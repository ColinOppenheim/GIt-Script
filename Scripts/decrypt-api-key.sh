#!/bin/bash

# Initialize flags
silent=false

# Process command line options
while getopts ":s" opt; do
  case $opt in
    s)
      silent=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Prompt user for the decryption password
read -s -p "Enter the decryption password: " password
echo  # Move to a new line after the password prompt

# Read the encrypted key from the file
encrypted_key=$(<encrypted_key.txt)

# Decrypt the key, redirect stderr to null
decrypted_key=$(echo -n "$encrypted_key" | openssl enc -d -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 \
    -salt -pass pass:"$password" 2>/dev/null)

# Check if decryption was successful
if [ $? -eq 0 ] && [ -n "$decrypted_key" ]; then
    if [ "$silent" = true ]; then
        # Output the decrypted key without any trailing whitespace in silent mode
        echo -n "$decrypted_key"
    else
        echo "Decryption successful."
        echo "Decrypted Key: $decrypted_key"
    fi
else
    if [ "$silent" = true ]; then
        exit 1  # Exit with an error code in silent mode
    else
        echo "Decryption failed. Please check the password and try again."
        exit 1
    fi
fi
