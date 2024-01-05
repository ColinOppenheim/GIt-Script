#!/bin/bash

#This script checks if api_key.txt exists and if it is empty. 
#Depending on the result, it prompts the user to enter the API
#key manually or to quit. If the file exists and is not empty,
#it proceeds with the encryption process as before.


#!/bin/bash

# Function to check if api_key.txt exists and is not empty
function checkApiKeyFile {
    if [ -s api_key.txt ]; then
        return 0  # File exists and is not empty
    else
        return 1  # File does not exist or is empty
    fi
}

# Check if api_key.txt exists and is not empty
if checkApiKeyFile; then
    # File exists and is not empty
    API_KEY=$(<api_key.txt)
else
    # File does not exist or is empty
    read -p "api_key.txt does not exist or is empty. Do you want to manually enter the API key? (yes/no): " manual_entry

    if [[ "$manual_entry" =~ ^[yY](es)?$ ]]; then
        while true; do
            # Prompt user for API key
            read -p "Enter the API key: " API_KEY

            # Display the entered API key for user confirmation
            echo "Entered API key: $API_KEY"

            # Prompt user to confirm the API key
            read -p "Is the entered API key correct? (yes/no): " key_confirmation

            # Check the user's confirmation
            if [[ "$key_confirmation" =~ ^[yY](es)?$ ]]; then
                break  # Exit the loop if the API key is confirmed
            else
                echo "API key confirmation failed. Please re-enter the API key."
            fi
        done
    else
        echo "Quitting the script."
        exit 1
    fi
fi

# Proceed with the original script
while true; do
    # Prompt user for a password
    read -s -p "Enter a password for encryption: " password
    echo  # Move to a new line after the password prompt

    # Display the entered password for user confirmation
    echo "Entered password: $password"

    # Prompt user to confirm the password
    read -p "Is the entered password correct? (yes/no): " confirmation

    # Check the user's confirmation 
    if [[ "$confirmation" =~ ^[yY](es)?$ ]]; then
        # Encrypt the API key using the provided password
        encrypted_key=$(echo -n "$API_KEY" | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 \
            -salt -pass pass:"$password")

        # Save the encrypted key to a file
        echo -n "$encrypted_key" > encrypted_key.txt
        echo "API key successfully encrypted and saved to encrypted_key.txt."

        # Continue with further processing if needed
        break
    else
        echo "Password confirmation failed. Please re-enter the password."
    fi
done
