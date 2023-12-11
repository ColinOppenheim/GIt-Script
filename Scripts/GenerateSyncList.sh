#!/bin/bash

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