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


# you gotta before careful, because you do not want to replace the thing that looks like a heading with a newline in this case,
# since it is actually a python comment, not a heading:
# ```python
# # This is how to initialize a variable
# a = 1
# ```
# for that reason, i ignore h1 tags and just get it when there is more than one pound sign
def add_whitespace_to_headings(markdown_text):
    # Define regex pattern to match markdown headings at the beginning of a line
    pattern = r"(^|\n)(#{2,6}\s*[^#\n]+)\n*"
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


def ensure_ends_with_newline(markdown_text):
    if not markdown_text.endswith("\n"):
        markdown_text += "\n"
    return markdown_text


def markdown_to_ventilated_prose(input_file, output_file):
    # Read the Markdown file
    with open(input_file, "r", encoding="utf-8") as f:
        markdown_text = f.read()

    # at one point i was thinking it necessary to remove leading whitespace before images,
    # but i think it is reasonable to have it for visual consistency in the markdown
    # if the lines around it also have space.
    # markdown_text = remove_leading_whitespace_before_image_markup(markdown_text)

    markdown_text = add_whitespace_to_headings(markdown_text)

    ventilated_prose = ""

    # break the markddown text into chunks that are separated by two newlines
    chunks = re.split(r"\n\n", markdown_text)

    potentially_updated_chunks = []
    for index, chunk in enumerate(chunks):
        # if the chunk contains any special markdown characters, then do not tokenize it
        #   * header
        #   * starting with four spaces, which is a code block
        #   * starting with exclamation mark, which is an image
        #   * starting with pipe, which is a table
        #   * starting with a number or letter and a period, which is a list
        if re.search(
            r"^(\s*[*#\d!-]|    |[\t ]+\!|\| |\w{1,2}\.)", chunk, flags=re.MULTILINE
        ):
            potentially_updated_chunks.append(chunk)
            continue

        # tried combining this with the previous regex but i'm apparently a noob
        #   anything starting with a backtick is code
        if re.search(r"^[\t ]*\`", chunk, flags=re.MULTILINE):
            potentially_updated_chunks.append(chunk)
            continue

        # Tokenize Markdown text chunk into sentences
        sentences = tokenize_into_sentences(chunk)

        # remove any newlines from the sentences, preserving those at the beginning or end
        sentences = [
            re.sub(r"(?<!^)\n(?!\s*$|\n)", " ", sentence) for sentence in sentences
        ]

        # Join sentences with newline character
        potentially_updated_chunks.append("\n".join(sentences))

    # Write the ventilated prose to the output file
    new_markdown_text = "\n\n".join(potentially_updated_chunks)
    new_markdown_text = ensure_ends_with_newline(new_markdown_text)

    # one newline at the end is good. two or more is excessive.
    new_markdown_text = new_markdown_text.rstrip() + "\n"

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(new_markdown_text)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py input.md output.md")
    else:
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        markdown_to_ventilated_prose(input_file, output_file)
        message = "Ventilation success: "
        if input_file == output_file:
            message += f"{output_file} updated"
        else:
            message += f"Output written to {output_file}"
        print(message)
