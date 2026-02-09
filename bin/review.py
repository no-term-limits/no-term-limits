#!/usr/bin/env python3
"""
Ergonomic code review script for reviewing branch changes and uncommitted files.
"""

import os
import sys
import subprocess
import json
from pathlib import Path
import shutil
from dataclasses import dataclass
from typing import List, Set, Dict
import select
import hashlib
import termios
import tty


@dataclass
class FileToReview:
    path: str
    status: str  # 'modified', 'added', 'branch_modified', 'branch_added'
    is_new: bool = False


class CodeReviewer:
    def __init__(self):
        self.terminal_height, self.terminal_width = self.get_terminal_size()
        self.current_index = 0
        self.files_to_review: List[FileToReview] = []
        self.ignored_files: Set[str] = set()
        self.reviewed_files: Dict[str, str] = {}  # {file_path: sha1sum}

        # Timer control
        self.timer_disabled = False

        # Find git root and set up cache directory
        self.git_root = self.get_git_root()
        self.cache_dir = self.git_root / ".git" / "code_review_cache"
        self.cache_dir.mkdir(exist_ok=True)

        self.branch_name = self.get_current_branch()
        self.ignore_file = (
            self.cache_dir / f"ignored_{self.branch_name.replace('/', '_')}.json"
        )
        self.reviewed_file_cache = (
            self.cache_dir / f"reviewed_{self.branch_name.replace('/', '_')}.json"
        )
        self.load_ignored_files()
        self.load_reviewed_files()

    def handle_t_press(self):
        """Handle 't' key press to potentially disable/enable timer."""
        self.timer_disabled = not self.timer_disabled
        return True

    def get_terminal_size(self):
        """Get current terminal dimensions."""
        try:
            result = subprocess.run(["stty", "size"], capture_output=True, text=True)
            if result.returncode == 0:
                lines, cols = map(int, result.stdout.split())
                return lines, cols
        except:
            pass
        # Fallback
        return shutil.get_terminal_size((80, 24))

    def get_git_root(self):
        """Find the root of the git repository."""
        try:
            result = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True,
                text=True,
                check=True,
            )
            return Path(result.stdout.strip())
        except subprocess.CalledProcessError:
            # If not in a git repo, use current directory
            return Path.cwd()

    def get_current_branch(self):
        """Get current git branch name."""
        try:
            result = subprocess.run(
                ["git", "branch", "--show-current"],
                capture_output=True,
                text=True,
                check=True,
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError:
            return "unknown"

    def resolve_file_path(self, file_path: str) -> str:
        """Resolve file path relative to git root or current directory."""
        # First try relative to current directory
        if os.path.exists(file_path):
            return file_path

        # Try relative to git root
        git_root_path = self.git_root / file_path
        if git_root_path.exists():
            return str(git_root_path)

        # Return original path if nothing found
        return file_path

    def load_ignored_files(self):
        """Load per-branch ignored files from cache."""
        if self.ignore_file.exists():
            try:
                with open(self.ignore_file, "r") as f:
                    self.ignored_files = set(json.load(f))
            except (json.JSONDecodeError, IOError):
                self.ignored_files = set()

    def save_ignored_files(self):
        """Save per-branch ignored files to cache."""
        with open(self.ignore_file, "w") as f:
            json.dump(list(self.ignored_files), f)

    def load_reviewed_files(self):
        """Load per-branch reviewed files cache with sha1sums."""
        if self.reviewed_file_cache.exists():
            try:
                with open(self.reviewed_file_cache, "r") as f:
                    self.reviewed_files = json.load(f)
            except (json.JSONDecodeError, IOError):
                self.reviewed_files = {}

    def save_reviewed_files(self):
        """Save per-branch reviewed files cache with sha1sums."""
        with open(self.reviewed_file_cache, "w") as f:
            json.dump(self.reviewed_files, f, indent=2)

    def calculate_file_sha1(self, file_path: str) -> str:
        """Calculate SHA1 hash of a file."""
        try:
            full_path = self.resolve_file_path(file_path)
            if not os.path.exists(full_path):
                return ""

            sha1 = hashlib.sha1()
            with open(full_path, "rb") as f:
                while chunk := f.read(8192):
                    sha1.update(chunk)
            return sha1.hexdigest()
        except (IOError, OSError):
            return ""

    def get_default_branch(self):
        """Get the default branch name dynamically."""
        try:
            result = subprocess.run(
                ["git", "symbolic-ref", "refs/remotes/origin/HEAD"],
                capture_output=True,
                text=True,
                check=True,
            )
            return result.stdout.strip().split("/")[-1]
        except subprocess.CalledProcessError:
            # Fallback to common default branch names
            for branch in ["main", "master"]:
                try:
                    subprocess.run(
                        ["git", "rev-parse", "--verify", f"origin/{branch}"],
                        capture_output=True,
                        check=True,
                    )
                    return branch
                except subprocess.CalledProcessError:
                    continue
            return "main"  # Final fallback

    def get_files_to_review(self):
        """Get all files that need review (branch changes + uncommitted)."""
        files = []

        # Get uncommitted changes (working directory changes)
        try:
            result = subprocess.run(
                ["git", "status", "--porcelain"],
                capture_output=True,
                text=True,
                check=True,
            )
            for line in result.stdout.strip().split("\n"):
                if not line:
                    continue
                status_code = line[:2]
                file_path = line[3:]

                if status_code.strip():  # Has changes
                    is_new = status_code[1] == "?" or status_code[0] == "A"
                    files.append(
                        FileToReview(
                            path=file_path,
                            status="added" if is_new else "modified",
                            is_new=is_new,
                        )
                    )
        except subprocess.CalledProcessError:
            pass

        # Get branch changes vs default branch (similar to gbf but without --relative)
        default_branch = self.get_default_branch()
        try:
            result = subprocess.run(
                [
                    "git",
                    "diff",
                    "--name-status",
                    "--diff-filter=d",
                    f"origin/{default_branch}",
                ],
                capture_output=True,
                text=True,
                check=True,
                cwd=self.git_root,
            )
            for line in result.stdout.strip().split("\n"):
                if not line:
                    continue
                parts = line.split("\t")
                if len(parts) >= 2:
                    status = parts[0]
                    file_path = parts[1]

                    # Don't duplicate files already in working changes
                    if not any(f.path == file_path for f in files):
                        is_new = status == "A"
                        files.append(
                            FileToReview(
                                path=file_path,
                                status="branch_added" if is_new else "branch_modified",
                                is_new=is_new,
                            )
                        )
        except subprocess.CalledProcessError:
            pass

        # Filter out ignored files
        files = [f for f in files if f.path not in self.ignored_files]

        # Filter out files that are in the reviewed cache with matching sha1sums
        files_to_review = []
        for file_info in files:
            file_sha1 = self.calculate_file_sha1(file_info.path)
            cached_sha1 = self.reviewed_files.get(file_info.path)

            # Include file if:
            # - Not in cache, OR
            # - SHA1 has changed (file was modified since last review)
            if cached_sha1 is None or cached_sha1 != file_sha1:
                files_to_review.append(file_info)

        self.files_to_review = files_to_review

        if not self.files_to_review:
            print("No files to review!")
            return False

        return True

    def display_file_content(
        self, file_info: FileToReview, start_line: int = 0, timer_duration: int = 5
    ):
        """Display file content with appropriate method. Returns True if content was shown."""
        clear_screen()

        # Header info
        status_map = {
            "modified": "📝 Modified (uncommitted)",
            "added": "🆕 New file (uncommitted)",
            "branch_modified": "📝 Modified (vs main)",
            "branch_added": "🆕 New file (vs main)",
        }

        # Reserve lines for header (5) and footer (4)
        display_lines = self.terminal_height - 9

        # Simple chunk calculation
        total_lines = self.get_file_line_count(file_info)
        total_chunks = max(1, (total_lines + display_lines - 1) // display_lines)
        current_chunk = (start_line // display_lines) + 1
        chunk_info = f" [Chunk {current_chunk} of {total_chunks}]"

        print(
            f"\n📁 File {self.current_index + 1}/{len(self.files_to_review)}: {file_info.path}{chunk_info}"
        )
        print(f"📊 Status: {status_map.get(file_info.status, file_info.status)}")
        print("─" * min(self.terminal_width, 80))
        print()

        # Show content and check if anything was displayed
        has_content = False
        if file_info.is_new or file_info.status.startswith("branch_added"):
            # Show full file content for new files
            has_content = self.show_file_content(
                file_info.path, start_line, display_lines
            )
        else:
            # Show git diff for modified files
            has_content = self.show_git_diff(file_info, start_line, display_lines)

        # Footer with controls
        print("\n" + "─" * min(self.terminal_width, 80))
        controls = "h)prev  l)next  i)gnore  j/k)scroll  space)pause  1-9)timer  t)toggle-timer  q)uit"
        if file_info.is_new:
            controls += "  e)dit"

        if self.timer_disabled:
            controls += "  [Timer: OFF]"
        else:
            controls += f"  [Timer: {timer_duration}s]"

        print(f"Controls: {controls}")
        print("", end="", flush=True)

        return has_content

    def show_file_content(self, file_path: str, start_line: int, max_lines: int):
        """Show file content using bat if available, otherwise cat. Returns True if content was shown."""
        try:
            # Resolve file path relative to git root if needed
            full_path = self.resolve_file_path(file_path)
            if not os.path.exists(full_path):
                print(f"File not found: {file_path} (tried: {full_path})")
                return False

            # Read file to check for content in the range
            with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()

            # Check if there's actual content in this range
            end_line = min(start_line + max_lines, len(lines))
            display_lines = lines[start_line:end_line]
            has_content = any(line.strip() for line in display_lines)

            if not has_content:
                return False

            # Try to use bat or batcat for syntax highlighting
            bat_cmd = None
            if shutil.which("bat"):
                bat_cmd = "bat"
            elif shutil.which("batcat"):
                bat_cmd = "batcat"

            if bat_cmd:
                cmd = [
                    bat_cmd,
                    "--color=always",
                    "--style=numbers",
                    f"--line-range={start_line + 1}:{start_line + max_lines}",
                    full_path,
                ]
                result = subprocess.run(cmd, capture_output=True, text=True)
                if result.returncode == 0:
                    print(result.stdout)
                    return True

            # Fallback to reading file directly
            for i, line in enumerate(display_lines, start=start_line + 1):
                print(f"{i:4d}│ {line.rstrip()}")

            return True

        except (subprocess.CalledProcessError, FileNotFoundError, IOError) as e:
            print(f"Error reading file: {file_path} - {e}")
            return False

    def show_git_diff(self, file_info: FileToReview, start_line: int, max_lines: int):
        """Show git diff for the file. Returns True if content was shown."""
        try:
            # Use the original path for git commands (git expects repo-relative paths)
            if file_info.status.startswith("branch_"):
                # Compare with default branch
                default_branch = self.get_default_branch()
                cmd = [
                    "git",
                    "diff",
                    "--color=always",
                    f"origin/{default_branch}",
                    "--",
                    file_info.path,
                ]
            else:
                # Show working directory changes
                cmd = ["git", "diff", "--color=always", "--", file_info.path]

            # Run git command from the git root directory
            result = subprocess.run(
                cmd, capture_output=True, text=True, cwd=self.git_root
            )

            if result.returncode != 0:
                print(f"Git diff error for {file_info.path}: {result.stderr}")
                return False

            if not result.stdout.strip():
                print(
                    f"No diff output for {file_info.path} (file may be staged or unchanged)"
                )
                return False

            lines = result.stdout.split("\n")

            # Show subset of lines based on scrolling
            display_lines = lines[start_line : start_line + max_lines]
            has_content = any(line.strip() for line in display_lines)

            if has_content:
                for line in display_lines:
                    print(line)

            return has_content

        except subprocess.CalledProcessError as e:
            print(f"Error showing diff for: {file_info.path} - {e}")
            return False

    def get_file_line_count(self, file_info: FileToReview) -> int:
        """Get total line count for scrolling."""
        try:
            if file_info.is_new or file_info.status.startswith("branch_added"):
                # For new files, count actual file lines
                full_path = self.resolve_file_path(file_info.path)
                with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                    return len(f.readlines())
            else:
                # For modified files, count diff lines
                if file_info.status.startswith("branch_"):
                    default_branch = self.get_default_branch()
                    cmd = [
                        "git",
                        "diff",
                        f"origin/{default_branch}",
                        "--",
                        file_info.path,
                    ]
                else:
                    cmd = ["git", "diff", "--", file_info.path]

                result = subprocess.run(
                    cmd, capture_output=True, text=True, cwd=self.git_root
                )
                return len(result.stdout.split("\n"))
        except Exception as e:
            print(f"Error counting lines for {file_info.path}: {e}")
            return 0

    def run_review(self):
        """Main review loop."""
        if not self.get_files_to_review():
            return

        print(f"🔍 Starting code review for branch '{self.branch_name}'")
        print(f"Found {len(self.files_to_review)} files to review")
        print("Starting review...")

        scroll_position = 0
        timer_duration = 5  # Default 5 seconds

        while self.current_index < len(self.files_to_review):
            current_file = self.files_to_review[self.current_index]

            # Display content and check if anything was shown
            has_content = self.display_file_content(
                current_file, scroll_position, timer_duration
            )

            # If no content, skip to next chunk or file
            if not has_content:
                max_lines = self.get_file_line_count(current_file)
                display_lines = self.terminal_height - 9
                if (
                    max_lines > display_lines
                    and scroll_position + display_lines < max_lines
                ):
                    scroll_position += display_lines
                    continue  # Try next chunk
                else:
                    # Go to next file
                    # Mark current file as reviewed before moving to next
                    file_sha1 = self.calculate_file_sha1(current_file.path)
                    if file_sha1:
                        self.reviewed_files[current_file.path] = file_sha1
                        self.save_reviewed_files()
                    self.current_index += 1
                    scroll_position = 0
                    continue

            try:
                if self.timer_disabled:
                    choice = get_single_char().lower()
                else:
                    choice = get_single_char_with_timeout(timer_duration).lower()

                if choice == "t":  # Toggle timer (handle hammering)
                    if self.handle_t_press():
                        continue  # Timer was toggled, redisplay
                elif choice == "l":  # Next
                    # Mark current file as reviewed before moving to next
                    file_sha1 = self.calculate_file_sha1(current_file.path)
                    if file_sha1:
                        self.reviewed_files[current_file.path] = file_sha1
                        self.save_reviewed_files()
                    self.current_index += 1
                    scroll_position = 0
                elif choice == "h":  # Back
                    if self.current_index > 0:
                        self.current_index -= 1
                        scroll_position = 0
                elif choice == "i":  # Ignore
                    self.ignored_files.add(current_file.path)
                    self.save_ignored_files()
                    self.current_index += 1
                    scroll_position = 0
                elif choice == "j":  # Scroll down
                    max_lines = self.get_file_line_count(current_file)
                    display_lines = (
                        self.terminal_height - 9
                    )  # Leave room for header/footer

                    if (
                        max_lines > display_lines
                        and scroll_position + display_lines < max_lines
                    ):
                        scroll_position += display_lines
                        continue  # Loop back to re-display
                    # If already at bottom, do nothing (no message, no input required)

                elif choice == "k":  # Scroll up
                    display_lines = (
                        self.terminal_height - 9
                    )  # Leave room for header/footer

                    if scroll_position > 0:
                        scroll_position = max(0, scroll_position - display_lines)
                        continue  # Loop back to re-display
                    # If already at top, do nothing (no message, no input required)
                elif choice == "e" and current_file.is_new:  # Edit
                    editor = os.environ.get("EDITOR", "nano")
                    subprocess.run([editor, current_file.path])
                elif choice == "q":  # Quit
                    break
                elif choice == "auto":  # Auto-advance timeout
                    # Only auto-advance if timer is not disabled
                    if not self.timer_disabled:
                        # Try to scroll down first, if not possible then go to next file
                        max_lines = self.get_file_line_count(current_file)
                        display_lines = (
                            self.terminal_height - 9
                        )  # Leave room for header/footer

                        if (
                            max_lines > display_lines
                            and scroll_position + display_lines < max_lines
                        ):
                            # Can scroll down - do that
                            scroll_position += display_lines
                            continue  # Re-display with new scroll position
                        else:
                            # Can't scroll more, go to next file
                            # Mark current file as reviewed before moving to next
                            file_sha1 = self.calculate_file_sha1(current_file.path)
                            if file_sha1:
                                self.reviewed_files[current_file.path] = file_sha1
                                self.save_reviewed_files()
                            self.current_index += 1
                            scroll_position = 0
                elif (
                    choice == " "
                ):  # Spacebar (handled by countdown function, but might reach here)
                    continue  # Just re-display, don't treat as invalid
                elif choice.isdigit() and "1" <= choice <= "9":  # Set timer duration
                    timer_duration = int(choice)
                    continue  # Re-display with updated timer
                # Other invalid commands are simply ignored

            except KeyboardInterrupt:
                print("\n\n👋 Review session interrupted")
                break

        print(
            f"\n✅ Review complete! Reviewed {min(self.current_index + 1, len(self.files_to_review))} files"
        )


def clear_screen():
    """Clear the terminal screen."""
    os.system("clear" if os.name == "posix" else "cls")


def get_single_char_with_timeout(timeout_seconds=5):
    """Get a single character input with countdown timer. Returns 'AUTO' if timeout."""
    # Check if we're in an interactive terminal
    if not sys.stdin.isatty():
        # Non-interactive mode - use line input
        try:
            response = input("Enter command: ").strip()
            return response[:1] if response else "q"
        except (EOFError, KeyboardInterrupt):
            return "q"

    try:
        import termios
        import tty

        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)

        try:
            tty.setcbreak(fd)

            paused = False
            remaining = timeout_seconds

            while remaining > 0:
                if not paused:
                    print(f"\r{remaining}s", end="", flush=True)
                else:
                    print(f"\r⏸️ {remaining}s (paused)", end="", flush=True)

                # Check if input is available
                if select.select([sys.stdin], [], [], 1.0)[0]:
                    char = sys.stdin.read(1)
                    print(
                        f"\r                    \r", end="", flush=True
                    )  # Clear countdown

                    if char == " ":  # Spacebar toggles pause
                        paused = not paused
                        continue  # Don't return, just toggle pause state
                    else:
                        return char  # Return the pressed key

                # Only decrement if not paused
                if not paused:
                    remaining -= 1

            # Timeout reached
            print(f"\r                    \r", end="", flush=True)  # Clear countdown
            return "AUTO"

        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

    except (ImportError, OSError, AttributeError):
        # Fallback for systems without termios/tty
        try:
            response = input("Enter command: ").strip()
            return response[:1] if response else ""
        except (EOFError, KeyboardInterrupt):
            return "q"


def get_single_char():
    """Get a single character input without pressing enter."""
    # Check if we're in an interactive terminal
    if not sys.stdin.isatty():
        # Non-interactive mode - use line input
        try:
            response = input("Enter command: ").strip()
            return response[:1] if response else "q"
        except (EOFError, KeyboardInterrupt):
            return "q"

    try:
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setcbreak(fd)
            char = sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        return char
    except (ImportError, OSError, AttributeError):
        # Fallback for systems without termios/tty
        try:
            response = input("Enter command: ").strip()
            return response[:1] if response else ""
        except (EOFError, KeyboardInterrupt):
            return "q"


if __name__ == "__main__":
    try:
        reviewer = CodeReviewer()
        reviewer.run_review()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
