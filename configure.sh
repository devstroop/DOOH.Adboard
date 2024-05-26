#!/bin/bash

# Function to display messages
display_message() {
    sudo sh -c "setterm -clear >/dev/tty1; echo '$1' >/dev/tty1"
}

# Function to install dependencies
install_dependencies() {
    display_message "Installing dependencies..."
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y git vlc libvlc-dev zram-tools
    if [ $? -ne 0 ]; then
        display_message "Failed to install dependencies!"
        exit 1
    fi
}

# Function to install .NET
install_dotnet() {
    display_message "Installing .NET..."
    curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --version latest --verbose
    echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
    echo 'export PATH=$PATH:$HOME/.dotnet' >> ~/.bashrc
    source ~/.bashrc
    dotnet --list-sdks
}

# Function to install .NET debugger
install_debugger() {
    display_message "Installing .NET Debugger..."
    curl -sSL https://aka.ms/getvsdbgsh | /bin/sh /dev/stdin -v latest -l ~/vsdbg
}

# Function to configure system settings
configure_system() {
    display_message "Configuring system..."
    sudo usermod -a -G input $USER
    sudo raspi-config nonint do_boot_behaviour B2
    sudo timedatectl set-timezone "Asia/Kolkata"
    sudo raspi-config nonint do_memory_split 48
    sudo raspi-config nonint do_boot_splash 0
    sudo raspi-config nonint do_overscan 1
    sudo raspi-config nonint do_camera 0

    echo 'export XDG_RUNTIME_DIR=/tmp/.dotnet' >> ~/.bashrc
    source ~/.bashrc

    # Install and configure cron for time synchronization
    sudo apt-get install -y cron
    sudo timedatectl set-ntp true
}

# Function to clone the repository
clone_repository() {
    display_message "Cloning repository..."
    [ -d /home/admin/DOOH.Adboard ] && rm -rf /home/admin/DOOH.Adboard
    git clone https://github.com/devstroop/DOOH.Adboard.git /home/admin/DOOH.Adboard
    git -C /home/admin/DOOH.Adboard config pull.rebase true
}

# Function to set up services
setup_services() {
    display_message "Setting up services..."
    sudo systemctl stop "dooh.adboard.service" 2>/dev/null || true
    sudo systemctl disable "dooh.adboard.service" 2>/dev/null || true
    sudo chmod +x /home/admin/DOOH.Adboard/startup.sh
    cat <<EOF | sudo tee "/etc/systemd/system/dooh.adboard.service" > /dev/null
[Unit]
Description=DOOH Adboard Service

[Service]
Environment="DISPLAY=:0"
ExecStartPre=/bin/sleep 10
ExecStart=/bin/bash /home/admin/DOOH.Adboard/startup.sh >> /home/admin/DOOH.Adboard/service.log 2>&1
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable "dooh.adboard.service"
    sudo systemctl start "dooh.adboard.service"

    
    # Set up log rotation
    sudo tee /etc/logrotate.d/dooh-adboard <<EOF
/home/admin/DOOH.Adboard/service.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 admin admin
    sharedscripts
    postrotate
        systemctl reload dooh.adboard.service > /dev/null
    endscript
}
EOF
}

setup_zram() {
    NEW_SIZE=256
    FILE="/etc/default/zramswap"

    # Use sed to update the SIZE parameter in the file
    sudo sed -i "s/^#*SIZE=.*/SIZE=$NEW_SIZE/" $FILE

    # Check if the sed command was successful
    if [ $? -eq 0 ]; then
        echo "SIZE updated to $NEW_SIZE MiB in $FILE"
    else
        echo "Failed to update SIZE in $FILE"
    fi

    sudo systemctl enable zramswap.service
    sudo systemctl start zramswap.service
}


# Main script execution
install_dependencies
install_dotnet
install_debugger
configure_system
clone_repository
setup_services
setup_zram

# Final message
display_message "Installed Successfully! Rebooting..."
sudo reboot
