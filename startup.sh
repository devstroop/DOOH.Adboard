#!/bin/bash

# Function to display messages on tty1
display_message() {
    sudo sh -c "setterm -clear >/dev/tty1; echo '$1' >/dev/tty1"
}

# Navigate to the application directory
cd /home/admin/DOOH.Adboard

# Add the directory to Git's safe directories
git config --global --add safe.directory /home/admin/DOOH.Adboard

# Display message for checking updates
display_message "Checking for updates..."

# Check for updates
if git fetch --dry-run 2>/dev/null | grep -q 'origin'; then
    display_message "Updates available. Pulling changes..."
    if git pull; then
        display_message "Repository updated successfully."
    else
        display_message "Failed to pull updates."
    fi
else
    display_message "No updates available."
fi

# Start the .NET application
display_message "Starting application..."
/home/admin/.dotnet/dotnet /home/admin/DOOH.Adboard/net8.0/DOOH.Adboard.dll
