#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored status messages
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    exit 1
fi

# DNF Configuration
print_status "Configuring DNF..."
DNF_CONF="/etc/dnf/dnf.conf"

cat > "$DNF_CONF" << EOL
[main]
gpgcheck=True
installonly_limit=2
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
fastestmirror=true
EOL

if [ $? -eq 0 ]; then
    print_success "DNF configuration updated successfully"
else
    print_error "Failed to update DNF configuration"
    exit 1
fi

# Package list
packages=(
    gcc
    gcc-c++
    jq
    java-21-openjdk-headless
    podman
    git
    zoxide
    fzf
    bat
    fish
    tmux
    aria2
    fastfetch
    alacritty
    distrobox
    gnome-boxes
    vlc
    libreoffice
    okular
    qalculate-qt
    qbittorrent
    kile
    kate
    kwrite
    gwenview
    "fedora-media-writer"
)

# Install packages
print_status "Installing packages..."
if dnf install -y "${packages[@]}"; then
    print_success "All packages installed successfully"
else
    print_error "Some packages failed to install"
    exit 1
fi

print_success "Setup completed successfully"
