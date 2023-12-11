#!/bin/bash

# GitHub API token
API_KEY="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"

# Remote repo details
REMOTE_REPO="https://github.com/ColinOppenheim/Learning-Repository.git"
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
  if [[ "$sync_status" == "yes" ]]; then
    FILES_TO_TRACK+=("$file_path")
  elif [[ "$sync_status" == "no" ]]; then
    FILES_TO_REMOVE+=("$file_path")
  fi  
done < "$temp_csv_file"


# Fetch updates using API key
git -c "http.extraheader=AUTHORIZATION: token $API_KEY" -C "$target_repo_dir" fetch "$REMOTE_REPO" "$BRANCH"

# Checkout files using API key 
for file_path in "${FILES_TO_TRACK[@]}"; do
  full_path="$target_repo_dir/$file_path"

  if git -c "http.extraheader=AUTHORIZATION: token $API_KEY" -C "$target_repo_dir" show "$BRANCH":"$file_path" > /dev/null 2>&1; then  
    git -c "http.extraheader=AUTHORIZATION: token $API_KEY" -C "$target_repo_dir" checkout "$BRANCH" -- "$file_path"
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