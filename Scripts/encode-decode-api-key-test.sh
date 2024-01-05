#!/bin/bash

while true; do
    # Prompt user for a password
    read -s -p "Enter a password for encryption: " password
    echo  # Move to a new line after the password prompt

    # Display the entered password for user confirmation
    echo "Entered password: $password"

    # Prompt user to confirm the password
    read -p "Is the entered password correct? (yes/no): " confirmation

    # Check the user's confirmation
    if [ "$confirmation" == "yes" ]; then
        # Encrypt the API key using the provided password
        encrypted_key=$(cat api_key.txt | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 \
        -salt -pass pass:"$password")

        echo "The new key is $encrypted_key"
        # Save the encrypted key to a file (without newline characters)
        echo -n "$encrypted_key" > encrypted_key.txt

        cat encrypted_key.txt

        echo "API key successfully encrypted and saved to encrypted_key.txt."

        # Decrypt the contents of encrypted_key.txt using the provided password
        decrypted_key=$(cat encrypted_key.txt | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 \
        -salt -pass pass:"$password")

        # Check if decryption was successful
        if [ $? -eq 0 ] && [ -n "$decrypted_key" ]; then
            echo "Decryption successful."
            echo "Decrypted Key: $decrypted_key"
        else
            echo "Decryption failed. Please check the password and try again."
        fi

        # Continue with further processing if needed
        break
    else
        echo "Password confirmation failed. Please re-enter the password."
    fi
done
