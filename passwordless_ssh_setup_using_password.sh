#!/bin/bash

# Usage: ./setup_ssh.sh <remote_user> <remote_host> <remote_password>

# Check if arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <remote_user> <remote_host> <remote_password>"
    exit 1
fi

# Assign arguments to variables
REMOTE_USER=$1
REMOTE_HOST=$2
REMOTE_PASS=$3

# Function to check and install sshpass
install_sshpass() {
    if command -v sshpass &>/dev/null; then
        echo "sshpass is already installed."
    else
        echo "sshpass is not installed. Attempting to install..."

        # Detect package manager and install sshpass
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y sshpass
        elif command -v yum &>/dev/null; then
            sudo yum install -y sshpass
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y sshpass
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy sshpass
        else
            echo "Package manager not recognized. Please install sshpass manually."
            exit 1
        fi

        # Verify installation
        if ! command -v sshpass &>/dev/null; then
            echo "sshpass installation failed. Please install it manually."
            exit 1
        fi
    fi
}

# Check and install sshpass if necessary
install_sshpass

# Generate SSH key pair if not already existing
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo "Generating SSH key pair..."
    ssh-keygen -t rsa -N "" -f "$HOME/.ssh/id_rsa"
else
    echo "SSH key pair already exists. Skipping key generation."
fi

# Copy the public key to the remote host using sshpass
echo "Copying SSH public key to $REMOTE_USER@$REMOTE_HOST..."
sshpass -p "$REMOTE_PASS" ssh-copy-id -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST"

# Verify the passwordless SSH connection
echo "Testing SSH connection..."
ssh -o PasswordAuthentication=no "$REMOTE_USER@$REMOTE_HOST" "echo 'Passwordless SSH setup successful!'"

# Confirmation message
if [ $? -eq 0 ]; then
    echo "Passwordless SSH setup completed successfully."
else
    echo "Failed to set up passwordless SSH. Please check the provided details."
fi

