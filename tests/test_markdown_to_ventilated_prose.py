import sys
import os
import re
import pytest
import nltk

# Add the `bin` directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), "../bin"))

from markdown_to_ventilated_prose import (
    tokenize_into_sentences,
    merge_exclamation_sentences,
    add_whitespace_to_headings,
    remove_leading_whitespace_before_image_markup,
    ensure_ends_with_newline,
    process_markdown_string,
    remove_trailing_whitespace,
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
    expected = ["Hello there!!!!", "How are you doing?!!!", "I'm good."]
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

    markdown_text_with_whitespace = """
# This is a heading 1 (should be ignored)
## This is heading 2

Some text here.
### This is heading 3

More text here.
#### Rule #4: Do Use Data Objects to limit access to information

```python
# This is how to initialize a variable
a = 1
```
"""
    expected_with_whitespace = """
# This is a heading 1 (should be ignored)
## This is heading 2

Some text here.
### This is heading 3

More text here.
#### Rule #4: Do Use Data Objects to limit access to information

```python
# This is how to initialize a variable
a = 1
```
"""
    assert (
        add_whitespace_to_headings(markdown_text_with_whitespace)
        == expected_with_whitespace
    )


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


def test_remove_trailing_whitespace():
    markdown_text = "This is a line with trailing spaces.   \nThis is another line with trailing spaces.   "
    expected = "This is a line with trailing spaces.\nThis is another line with trailing spaces."
    assert remove_trailing_whitespace(markdown_text) == expected


def test_process_markdown_string_with_trailing_spaces():
    markdown_text = "This is a line with trailing spaces.   \nThis is another line with trailing spaces.   "
    expected = "This is a line with trailing spaces.\nThis is another line with trailing spaces.\n"
    assert process_markdown_string(markdown_text) == expected


# the two sentences get into the same chunk, which we ignore because of the the jinja, so it doesn't end up ventilating like we would want.
# def test_process_markdown_string_with_sentences_and_jinja():
#     markdown_text = "This is the first sentence. This is the second sentence.\n{{ jinja_variable }}"
#     expected = "This is the first sentence.\nThis is the second sentence.\n{{ jinja_variable }}\n"
#     assert process_markdown_string(markdown_text) == expected


def test_process_markdown_string_with_period_and_spaces():
    markdown_text = "This is the first sentence.   This is the second sentence."
    expected = "This is the first sentence.\nThis is the second sentence.\n"
    assert process_markdown_string(markdown_text) == expected
    # pytest.main()


def test_process_markdown_string_when_bullet_points_are_long_enough_for_multiple_sentences():
    markdown_text = """
Hot list:
  - Awesome thing. It is mega awesome. So awesome, actually.
  - Next list item. Also a great item."""
    expected = """
Hot list:
  - Awesome thing.
    It is mega awesome.
    So awesome, actually.
  - Next list item.
    Also a great item.
"""
    actual = process_markdown_string(markdown_text)
    assert actual == expected


def test_process_markdown_string_when_sentences_are_indented():
    markdown_text = """
1. **Cool Stuff**
   Awesome thing. It is mega awesome. So awesome, actually."""
    expected = """
1. **Cool Stuff**
   Awesome thing.
   It is mega awesome.
   So awesome, actually.
"""
    actual = process_markdown_string(markdown_text)
    print(f"➡️ ➡️ ➡️  actual: {actual}")
    print(f"➡️ ➡️ ➡️  expected: {expected}")
    assert actual == expected


def test_images_with_exclamation_points():
    markdown_text = """
    ![Awesome label](images/great_image_2.png)
    """
    expected = """
    ![Awesome label](images/great_image_2.png)
"""
    actual = process_markdown_string(markdown_text)
    assert actual == expected


def test_weird_header_that_should_remain_intact():
    markdown_text = """
### **1. Running SpiffWorkflow in PyCharm**
    """
    expected = """
### **1. Running SpiffWorkflow in PyCharm**
"""
    actual = process_markdown_string(markdown_text)
    assert actual == expected
