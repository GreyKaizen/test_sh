#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Progress spinner characters
SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

# Function to show spinner
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr=$SPINNER
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${CYAN}%c${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b"
    done
    printf "  \b\b"
}

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

# Backup existing configuration
if [ -f "$DNF_CONF" ]; then
    cp "$DNF_CONF" "${DNF_CONF}.backup"
    print_success "Backup created: ${DNF_CONF}.backup"
fi

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

# System update
print_status "Updating system packages..."
if dnf update -y; then
    print_success "System update completed"
else
    print_warning "System update encountered some issues"
    read -p "Continue with package installation? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
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
    mediawriter
)

# Install packages
print_status "Installing packages..."
print_warning "This may take a while depending on your internet speed"

if dnf install -y "${packages[@]}" & show_spinner $!; then
    print_success "All packages installed successfully"
else
    print_error "Some packages failed to install"
    exit 1
fi

print_success "Setup completed successfully"

# Display final message with next steps
cat << EOL

${GREEN}=== Next Steps ===${NC}
1. Consider setting fish as your default shell:
   ${BLUE}chsh -s $(which fish)${NC}
2. Initialize zoxide for enhanced directory navigation:
   ${BLUE}zoxide init fish${NC}
3. Log out and back in for shell changes to take effect

EOL
