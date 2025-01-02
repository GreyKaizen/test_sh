#!/bin/bash

# Define colors for UI
NC='\033[0m'  # No color
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'

# Path to dnf.conf file
DNF_CONF="/etc/dnf/dnf.conf"

# Check if script is run with sudo privileges
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root!${NC}"
    exit 1
fi

# Backup current dnf.conf
echo -e "${YELLOW}Backing up current /etc/dnf/dnf.conf...${NC}"
cp $DNF_CONF "$DNF_CONF.bak"

# Update dnf.conf file with correct format
echo -e "${YELLOW}Setting up /etc/dnf/dnf.conf...${NC}"

{
  echo "# Custom DNF configuration"
  echo "[main]"
  echo "gpgcheck=True"
  echo "installonly_limit=2"
  echo "clean_requirements_on_remove=True"
  echo "best=False"
  echo "skip_if_unavailable=True"
  echo "max_parallel_downloads=10"
  echo "fastestmirror=True"
} | sudo tee -a $DNF_CONF > /dev/null

# Array of packages to be installed
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
