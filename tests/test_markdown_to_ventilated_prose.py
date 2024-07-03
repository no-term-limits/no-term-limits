import re
import pytest
import nltk
import sys
import os

# Add the `bin` directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '../bin'))

from markdown_to_ventilated_prose import (
    tokenize_into_sentences,
    merge_exclamation_sentences,
    add_whitespace_to_headings,
    remove_leading_whitespace_before_image_markup,
    ensure_ends_with_newline
)

# Ensure nltk tokenizer is available
@pytest.fixture(scope="module", autouse=True)
def setup_nltk():
    try:
        nltk.data.load("tokenizers/punkt/english.pickle")
    except LookupError:
        nltk.download("punkt")

def test_tokenize_into_sentences():
    text = "Hello there! How are you doing? I'm good."
    expected = ["Hello there!", "How are you doing?", "I'm good."]
    assert tokenize_into_sentences(text) == expected

def test_merge_exclamation_sentences():
    sentences = ["Hello there!", "!!!", "How are you doing?", "!!!", "I'm good."]
    expected = ["Hello there! !!!", "How are you doing? !!!", "I'm good."]
    assert merge_exclamation_sentences(sentences) == expected

def test_add_whitespace_to_headings():
    markdown_text = """
# This is a heading 1 (should be ignored)
## This is heading 2
Some text here.
### This is heading 3
More text here.
#### Rule #4: Do Use Data Objects to limit access to information
# This is how to initialize a variable
# a = 1
"""
    expected = """
# This is a heading 1 (should be ignored)
## This is heading 2

Some text here.
### This is heading 3

More text here.
#### Rule #4: Do Use Data Objects to limit access to information

# This is how to initialize a variable
# a = 1
"""
    assert add_whitespace_to_headings(markdown_text) == expected

def test_remove_leading_whitespace_before_image_markup():
    markdown_text = """
    ![Alt text](/path/to/img.jpg)
"""
    expected = """
![Alt text](/path/to/img.jpg)
"""
    assert remove_leading_whitespace_before_image_markup(markdown_text) == expected

def test_ensure_ends_with_newline():
    markdown_text = "Some text without a newline"
    expected = "Some text without a newline\n"
    assert ensure_ends_with_newline(markdown_text) == expected

if __name__ == "__main__":
    pytest.main()

