#!/bin/bash

# Define colors for UI
NC='\033[0m'  # No color
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'

# Path to dnf.conf file
DNF_CONF="/etc/dnf/dnf.conf"

# Backup current dnf.conf
echo -e "${YELLOW}Backing up current /etc/dnf/dnf.conf...${NC}"
cp $DNF_CONF "$DNF_CONF.bak"

# Update dnf.conf file
echo -e "${YELLOW}Setting up /etc/dnf/dnf.conf...${NC}"
cat <<EOL >> $DNF_CONF
# see `man dnf.conf` for defaults and possible options

[main]
gpgcheck=True
installonly_limit=2
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
fastestmirror=true
EOL

# Array of packages
packages=(
    "gcc"
    "gcc-c++"
    "jq"
    "java-21-openjdk-headless"
    "podman"
    "git"
    "zoxide"
    "fzf"
    "bat"
    "fish"
    "tmux"
    "aria2"
    "fastfetch"
    "alacritty"
    "distrobox"
    "gnome-boxes"
    "vlc"
    "libreoffice"
    "okular"
    "qalculate-qt"
    "qbittorrent"
    "kile"
    "kate"
    "kwrite"
    "gwenview"
    "fedora-media-writer"
)

# Prompt before starting the download
echo -e "${GREEN}Preparing to install packages...${NC}"
echo -e "${YELLOW}The following packages will be installed: ${NC}"
for pkg in "${packages[@]}"; do
    echo -e "${GREEN}- $pkg${NC}"
done
read -p "Proceed with installation? (y/n): " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation aborted by user.${NC}"
    exit 1
fi

# Install packages
echo -e "${YELLOW}Installing packages...${NC}"
sudo dnf install -y "${packages[@]}"

echo -e "${GREEN}Installation complete!${NC}"
