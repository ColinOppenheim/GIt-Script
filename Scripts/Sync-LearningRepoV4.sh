#!/bin/bash

# CSV file
csv_file="C:\\Users\\colin.oppenheim.admi\\Desktop\\Remote-SyncTest\\Scripts\\sync_list.csv"   

# Target directory
main_repo_dir="C:\\Users\\colin.oppenheim.admi\\Desktop\\Remote-SyncTest\\RTMFM"

cd "$main_repo_dir"

# Specify the remote repository and branch
REMOTE_REPO="https://github.com/ColinOppenheim/Learning-Repository.git"
BRANCH="master"
ACCESS_TOKEN="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"

# Fetch the latest changes 
if ! git -C "$main_repo_dir" fetch --depth=1 $REMOTE_REPO $BRANCH; then
  echo "Error fetching" >&2
  exit 1 
fi

#Populate Array of Files to keep and remove
files_yes=()
files_no=()

HIDDEN_DIR_PATTERN="^\.[^\/]+"

while IFS=, read -r sync_status file_path; do
#   echo "File path: $file_path"
  if [[ "$file_path" =~ $HIDDEN_DIR_PATTERN ]]; then
    #echo "Hidden file"
    continue 
  fi
  if [ "$sync_status" == "yes" ]; then
    files_yes+=("$file_path")
  else
    # Check if path is hidden before adding to files_no
    if [[ ! "$file_path" =~ $HIDDEN_DIR_PATTERN ]]; then
      files_no+=("$file_path")
    fi
  fi
done < "$csv_file"

# #Inspect Array Contents
#  echo "Files to add from sparse checkout:" 
#  for file in "${files_yes[@]}"; do
#    echo $file
#  done
#  echo "Files to remove from sparse checkout:"  
#  for file in "${files_no[@]}"; do
#    echo $file 
#  done
#  echo "Output to inspect"
#  read -p "Press [Enter] key to continue"

# # Construct the full path to the file
#     full_path="$main_repo_dir/$file_path"

# Construct space-separated list of files to check out 
files_list="${files_yes[@]}"

echo "Files to check out: $files_list"

# Fetch the latest changes using the personal access token
fetched_branch=$(git -C "$main_repo_dir" fetch --quiet --depth=1 $REMOTE_REPO $BRANCH)

# Checkout the files
#git -C "$main_repo_dir" checkout $fetched_branch -- $files_list

for file in "${files_yes[@]}"; do
   echo "Checking if file exists: $file"
   if git -C "$main_repo_dir" show "$fetched_branch":"$file" > /dev/null 2>&1; then
     echo "File exists, attempting checkout: $file" 
     git -C "$main_repo_dir" checkout "$fetched_branch" -- "$file"
     echo "Checked out file: $file"
   else
     echo "File does NOT exist, skipping: $file"
   fi
 done

# Loop through no files
for file in "${files_no[@]}"; do
  # Remove the file from disk
  rm -rf "$repo_dir/$file"
done

#git commit -m "Sync files"

#cd -