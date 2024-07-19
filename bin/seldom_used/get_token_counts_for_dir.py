import glob
from token_count import TokenCount
import sys

# pip install token-count

tc = TokenCount(model_name="gpt-3.5-turbo")

# get base dir from argv
base_dir = sys.argv[1] if len(sys.argv) > 1 else "."
file_extension = sys.argv[2] if len(sys.argv) > 2 else "py"

# text = "Your text here"
# tokens = tc.num_tokens_from_string(text)
# print(f"Tokens in the string: {tokens}")
#
# file_path = "path/to/your/file.txt"
# tokens = tc.num_tokens_from_file(file_path)
# print(f"Tokens in the file: {tokens}")

# dir_path = "src/spiffworkflow_backend"
# tokens = tc.num_tokens_from_directory(dir_path)
# print(f"Tokens in the directory: {tokens}")

total_tokens = 0
file_to_token_count_map = {}

# find all python files in src/spiffworkflow_backend with glob
# glob_arg = f"src/spiffworkflow_backend/**/*.py"
glob_arg = f"{base_dir}/**/*.{file_extension}"
for file in glob.glob(glob_arg, recursive=True):
    tokens = tc.num_tokens_from_file(file)
    total_tokens += tokens
    # print(f"Tokens in {file}: {tokens}")
    file_to_token_count_map[file] = tokens

# give report of files with most tokens
sorted_token_tuples = sorted(file_to_token_count_map.items(), key=lambda item: item[1], reverse=True)

print("Top 10 files with most tokens:\n")
for i in range(10):
    file, tokens = sorted_token_tuples[i]
    print(f"➡️ ➡️ ➡️  {file}: {tokens}")

print()
print(f"➡️ ➡️ ➡️  total_tokens: {total_tokens}")
