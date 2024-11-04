#!/usr/bin/env python

import sys
import re
import nltk.data


def tokenize_into_sentences(text):
    tokenizer = None
    try:
        tokenizer = nltk.data.load("tokenizers/punkt/english.pickle")
    except LookupError:
        nltk.download("punkt")
        tokenizer = nltk.data.load("tokenizers/punkt/english.pickle")
    return tokenizer.tokenize(text)


# find any sentence that is all exclamation marks
# and add its contents to the previous sentence
def merge_exclamation_sentences(sentences):
    i = 0
    while i < len(sentences):
        if all(char == "!" for char in sentences[i]):
            if len(sentences) >= i + 1 and sentences[i + 1].startswith("["):
                sentences[i] += "" + sentences.pop(i + 1)
            else:
                sentences[i - 1] += "" + sentences.pop(i)
        else:
            i += 1
    return sentences


# you gotta before careful, because you do not want to replace the thing that looks like a heading with a newline in this case,
# since it is actually a python comment, not a heading:
# ```python
# # This is how to initialize a variable
# a = 1
# ```
# for that reason, i ignore h1 tags and just get it when there is more than one pound sign
#
# we also have to be careful to not screw up headers that have pounds signs by breaking up:
#   #### Rule #4: Do Use Data Objects to limit access to information
# into:
#   #### Rule
#
#   #4: Do Use Data Objects to limit access to information
#
def add_whitespace_to_headings(markdown_text):
    # Define regex pattern to match markdown headings at the beginning of a line
    pattern = r"(^|\n)(#{2,6}\s*[^\n]+)\n*"
    # Replace markdown headings with added whitespace
    replaced_text = re.sub(pattern, r"\1\2\n\n", markdown_text)
    return replaced_text


# and image looks like this: ![Alt text](/path/to/img.jpg)
# you don't want to remove newlines, so it just removes tabs and spaces explicitly
# rather than \s
def remove_leading_whitespace_before_image_markup(markdown_text):
    pattern = re.compile(r"^[\t ]+!(?=\[)", re.MULTILINE)
    replaced_text = re.sub(pattern, "!", markdown_text)
    return replaced_text


def remove_trailing_whitespace(markdown_text):
    """
    Remove trailing whitespace from each line in the markdown text.
    """
    return "\n".join(line.rstrip() for line in markdown_text.splitlines())


def ensure_ends_with_newline(markdown_text):
    if not markdown_text.endswith("\n"):
        markdown_text += "\n"
    return markdown_text


def process_bullet_points(chunk):
    """
    Process bullet points with multiple sentences in a markdown chunk.
    """
    lines = chunk.splitlines()
    updated_lines = []
    skip_until_closing_backticks = False
    for line in lines:
        # Toggle the flag if the line contains triple backticks
        if re.match(r"^```", line):
            skip_until_closing_backticks = not skip_until_closing_backticks
            updated_lines.append(line)
            continue

        # Skip processing if inside a code block
        if skip_until_closing_backticks:
            updated_lines.append(line)
            continue

        # if line begins with # (it's a header), skip it
        if line.startswith("#"):
            updated_lines.append(line)
            continue
        match = re.match(r"^(\s*([-*]|\d+\.)?\s+)(.*)", line)
        if match:
            bullet, content = match.groups()[0], match.groups()[2]
            # Check if the content contains markdown elements that should not be split
            if re.search(r"!\[.*\]|\*\*.*\*\*", content):
                updated_lines.append(line)
                continue
            # Tokenize the content into sentences
            sentences = tokenize_into_sentences(content)
            # Only process if there are multiple sentences
            if len(sentences) > 1:
                # Merge exclamation sentences
                sentences = merge_exclamation_sentences(sentences)
                # Join sentences with newline and indentation
                updated_lines.append(bullet + sentences[0])
                for sentence in sentences[1:]:
                    updated_lines.append(" " * len(bullet) + sentence)
            else:
                updated_lines.append(line)
        else:
            updated_lines.append(line)
    return "\n".join(updated_lines)


def process_markdown_string(markdown_text):
    """
    Process a markdown string and return the ventilated prose.
    """

    # break the markdown text into chunks that are separated by two newlines
    chunks = re.split(r"\n\n", markdown_text)

    potentially_updated_chunks = []
    for index, chunk in enumerate(chunks):
        # if the chunk contains any special markdown characters, then do not tokenize it
        #   * header
        #   * starting with "[![" it is a markdown link with alt text
        #   * starting with "{{" since this is likely jinja
        #   * starting with four spaces, which is a code block
        #   * starting with exclamation mark, which is an image
        #   * starting with pipe, which is a table
        #   * starting with a number or letter and a period, which is a list
        if re.search(
            r"^(\s*[*#\d!-]|\[\!\[|{{|    |[\t ]+\!|\| |\w{1,2}\.)",
            chunk,
            flags=re.MULTILINE,
        ):
            # Handle bullet points with multiple sentences
            potentially_updated_chunks.append(process_bullet_points(chunk))
            continue

        # tried combining this with the previous regex but i'm apparently a noob
        #   anything starting with a backtick is code
        if re.search(r"^[\t ]*\`", chunk, flags=re.MULTILINE):
            potentially_updated_chunks.append(chunk)
            continue

        # Tokenize Markdown text chunk into sentences
        sentences = tokenize_into_sentences(chunk)

        sentences = merge_exclamation_sentences(sentences)

        # remove any newlines from the sentences, preserving those at the beginning or end
        sentences = [
            re.sub(r"(?<!^)\n(?!\s*$|\n)", " ", sentence) for sentence in sentences
        ]

        # Join sentences with newline character
        potentially_updated_chunks.append("\n".join(sentences))

    # Join the potentially updated chunks into the new markdown text
    new_markdown_text = "\n\n".join(potentially_updated_chunks)
    new_markdown_text = remove_trailing_whitespace(new_markdown_text)
    new_markdown_text = ensure_ends_with_newline(new_markdown_text)

    # one newline at the end is good. two or more is excessive.
    new_markdown_text = new_markdown_text.rstrip() + "\n"

    return new_markdown_text


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py input.md output.md")
    else:
        input_file = sys.argv[1]
        output_file = sys.argv[2]

        with open(input_file, "r", encoding="utf-8") as f:
            markdown_text = f.read()

        new_markdown_text = process_markdown_string(markdown_text)

        if new_markdown_text == markdown_text:
            print(f"{input_file}: Ventilation success. No updates needed.")
        else:
            # Write the ventilated prose to the output file
            with open(output_file, "w", encoding="utf-8") as f:
                f.write(new_markdown_text)

            message = "Ventilation success: "
            if input_file == output_file:
                message += f"{output_file} updated"
            else:
                message += f"Output written to {output_file}"
            print(message)
