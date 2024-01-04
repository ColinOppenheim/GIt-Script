#!/bin/bash
<< ////
This script is what makes the magic happen in syncing the remote repo to the local repo.
It takes a CSV file as input and uses that to sync the remote repo to a local onsite repo.
The advantage in this method is allows updating of new content from the remote repo without
having to manually update the local repo or make the local repo a fork of the original repo.

The main requirements are the API_KEY, REMOTE_REPO, BRANCH, target_repo_dir, and csv_file. These
are all set in the script; however, if they locations can not be found for the target_repo_dir
or csv_file, the script will prompt the user to enter the correct path.The script will also prompt 
the user to initialize a new Git repo if one is not found in the target folder as having a gitrepo 
within the target folder is required for the script to work.

The script works by reading the CSV file into two seperate arrays. The script file paths are stored in
the CSV in quotes to ensure spaces and special characters within file names is captured,he first array
is a list of files to be added to the repo. The second array is a list of files to be removed from the
repo.

It will then iterate through the first array and add each file to the repo. If the file already exists in
the target directory, it will be skipped. If the file does not exist in the target repo, it will be added.
After the second iteration it will remove any files listed in the CSV that are not in the locations
specified by the CSV. This ensures the file names and folder structure within the repo match the data
within the CSV so if a particular file is changed or moved it will be updated into the proper location.

////
# Function to validate and expand a given path
expand_path() {
  local input_path=$1
  
  # Check if absolute or relative path
  if [[ $input_path == /* ]]; then 
    # Absolute path
    expanded_path=$(realpath "$input_path")
  else
    # Relative path 
    normalized_path=${input_path/#\~/$HOME}
    expanded_path=$(realpath "$normalized_path")
  fi

  echo "$expanded_path"
}

# GitHub API token
API_KEY="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"

# Remote repo URL with embedded token  
REMOTE_REPO="https://$API_KEY@github.com/ColinOppenheim/Learning-Repository.git"
BRANCH="master"

# Target directory for syncing files  
target_repo_dir="C:\\Users\\colin.oppenheim.admi\\Desktop\\Remote-SyncTest\\RTMFM\\"

# CSV file
csv_file="C:\\Users\\colin.oppenheim.admi\\Desktop\\Remote-SyncTest\\Scripts\\sync_list.csv"

# Check if target dir exists
if [ ! -d "$target_repo_dir" ]; then
  while true; do
    echo $target_repo_dir
    # Prompt for new directory
    read -p "Original target directory not found. Do you wish to Enter a new one or exit? (y/n) " exit_script
    # Take action based on input
    if [[ $exit_script == "y" || $exit_script == "Y" ]]; then
      # Prompt for new directory
      read -p "Enter new target directory:" new_target_dir
      new_target_dir=$(echo "$new_target_dir" | tr -d '[:space:]')
      new_target_dir=$(expand_path "$new_target_dir")

      echo "New Target Directory is: $new_target_dir"
      # Validate new input is directory
      if [ ! -d "$new_target_dir" ]; then
        echo "Invalid directory. Please try again."
        continue
      else
        # Set target dir to the new one
        target_repo_dir=$new_target_dir
        break
      fi
    else
      echo "Exiting No Target Directory Specified"
      exit 1
    fi
  done
fi

# Check if Git repo exists
if [ ! -d "$target_repo_dir/.git" ]; then

  # Prompt user
  read -p "No Git repo found. Initialize new repo? (y/n) " init_repo
  
  # Take action based on input
  if [[ $init_repo == "y" || $init_repo == "Y" ]]; then
    git -C "$target_repo_dir" init
  else
    echo "Exiting without initializing Git repo"
    exit 2
  fi

fi

# Check if CSV file exists
if [ ! -f "$csv_file" ]; then
  # Prompt for correct path
  read -p "sync_list.csv file not found. Enter correct path: " csv_file
  csv_file=$(echo "$csv_file" | tr -d '[:space:]')
  csv_file=$(expand_path "$csv_file")
  
  # Validate new input is CSV file
  if [[ "$csv_file" != *.csv ]]; then
    echo "Invalid file type. Please input CSV file path."
    exit 3
    else
    # Set CSV file to the new one
    csv_file=$csv_file
  fi
fi

# Temporary file for corrected content
temp_csv_file=$(mktemp)

# Replace spaces with escaped paths in CSV 
awk -F, '{
  if ($1 == "yes" || $1 == "no") { 
    if ($2 !~ /\/\./) print $0;  
  }
}' "$csv_file" > "$temp_csv_file"

# Populate sync lists
FILES_TO_TRACK=()
FILES_TO_REMOVE=() 

while IFS=, read -r sync_status file_path; do
    # Remove quotes 
  file_path="${file_path//\"}"
  
  # Skip files starting with ./
  if [[ "${file_path:0:1}" == "." ]]; then
    #echo "$file_path Matches" 
    continue
  fi
  # Skip readme.md files (case-insensitive)
  if [[ "${file_path,,}" == "readme.md" ]]; then
    #echo "$file_path Matches" 
    continue 
  fi
  
  if [[ "$sync_status" == "yes" ]]; then
    FILES_TO_TRACK+=("$file_path")
  elif [[ "$sync_status" == "no" ]]; then
    FILES_TO_REMOVE+=("$file_path") 
  fi
done < "$temp_csv_file"

# # Print files to track 
# echo "Files to track:"
# printf '%s\n' "${FILES_TO_TRACK[@]}"
# read -p ""

# # Print files to remove
# echo "Files to remove:" 
# printf '%s\n' "${FILES_TO_REMOVE[@]}"
# read -p ""

# Fetch latest master branch updates
echo "Fetching latest updates from $BRANCH branch..."
git -C "$target_repo_dir" fetch --depth=1 $REMOTE_REPO $BRANCH
# echo "Press enter to continue..."
# read -p ""

# Checkout files 
for file_path in "${FILES_TO_TRACK[@]}"; do
    if git -C "$target_repo_dir" show "FETCH_HEAD":"$file_path"> /dev/null 2>&1; then 
        git -C "$target_repo_dir" checkout "FETCH_HEAD" -- "$file_path"
        echo "Checking out $file_path"  
    else
        echo "Error checking out $file_path" >&2
    fi
done

echo "Attempting to remove any files no longer in sync"

# Remove files  
for file_path in "${FILES_TO_REMOVE[@]}"; do
  full_path="$target_repo_dir/$file_path"
  
  if [ -f "$full_path" ] && [[ "$file_path" != .* ]]; then
    echo "Removing file: $file_path" 
    rm "$full_path"
  fi
done

# Clean up
rm "$temp_csv_file"