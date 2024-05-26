#!/bin/bash

# Function to display messages on tty1
display_message() {
    sudo sh -c "setterm -clear >/dev/tty1; echo '$1' >/dev/tty1"
}

# In startup.sh before starting the application
if pgrep -f "DOOH.Adboard.dll" > /dev/null; then
    display_message "Application already running!"
    exit 1
fi

# Start the .NET application
display_message "Starting application..."
/home/admin/.dotnet/dotnet /home/admin/DOOH.Adboard/net8.0/DOOH.Adboard.dll
