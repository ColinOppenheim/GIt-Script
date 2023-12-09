#!/bin/bash

# Access token 
ACCESS_TOKEN="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"

# Remote repo
REMOTE_REPO="github.com/ColinOppenheim/Learning-Repository.git"  
# Branch
BRANCH="master"
# CSV file
csv_file="C:\\Users\\colin.oppenheim.admi\\Desktop\\Remote-SyncTest\\Scripts\\sync_list.csv"  
# Create temporary CSV file
temp_csv_file=$(mktemp)
# Escape spaces in "yes" rows 
awk -F, '$1 == "yes" {gsub(/ /,"\\ ",$2); print $0}' "$csv_file" > "$temp_csv_file"
# Read "yes" rows into array
IFS=, read -r -a files_to_sync < <(awk -F, '$1 == "yes" {print $2}' "$temp_csv_file")
# Target directory
target_dir="C:\\Users\\colin.oppenheim.admi\\Desktop\\Remote-SyncTest\\RTMFM"
cd "$target_dir"
# Add remote 
git remote add remote-repo "https://${ACCESS_TOKEN}@${REMOTE_REPO}"
# Fetch changes
git fetch remote-repo $BRANCH  
# Initialize sparse checkout
git sparse-checkout init
# Pattern to match hidden folders
HIDDEN_DIR_PATTERN="^\.*/"
# Loop through files array 
while IFS=, read -r sync_status file_path; do
  if [ "$sync_status" == "no" ]; then
    git sparse-checkout set "\"!$file_path\""
  fi
  if [ "$sync_status" == "yes" ]; then  
    git sparse-checkout set "\"$file_path\"" 
  fi
done < "$csv_file"
# Checkout files
git checkout remote-repo/$BRANCH -- "${files_to_sync[@]}"
# Commit changes
git commit -m "Sync files"
cd -
# Cleanup
rm "$temp_csv_file"