#!/usr/bin/env python3
"""
Ergonomic code review script for reviewing branch changes and uncommitted files.
"""

import hashlib
import json
import os
import select
import shutil
import subprocess
import sys
import termios
import tty
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Callable, Dict, List, Set, Tuple

DEFAULT_TIMER_SECONDS = 5


class FileStatus(str, Enum):
    MODIFIED = "modified"
    ADDED = "added"
    BRANCH_MODIFIED = "branch_modified"
    BRANCH_ADDED = "branch_added"


STATUS_LABELS = {
    FileStatus.MODIFIED: "📝 Modified (uncommitted)",
    FileStatus.ADDED: "🆕 New file (uncommitted)",
    FileStatus.BRANCH_MODIFIED: "📝 Modified (vs main)",
    FileStatus.BRANCH_ADDED: "🆕 New file (vs main)",
}


@dataclass
class FileToReview:
    path: str
    status: FileStatus
    is_new: bool = False


class CodeReviewer:
    def __init__(self):
        self.terminal_height, self.terminal_width = self.get_terminal_size()
        self.current_index = 0
        self.files_to_review: List[FileToReview] = []
        self.ignored_files: Set[str] = set()
        self.reviewed_files: Dict[str, str] = {}
        self.timer_disabled = False

        self.git_root = self.get_git_root()
        self.branch_name = self.get_current_branch()
        self.default_branch = self.get_default_branch()

        self.cache_dir = self.git_root / ".git" / "code_review_cache"
        self.cache_dir.mkdir(exist_ok=True)
        branch_slug = self.branch_name.replace("/", "_")
        self.ignore_file = self.cache_dir / f"ignored_{branch_slug}.json"
        self.reviewed_file_cache = self.cache_dir / f"reviewed_{branch_slug}.json"

        self.ignored_files = set(self._load_json(self.ignore_file, []))
        self.reviewed_files = self._load_json(self.reviewed_file_cache, {})
        self.content_cache: Dict[Tuple[str, str], List[str]] = {}
        self.bat_cmd = shutil.which("bat") or shutil.which("batcat")
        self.choice_handlers: Dict[
            str, Callable[[FileToReview, int], Tuple[int, bool]]
        ] = {
            "t": self._handle_toggle_timer,
            "l": self._handle_next_file,
            "h": self._handle_prev_file,
            "i": self._handle_ignore_file,
            "e": self._handle_edit_file,
            "q": self._handle_quit,
            " ": self._handle_noop,
        }

    def _load_json(self, path: Path, default):
        if not path.exists():
            return default
        try:
            with open(path, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return default

    def save_ignored_files(self):
        with open(self.ignore_file, "w") as f:
            json.dump(list(self.ignored_files), f)

    def save_reviewed_files(self):
        with open(self.reviewed_file_cache, "w") as f:
            json.dump(self.reviewed_files, f, indent=2)

    def get_terminal_size(self):
        return shutil.get_terminal_size((80, 24))

    def _run_git(
        self, args: List[str], check: bool = False, cwd: Path = None
    ) -> subprocess.CompletedProcess:
        return self._run(["git", *args], check=check, cwd=cwd)

    def _run(
        self, cmd: List[str], check: bool = False, cwd: Path = None
    ) -> subprocess.CompletedProcess:
        return subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=check,
            cwd=cwd if cwd else self.git_root,
        )

    def get_git_root(self) -> Path:
        try:
            result = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True,
                text=True,
                check=True,
            )
            return Path(result.stdout.strip())
        except subprocess.CalledProcessError:
            return Path.cwd()

    def get_current_branch(self) -> str:
        try:
            result = self._run_git(["branch", "--show-current"], check=True)
            return result.stdout.strip()
        except subprocess.CalledProcessError:
            return "unknown"

    def get_default_branch(self) -> str:
        try:
            result = self._run_git(
                ["symbolic-ref", "refs/remotes/origin/HEAD"], check=True
            )
            return result.stdout.strip().split("/")[-1]
        except subprocess.CalledProcessError:
            for branch in ["main", "master"]:
                try:
                    self._run_git(
                        ["rev-parse", "--verify", f"origin/{branch}"], check=True
                    )
                    return branch
                except subprocess.CalledProcessError:
                    continue
            return "main"

    def resolve_file_path(self, file_path: str) -> str:
        if os.path.exists(file_path):
            return file_path

        git_root_path = self.git_root / file_path
        if git_root_path.exists():
            return str(git_root_path)

        return file_path

    def calculate_file_sha256(self, file_path: str) -> str:
        try:
            full_path = self.resolve_file_path(file_path)
            if not os.path.exists(full_path):
                return ""

            sha256 = hashlib.sha256()
            with open(full_path, "rb") as f:
                while chunk := f.read(8192):
                    sha256.update(chunk)
            return sha256.hexdigest()
        except (IOError, OSError):
            return ""

    def parse_working_tree_files(self) -> List[FileToReview]:
        files: List[FileToReview] = []
        try:
            result = self._run_git(["status", "--porcelain"], check=True)
        except subprocess.CalledProcessError:
            return files

        for line in result.stdout.splitlines():
            if len(line) < 4:
                continue

            status_code = line[:2]
            file_path = line[3:]
            if not status_code.strip():
                continue

            is_new = status_code[1] == "?" or status_code[0] == "A"
            files.append(
                FileToReview(
                    path=file_path,
                    status=FileStatus.ADDED if is_new else FileStatus.MODIFIED,
                    is_new=is_new,
                )
            )
        return files

    def parse_branch_files(self, existing_paths: Set[str]) -> List[FileToReview]:
        files: List[FileToReview] = []
        try:
            result = self._run_git(
                [
                    "diff",
                    "--name-status",
                    "--diff-filter=d",
                    f"origin/{self.default_branch}",
                ],
                check=True,
            )
        except subprocess.CalledProcessError:
            return files

        for line in result.stdout.splitlines():
            if not line:
                continue

            parts = line.split("\t")
            if len(parts) < 2:
                continue

            status_code = parts[0]
            file_path = parts[
                -1
            ]  # Handles rename entries by selecting destination path

            if file_path in existing_paths:
                continue

            is_new = status_code == "A"
            files.append(
                FileToReview(
                    path=file_path,
                    status=FileStatus.BRANCH_ADDED
                    if is_new
                    else FileStatus.BRANCH_MODIFIED,
                    is_new=is_new,
                )
            )
        return files

    def should_review(self, file_info: FileToReview) -> bool:
        if file_info.path in self.ignored_files:
            return False

        file_sha256 = self.calculate_file_sha256(file_info.path)
        cached_sha256 = self.reviewed_files.get(file_info.path)
        return cached_sha256 is None or cached_sha256 != file_sha256

    def refresh_files_to_review(self) -> bool:
        files = self.parse_working_tree_files()
        seen_paths = {f.path for f in files}
        files.extend(self.parse_branch_files(seen_paths))

        self.files_to_review = [f for f in files if self.should_review(f)]
        if not self.files_to_review:
            print("No files to review!")
            return False
        return True

    def is_new_file(self, file_info: FileToReview) -> bool:
        return file_info.is_new or file_info.status == FileStatus.BRANCH_ADDED

    def cache_key(self, file_info: FileToReview) -> Tuple[str, str]:
        return (file_info.path, file_info.status.value)

    def invalidate_content_cache(self, file_info: FileToReview):
        self.content_cache.pop(self.cache_key(file_info), None)

    def get_file_lines(self, file_info: FileToReview) -> List[str]:
        key = self.cache_key(file_info)
        if key in self.content_cache:
            return self.content_cache[key]

        lines: List[str]
        if self.is_new_file(file_info):
            full_path = self.resolve_file_path(file_info.path)
            if not os.path.exists(full_path):
                lines = []
            else:
                with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                    lines = f.read().splitlines()
        else:
            lines = self.get_diff_lines(file_info)

        self.content_cache[key] = lines
        return lines

    def get_diff_lines(self, file_info: FileToReview) -> List[str]:
        cmd = ["diff", "--color=always"]
        if file_info.status in (FileStatus.BRANCH_MODIFIED, FileStatus.BRANCH_ADDED):
            cmd.append(f"origin/{self.default_branch}")
        cmd.extend(["--", file_info.path])

        result = self._run_git(cmd)
        if result.returncode != 0:
            print(f"Git diff error for {file_info.path}: {result.stderr}")
            return []

        if not result.stdout.strip():
            return []

        return result.stdout.splitlines()

    def mark_file_reviewed(self, file_info: FileToReview):
        file_sha256 = self.calculate_file_sha256(file_info.path)
        if file_sha256:
            self.reviewed_files[file_info.path] = file_sha256
            self.save_reviewed_files()

    def next_file(self, file_info: FileToReview, review_file: bool = True):
        if review_file:
            self.mark_file_reviewed(file_info)
        self.current_index += 1

    def print_header(self, file_info: FileToReview):
        print(
            f"\n📁 File {self.current_index + 1}/{len(self.files_to_review)}: {file_info.path}"
        )
        print(f"📊 Status: {STATUS_LABELS.get(file_info.status, file_info.status)}")
        print("─" * min(self.terminal_width, 80))
        print()

    def print_footer(self, file_info: FileToReview, timer_duration: int):
        print("\n" + "─" * min(self.terminal_width, 80))
        controls = (
            "h)prev  l)next  i)gnore  space)pause  1-9)timer  t)toggle-timer  q)uit"
        )
        if file_info.is_new:
            controls += "  e)dit"

        if self.timer_disabled:
            controls += "  [Timer: OFF]"
        else:
            controls += f"  [Timer: {timer_duration}s]"

        print(f"Controls: {controls}")
        print("", end="", flush=True)

    def show_new_file_content(self, file_info: FileToReview, lines: List[str]) -> bool:
        if not lines:
            print(f"File not found or empty: {file_info.path}")
            return False

        has_content = any(line.strip() for line in lines)
        if not has_content:
            return False

        if self.bat_cmd:
            full_path = self.resolve_file_path(file_info.path)
            result = subprocess.run(
                [
                    self.bat_cmd,
                    "--color=always",
                    "--style=numbers",
                    full_path,
                ],
                capture_output=True,
                text=True,
            )
            if result.returncode == 0:
                print(result.stdout, end="")
                return True

        for i, line in enumerate(lines, start=1):
            print(f"{i:4d}│ {line}")
        return True

    def show_diff_content(self, lines: List[str]) -> bool:
        if not any(line.strip() for line in lines):
            return False
        for line in lines:
            print(line)
        return True

    def display_file_content(
        self, file_info: FileToReview, timer_duration: int
    ) -> bool:
        clear_screen()

        lines = self.get_file_lines(file_info)

        self.print_header(file_info)

        if self.is_new_file(file_info):
            has_content = self.show_new_file_content(file_info, lines)
        else:
            has_content = self.show_diff_content(lines)
            if not has_content:
                print(
                    f"No diff output for {file_info.path} (file may be staged or unchanged)"
                )

        self.print_footer(file_info, timer_duration)
        return has_content

    def read_choice(self, timer_duration: int) -> str:
        if self.timer_disabled:
            return get_single_char().lower()
        return get_single_char_with_timeout(timer_duration).lower()

    def _handle_toggle_timer(
        self, _file_info: FileToReview, timer_duration: int
    ) -> Tuple[int, bool]:
        self.timer_disabled = not self.timer_disabled
        return timer_duration, False

    def _handle_next_file(
        self, file_info: FileToReview, timer_duration: int
    ) -> Tuple[int, bool]:
        self.next_file(file_info)
        return timer_duration, False

    def _handle_prev_file(
        self, _file_info: FileToReview, timer_duration: int
    ) -> Tuple[int, bool]:
        if self.current_index > 0:
            self.current_index -= 1
        return timer_duration, False

    def _handle_ignore_file(
        self, file_info: FileToReview, timer_duration: int
    ) -> Tuple[int, bool]:
        self.ignored_files.add(file_info.path)
        self.save_ignored_files()
        self.next_file(file_info, review_file=False)
        return timer_duration, False

    def _handle_edit_file(
        self, file_info: FileToReview, timer_duration: int
    ) -> Tuple[int, bool]:
        if file_info.is_new:
            editor = os.environ.get("EDITOR", "nano")
            subprocess.run([editor, file_info.path])
            self.invalidate_content_cache(file_info)
        return timer_duration, False

    def _handle_quit(
        self, _file_info: FileToReview, timer_duration: int
    ) -> Tuple[int, bool]:
        return timer_duration, True

    def _handle_noop(
        self, _file_info: FileToReview, timer_duration: int
    ) -> Tuple[int, bool]:
        return timer_duration, False

    def handle_choice(
        self,
        choice: str,
        file_info: FileToReview,
        timer_duration: int,
    ) -> Tuple[int, bool]:
        if choice.isdigit() and "1" <= choice <= "9":
            return int(choice), False

        handler = self.choice_handlers.get(choice)
        if handler:
            return handler(file_info, timer_duration)

        return timer_duration, False

    def run_review(self):
        if not self.refresh_files_to_review():
            return

        print(f"🔍 Starting code review for branch '{self.branch_name}'")
        print(f"Found {len(self.files_to_review)} files to review")
        print("Starting review...")

        timer_duration = DEFAULT_TIMER_SECONDS

        while self.current_index < len(self.files_to_review):
            current_file = self.files_to_review[self.current_index]

            has_content = self.display_file_content(current_file, timer_duration)
            if not has_content:
                self.next_file(current_file)
                continue

            try:
                choice = self.read_choice(timer_duration)
                if choice == "auto" and not self.timer_disabled:
                    self.next_file(current_file)
                    continue
                timer_duration, should_quit = self.handle_choice(
                    choice, current_file, timer_duration
                )
                if should_quit:
                    break
            except KeyboardInterrupt:
                print("\n\n👋 Review session interrupted")
                break

        reviewed_count = min(self.current_index + 1, len(self.files_to_review))
        print(f"\n✅ Review complete! Reviewed {reviewed_count} files")


def clear_screen():
    os.system("clear" if os.name == "posix" else "cls")


def _read_line_char(prompt: str = "Enter command: ", default: str = "q") -> str:
    try:
        response = input(prompt).strip()
        return response[:1] if response else default
    except (EOFError, KeyboardInterrupt):
        return "q"


def get_single_char_with_timeout(timeout_seconds: int = 5) -> str:
    if not sys.stdin.isatty():
        return _read_line_char()

    try:
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setcbreak(fd)
            paused = False
            remaining = timeout_seconds

            while remaining > 0:
                status = f"{remaining}s" if not paused else f"⏸️ {remaining}s (paused)"
                print(f"\r{status}", end="", flush=True)

                if select.select([sys.stdin], [], [], 1.0)[0]:
                    char = sys.stdin.read(1)
                    print("\r                    \r", end="", flush=True)
                    if char == " ":
                        paused = not paused
                        continue
                    return char

                if not paused:
                    remaining -= 1

            print("\r                    \r", end="", flush=True)
            return "AUTO"
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    except (OSError, AttributeError):
        return _read_line_char(default="")


def get_single_char() -> str:
    if not sys.stdin.isatty():
        return _read_line_char()

    try:
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setcbreak(fd)
            return sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    except (OSError, AttributeError):
        return _read_line_char(default="")


if __name__ == "__main__":
    reviewer = CodeReviewer()
    reviewer.run_review()
