#!/bin/bash

# Colors and spinner setup remain the same
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

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

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Get confirmation mode
get_confirmation_mode() {
    while true; do
        print_status "How would you like to handle confirmations?"
        echo "1) Yes to all prompts (automatic)"
        echo "2) Ask for each operation"
        read -p "Enter choice [1/2]: " choice
        case $choice in
            1) CONFIRM_ALL=true; break;;
            2) CONFIRM_ALL=false; break;;
            *) print_error "Invalid choice";;
        esac
    done
}

# Confirmation function
confirm_action() {
    if [ "$CONFIRM_ALL" = true ]; then
        return 0
    fi
    read -p "Proceed with $1? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Root check
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    exit 1
fi

get_confirmation_mode

# DNF Configuration
if confirm_action "DNF configuration update"; then
    print_status "Configuring DNF..."
    DNF_CONF="/etc/dnf/dnf.conf"

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

    [ $? -eq 0 ] && print_success "DNF configuration updated" || { print_error "DNF configuration failed"; exit 1; }
fi

# System update
if confirm_action "system update"; then
    print_status "Updating system..."
    if [ "$CONFIRM_ALL" = true ]; then
        dnf update -y
    else
        dnf update
    fi
    [ $? -eq 0 ] && print_success "System updated" || print_warning "System update had issues"
fi

# Package installation
packages=(
    gcc gcc-c++ jq java-21-openjdk-headless podman git
    zoxide fzf bat fish tmux aria2 fastfetch alacritty
    distrobox gnome-boxes vlc libreoffice okular
    qalculate-qt qbittorrent kile kate kwrite gwenview
    mediawriter
)

if confirm_action "package installation"; then
    print_status "Installing packages..."
    if [ "$CONFIRM_ALL" = true ]; then
        dnf install -y "${packages[@]}" & show_spinner $!
    else
        dnf install "${packages[@]}"
    fi
    [ $? -eq 0 ] && print_success "Packages installed" || print_error "Some packages failed"
fi

print_success "Setup completed"

cat << EOL

${GREEN}=== Next Steps ===${NC}
1. Set fish as default shell: ${BLUE}chsh -s $(which fish)${NC}
2. Initialize zoxide: ${BLUE}zoxide init fish${NC}
3. Log out and back in
EOL
