#!/bin/bash

<< ////
This script functions as an initial snapshot tool to identify all the files 
in a local folder, and add them to a .csv so they can be used to sync that 
list of files with another repository. It will populate the list of files 
recursively from the target folder specified in the scan_directory variable. 
Each file will be added to the CSV file with a "Sync" column that will be 
set to "yes".

This script is designed to be used as a one-time tool to generate a CSV file. 
It is not intended to be used as a regular sync tool. For that you will need 
to use AppendSyncList-alaGit.sh instead.

This script is intended to be run from the command line.

The script will output a message indicating the location of the CSV file.

This script is written in Bash.

This script is licensed under the MIT license.
////


# Specify the directory to scan
scan_directory=~/Vaults/Public/Learning-Repository

# Define the output CSV file
csv_file="sync_list.csv"

# Clear the existing CSV file
> "$csv_file"

# Iterate over each file in the specified directory
find "$scan_directory" -type f | while read -r file; do
    # Calculate the relative path
    relative_path="${file#"$scan_directory"/}"

    # Set the "Sync" value to "yes"
    sync_value="yes"

    # Append the entry to the CSV file with filenames encapsulated in quotes
    echo "$sync_value,\"$relative_path\"" >> "$csv_file"
done

echo "Sync list generated and saved to $csv_file"