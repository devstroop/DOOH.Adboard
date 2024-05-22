#!/bin/bash

# Function to display messages
display_message() {
    sudo sh -c "setterm -clear >/dev/tty1; echo '$1' >/dev/tty1"
}

# Function to install dependencies
install_dependencies() {
    display_message "Installing dependencies..."
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y \
        git \
        vlc \
        libvlc-dev
        # libgl1-mesa-dev \
        # libgles2-mesa-dev \
        # libegl1-mesa-dev \
        # libdrm-dev \
        # libgbm-dev \
        # ttf-mscorefonts-installer \
        # fontconfig \
        # libsystemd-dev \
        # libinput-dev \
        # libudev-dev \
        # libxkbcommon-dev
}

# Function to install .NET
install_dotnet() {
    display_message "Installing .NET..."
    # Perform installation
    curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --version latest --verbose
    # Set environment variables
    echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
    echo 'export PATH=$PATH:$HOME/.dotnet' >> ~/.bashrc
    source ~/.bashrc
    # Review installed SDKs
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
    sudo raspi-config nonint do_memory_split 128
    sudo raspi-config nonint do_boot_splash 0
    sudo raspi-config nonint do_overscan 1
    sudo raspi-config nonint do_camera 0
}

# Function to pull repository in home directory
pull_repository() {
    display_message "Pulling repository..."
    git clone https://github.com/devstroop/DOOH.Adboard.git ~/DOOH.Adboard
    git config pull.rebase true
}

# Function to create the start script
create_start_script() {
    cat <<EOF | sudo tee /home/admin/start_dooh_adboard.sh > /dev/null
#!/bin/bash
# Navigate to the application directory
cd /home/admin/DOOH.Adboard
# Add the directory to Git's safe directories
git config --global --add safe.directory /home/admin/DOOH.Adboard
# Pull the latest code from the repository
git pull
# Start the .NET application
/home/admin/.dotnet/dotnet /home/admin/DOOH.Adboard/net8.0/DOOH.Adboard.dll
EOF
    sudo chmod +x /home/admin/start_dooh_adboard.sh
}

# Function to set up services
setup_services() {
    display_message "Setting up services..."
    cat <<EOF | sudo tee "/etc/systemd/system/dooh.adboard.service" > /dev/null
[Unit]
Description=DOOH Adboard Service
[Service]
Environment="DISPLAY=:0"
ExecStart=/bin/bash /home/admin/start_dooh_adboard.sh
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable "dooh.adboard.service"
    sudo systemctl start "dooh.adboard.service"
}

# Main script
install_dependencies
install_dotnet
install_debugger
configure_system
pull_repository
create_start_script
setup_services

# Final message
display_message "Installed Successfully! Rebooting..."
sudo reboot
