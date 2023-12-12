#!/bin/bash

# GitHub API token
API_KEY="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"

# Remote repo URL with embedded token  
REMOTE_REPO="https://$API_KEY@github.com/ColinOppenheim/Learning-Repository.git"
BRANCH="master"

# CSV file 
csv_file="C:\\Users\\colin.oppenheim.admi\\Desktop\\Remote-SyncTest\\Scripts\\sync_list.csv"

# Temporary file for corrected content
temp_csv_file=$(mktemp)

# Target directory for syncing files  
target_repo_dir="C:\\Users\\colin.oppenheim.admi\\Desktop\\Remote-SyncTest\\RTMFM"

# Replace spaces with escaped paths in CSV 
awk -F, '{
  if ($1 == "yes" || $1 == "no") {  
    gsub(/ /, "\\\\ ", $2);
    gsub(/([()\[\]{}*?+^$|])/,"\\\\\\1",$2);
    if ($2 !~ /\/\./) print $0; 
  }
}' "$csv_file" > "$temp_csv_file"

# Populate sync lists
FILES_TO_TRACK=()
FILES_TO_REMOVE=() 

while IFS=, read -r sync_status file_path; do
  file_path="${file_path//\"}"
  
  if [[ "$sync_status" == "yes" ]]; then
    FILES_TO_TRACK+=("$file_path")
  elif [[ "$sync_status" == "no" ]]; then
    FILES_TO_REMOVE+=("$file_path")
  fi
done < "$temp_csv_file"


# Fetch latest master branch updates
git -C "$target_repo_dir" fetch --depth=1 $REMOTE_REPO $BRANCH

# Checkout files 
for file_path in "${FILES_TO_TRACK[@]}"; do
    if git -C "$target_repo_dir" show "FETCH_HEAD":"$file_path"> /dev/null 2>&1; then 
        git -C "$target_repo_dir" checkout "FETCH_HEAD" -- "$file_path"
        echo "Checking out $file_path"  
    else
        echo "Error checking out $file_path" >&2
    fi
done

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