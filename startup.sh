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
if [[ $(git rev-list HEAD...origin/main --count) -gt 0 ]]; then
    display_message "Updates available! Applying changes..."
    # Pull updates from the remote repository
    if git stash && git pull --rebase; then
        sudo chmod +x /home/admin/DOOH.Adboard/startup.sh
        display_message "Updated successfully!"
    else
        display_message "Failed to update!"
    fi
else
    display_message "No updates available!"
fi

# Start the .NET application
display_message "Starting application..."
/home/admin/.dotnet/dotnet /home/admin/DOOH.Adboard/net8.0/DOOH.Adboard.dll