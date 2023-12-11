#!/bin/bash

# Specify the directory to scan (make it recursive)
main_repo_dir=~/Vaults/Learning-Repository

# Existing CSV file
csv_file="sync_list.csv"

# Check if the CSV file exists
if [ ! -f "$csv_file" ]; then
    echo "CSV file $csv_file not found."
    exit 1
fi

# Get the absolute path of the main repository directory
main_repo_dir=$(realpath "$main_repo_dir")

# Create a temporary file to store the updated CSV content
temp_csv_file=$(mktemp)

# First Iteration: Check for files in CSV but not in the master branch
while IFS=, read -r sync_status file_path; do
    # Construct the full path to the file
    full_path="$main_repo_dir/$file_path"

    # Check if the file exists in the master branch of the repository
    if git -C "$main_repo_dir" rev-parse --quiet --verify "master:$file_path" > /dev/null; then
        # File exists in the master branch, keep it in the CSV with its current sync status
        if [[ $file_path != \"*\" ]]; then
            file_path="\"$file_path\""
        fi
        echo "$sync_status,$file_path" >> "$temp_csv_file"
    else
        # File does not exist in the master branch, remove it from the CSV
        echo "File '$file_path' not found in the master branch. Removing from CSV."
    fi
done < "$csv_file"

# Second Iteration: Check for new files in the master branch and append to CSV with sync status "no"
git -C "$main_repo_dir" ls-tree --name-only -r master | while read -r file_path; do
    # Check if the file is already in the CSV
    if ! grep -q "\"$file_path\"" "$temp_csv_file"; then
        # File is not in the CSV, append it with sync status "no"
        echo "no,\"$file_path\"" >> "$temp_csv_file"
        echo "New file '$file_path' found in the master branch. Appending to CSV with sync status 'no'."
    fi
done

# Replace the original CSV file with the updated content
mv "$temp_csv_file" "$csv_file"

echo "Sync list updated in the CSV file: $csv_file"