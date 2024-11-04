#!/usr/bin/env python

# originally from https://mindfulmodeler.substack.com/p/proofreading-an-entire-book-with
# and then heavily modified
#
# pip install langchain-openai langchain openai

import sys
import os
import difflib
import requests

EDIT_DIR = "/tmp/edits"

# Determine which API key and endpoint to use
azure_api_key = os.environ.get("AZURE_API_KEY")
openai_api_key = os.environ.get("OPENAI_API_KEY")

if azure_api_key:
    api_key = azure_api_key
    endpoint = "https://eastus.api.cognitive.microsoft.com/openai/deployments/go-nuts/chat/completions?api-version=2024-06-01"
    headers = {
        "Content-Type": "application/json",
        "api-key": api_key,
    }
else:
    if openai_api_key is None:
        keyfile = "oai.key"
        with open(keyfile, "r") as f:
            openai_api_key = f.read().strip()
    api_key = openai_api_key
    endpoint = "https://api.openai.com/v1/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}",
    }


def read_file(file_path):
    with open(file_path, "r") as f:
        return f.read()


def split_content(content, chunk_size=13000):
    return [content[i : i + chunk_size] for i in range(0, len(content), chunk_size)]


def process_chunk(doc, retries=3):
    system_prompt = """You are proofreading a markdown document and you will receive text that is almost exactly correct, but may contain errors. You should:
- fix spelling
- not edit URLs
- never touch a markdown link; these might look like: [Image label](images/Manual_instructions_panel.png)
- improve grammar that is obviously wrong
- fix awkward language if it is really bad
- keep everything else exactly the same, including tone and voice
- not change the case of words unless they are obviously wrong
- avoid changing markdown syntax, e.g. keep [@reference]
- avoid putting multiple sentences on the same line
- make sure you do not remove any headers at the beginning of the text (markdown headers begin with one or more # characters).

Example of good edit:
<input>
# Awesome Headerr
This is a sentance that are about *something*.
</input>
<output>
# Awesome Header
This is a sentence that is about *something*.
</output>

Bad edit removing content:
<input>
# Excellent ideas
Pet Panda
Eeating Tofu
</input>
<output>
Pet Panda
Eeating Tofu
</output>

Bad edit unnecessarily adding lines with no content, which introduces a paragraph break where none existed before:
<input>
# Excellent ideas

Pet Panda
Eeating Tofu
</input>
<output>
# Excellent ideas

Pet Panda

Eeating Tofu
</output>

The markdown document follows. The output document's first line should probably match that of the input document, even if it is a markdown header.
"""

    payload = {
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": doc},
        ],
        "temperature": 0.2,
        "top_p": 0.95,
    }

    for attempt in range(retries):
        try:
            response = requests.post(endpoint, headers=headers, json=payload)
            response.raise_for_status()
            result = response.json()
            edited_result_content = result["choices"][0]["message"]["content"]
            if 0.95 * len(doc) <= len(edited_result_content) <= 1.05 * len(doc):
                return edited_result_content
            print(
                f"Retry {attempt + 1} for chunk due to size mismatch. Original length: {len(doc)}, Edited length: {len(edited_result_content)}"
            )

            temp_output_file = f"{EDIT_DIR}/size_mismatch_output.md"
            with open(temp_output_file, "w") as f:
                f.write(edited_result_content)
            temp_input_file = f"{EDIT_DIR}/size_mismatch_input.md"
            with open(temp_input_file, "w") as f:
                f.write(doc)
        except requests.RequestException as e:
            print(f"Request failed: {e}")
    raise ValueError("Failed to process chunk after retries.")


def get_edited_content(docs):
    edited_content = ""
    for i, doc in enumerate(docs):
        edited_result_content = process_chunk(doc)
        edited_content += edited_result_content + "\n"
    return edited_content


def analyze_diff(diff_file_path):
    diff_content = read_file(diff_file_path)
    analysis_prompt = """You are an expert technical editor. Please analyze the following diff and ensure it looks like a successful copy edit of a markdown file.
- Editing URLs is not allowed; never touch a link like [Image label](images/Manual_instructions_panel.png).
- It is not a successful edit if line one has been removed (editing is fine; removing is not).
- It is not a successful edit if three or more lines in a row have been removed without replacement.
- Edits or reformats are potentially good, but simply removing or adding a bunch of content is bad.
- Provide feedback if there are any issues.
- If it looks good, just reply with the single word: good"""

    payload = {
        "messages": [
            {"role": "system", "content": analysis_prompt},
            {"role": "user", "content": diff_content},
        ],
        "temperature": 0.2,
        "top_p": 0.95,
    }

    try:
        response = requests.post(endpoint, headers=headers, json=payload)
        response.raise_for_status()
        result = response.json()
        return result["choices"][0]["message"]["content"]
    except requests.RequestException as e:
        raise SystemExit(f"Failed to analyze diff. Error: {e}")


def process_file(input_file):
    content = read_file(input_file)
    docs = split_content(content)
    chunk_count = len(docs)

    if chunk_count > 1:
        print(f"Split into {chunk_count} docs")

    os.makedirs(EDIT_DIR, exist_ok=True)

    # Save the original content for diff generation
    original_content = content

    edited_content = get_edited_content(docs)
    temp_output_file = f"{EDIT_DIR}/edited_output.md"

    overall_result = None
    if edited_content == original_content:
        print(f"{input_file}: No edits made.")
        return "no_edits"

    with open(temp_output_file, "w") as f:
        f.write(edited_content)

    # Generate and save the diff for the whole file based on the basename of the input file
    input_basename = os.path.basename(input_file)
    diff_file_path = f"{EDIT_DIR}/{input_basename}.diff"
    diff = difflib.unified_diff(
        original_content.splitlines(), edited_content.splitlines(), lineterm=""
    )
    with open(diff_file_path, "w") as diff_file:
        diff_file.write("\n".join(diff))

    # Analyze the diff
    analysis_result = analyze_diff(diff_file_path)

    if analysis_result.lower().strip() == "good":
        os.replace(temp_output_file, input_file)
        print(f"{input_file}: edited!")
        return "edited"
    else:
        print(
            f"{input_file}: The diff looked suspect. Diff analysis result: {analysis_result}"
        )
        return "suspect_diff"


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py input_file")
    else:
        input_file = sys.argv[1]
        overall_result = process_file(input_file)
        with open(f"{EDIT_DIR}/proofread_results.txt", "a") as f:
            f.write(f"{input_file}: {overall_result}\n")
