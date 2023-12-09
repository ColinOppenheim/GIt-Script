#!/bin/bash

# Access token
ACCESS_TOKEN="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" 

# Remote repo
REMOTE_REPO="github.com/ColinOppenheim/Learning-Repository.git"

# Branch 
BRANCH="master"

# CSV file
csv_file="C:\\Users\\colin.oppenheim.admi\\Desktop\\Remote-SyncTest\\Scripts\\sync_list.csv"   

# Target directory
target_dir="C:\\Users\\colin.oppenheim.admi\\Desktop\\Remote-SyncTest\\RTMFM"

cd "$target_dir"

# Add remote
git remote add remote-repo "https://${ACCESS_TOKEN}@${REMOTE_REPO}"

# Fetch changes
git fetch remote-repo $BRANCH   

HIDDEN_DIR_PATTERN="^\.[^\/]+"

#git sparse-checkout init

files_yes=()
files_no=()

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

#Inspect Array Contents
# echo "Files to add from sparse checkout:" 
# for file in "${files_yes[@]}"; do
#   echo $file
# done
# echo "Files to remove from sparse checkout:"  
# for file in "${files_no[@]}"; do
#   echo $file 
# done
# echo "Output to inspect"
# read -p "Press [Enter] key to continue"

# Sparse checkout commands
# Construct array of 'git checkout -- ' + file path
# checkout_cmds=()
# for file in "${files_yes[@]}"; do
#   checkout_cmds+=("git sparse-checkout \"$file\"") 
# done

# # Run the git checkout commands
# echo "${checkout_cmds[@]}" | xargs -0 git -C "$repo_dir"


for file in "${files_yes[@]}"; do
  git checkout origin/$branch -- "$file"
  echo "Checked out $file"
done

# Loop through no files
for file in "${files_no[@]}"; do
  # Remove the file from disk
  rm -rf "$repo_dir/$file"
done

#git commit -m "Sync files"

#cd -