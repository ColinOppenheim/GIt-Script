#!/bin/bash

# Hard code access token for testing
ACCESS_TOKEN="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"

# Use relative path for csv file
csv_file="C:\Users\colin.oppenheim.admi\Desktop\Remote-SyncTest\Scripts\sync_list.csv"

# Check if csv file exists
if [ ! -f "$csv_file" ]; then
  read -p "CSV file not found at '$csv_file'. Enter the full path: " csv_file

  # Validate entered path
  if [ ! -f "$csv_file" ]; then
    read -p "Error: CSV file not found at '$csv_file' - enter a valid path or enter Q to quit: " input

    if [ "$input" = "Q" ] || [ "$input" = "q" ]; then
      echo "Exiting script."
      exit 1
    else
      csv_file=$input
    fi
  fi
fi

# Print full path if CSV file is valid
if [ -f "$csv_file" ]; then
  echo "Using CSV file at: $csv_file"
fi

# Exit if CSV file is still not valid
if [ ! -f "$csv_file" ]; then
  echo "Error: Valid CSV file not found. Exiting script."
  exit 1
fi

# Target directory where the local repository is located
target_dir="C:\Users\colin.oppenheim.admi\Desktop\Remote-SyncTest\RTMFM"

# Specify the remote repository and branch
REMOTE_REPO="github.com/ColinOppenheim/Learning-Repository.git"
BRANCH="master"

# Navigate to the target directory
cd "$target_dir"

# Add the remote repository with the access token if it doesn't exist
if ! git remote | grep -q remote-repo; then
    git remote add remote-repo "https://${ACCESS_TOKEN}@${REMOTE_REPO}"
fi

# Fetch the latest changes from the remote repository
git fetch remote-repo $BRANCH

# Initialize sparse-checkout if not already done
git sparse-checkout init

# Pattern to match hidden folder paths
HIDDEN_DIR_PATTERN="^\.*/"

while IFS=, read -r sync_status file_path; do

  file_path="${file_path//,/@}"

  if [[ "$file_path" =~ $HIDDEN_DIR_PATTERN ]]; then
    continue
  fi

  if [ "$sync_status" == "yes" ]; then
    git sparse-checkout set "\"$file_path\""
  else
    git sparse-checkout set "\"!$file_path\""
  fi

done < "$csv_file"

awk -F, '{gsub(/,/,"@")} $1 == "yes" {print "\"" $2 "\""}' "$csv_file" | xargs git checkout remote-repo/$BRANCH --

# Stage all changes and commit them to your local repository
git add .
git commit -m "Sync selected files from remote repository"

# Navigate back to the original directory
cd -