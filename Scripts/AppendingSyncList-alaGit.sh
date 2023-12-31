#!/bin/bash
<< ////
This script functions as an updater to identify what new files have been 
found in the master branch of a Git repository and append them to a CSV file. 
The CSV file is used as a list of files to be synced with a remote repository. 
By default any new file found will be will be appended to the CSV with a sync 
status of "no", meaning it will not be synced with the remote repository. You 
will need to change change the sync status to "yes" in the CSV file to sync 
the file with the remote repository.

It is designed to look at a local copy of the repository and not the remote 
repository, so you will need to have a copy of that repository on your local 
machine and have that directory specified inthe main_repo_dir variable. Future 
improvements will attempt to pull the list from another location or use the 
remote repository directly.

This script is intended to be run from the command line.
////

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
    org_file_path=$file_path
    # Remove quotes from file_path for verification
    file_path_no_quotes=$(sed 's/"//g' <<< "$file_path")
    # Construct the full path to the file with quotes
    full_path="\"$main_repo_dir/$file_path_no_quotes\""
    echo "Checking file $full_path..."

    # Check if the file exists in the master branch of the repository
    if git -C "$main_repo_dir" rev-parse --quiet --verify "master:$org_file_path_no_quotes" > /dev/null; then
        # Add quotes to file_path if it is not empty and has no quotes; otherwise, leave it alone.
        echo "Current value of file_path: $org_file_path"
        if [[ $org_file_path != \"\" && $org_file_path != \"*\" && ${file_path:0:1} != "\"" && ${file_path: -1} != "\"" ]]; then
            file_path="\"$file_path_no_quotes\""
            file_path="${file_path%$'\n'}" # Remove trailing newline character if present
        fi
        # File exists in the master branch, keep it in the CSV with its current sync status
        echo "$sync_status,$file_path" >> "$temp_csv_file"
    else
        # File does not exist in the master branch, remove it from the CSV
        echo "File $full_path not found in the master branch. Removing from CSV."
    fi
done < "$csv_file"

echo "Done with first iteration verifying existing files, now identifying new files...."

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