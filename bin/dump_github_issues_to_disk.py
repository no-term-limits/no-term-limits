import os
import requests

# you can't search the contents of comments of github issues.
# but grep works, so just dump issues to disk.

# Get the GitHub token from the environment variables
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
if not GITHUB_TOKEN:
    raise EnvironmentError("Please set the GITHUB_TOKEN environment variable.")

# Hardcoded repository details
REPO_OWNER = 'sartography'
REPO_NAME = 'spiff-arena'
OUTPUT_DIR = 'issues_dump'

# Create the output directory if it doesn't exist
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

def get_issues(page=1):
    url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/issues"
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }
    params = {
        "state": "all",
        "per_page": 100,
        "page": page
    }
    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()
    return response.json()

def get_comments(issue_number):
    url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/issues/{issue_number}/comments"
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.json()

def save_issue(issue):
    issue_number = issue['number']
    filename = f"{OUTPUT_DIR}/issue_{issue_number}.txt"
    with open(filename, 'w', encoding='utf-8') as file:
        # Write issue summary
        file.write(f"Summary: {issue['title']}\n\n")
        file.write(f"{issue['body']}\n\n" if issue['body'] else "No description provided.\n\n")
        
        # Get and write comments
        comments = get_comments(issue_number)
        if comments:
            file.write("First Comment:\n")
            file.write(f"{comments[0]['body']}\n\n")
            if len(comments) > 1:
                file.write("Other Comments:\n")
                for comment in comments[1:]:
                    file.write(f"{comment['body']}\n\n")
        else:
            file.write("No comments.\n")

def main():
    page = 1
    while True:
        issues = get_issues(page)
        if not issues:
            break
        for issue in issues:
            save_issue(issue)
        page += 1
        print(f"Fetched and saved page {page}")

if __name__ == "__main__":
    main()
