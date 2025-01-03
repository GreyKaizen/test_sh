#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the actual user's home directory (even when run with sudo)
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME="/home/$SUDO_USER"
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
fi

# Function to print colored messages
print_msg() {
    echo -e "${2}${1}${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to create directories if they don't exist
create_dirs() {
    local dirs=("$@")
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            # Ensure correct ownership if running with sudo
            if [ -n "$SUDO_USER" ]; then
                chown "$SUDO_USER:$SUDO_USER" "$dir"
            fi
            print_msg "Created directory: $dir" "$BLUE"
        fi
    done
}

# Function to handle yes/no prompts
prompt_user() {
    local message="$1"

    if [ "$AUTO_YES" = true ]; then
        return 0
    elif [ "$AUTO_NO" = true ]; then
        return 1
    fi

    while true; do
        read -rp "$(print_msg "$message [y/n]: " "$YELLOW")" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Parse command line arguments
AUTO_YES=false
AUTO_NO=false

while getopts "yn" opt; do
    case $opt in
        y) AUTO_YES=true ;;
        n) AUTO_NO=true ;;
        *) exit 1 ;;
    esac
done

# Check and install aria2
print_msg "Checking for aria2..." "$BLUE"
if ! command_exists aria2c; then
    print_msg "aria2 not found. Installing..." "$YELLOW"
    if command_exists dnf; then
        sudo dnf install -y aria2
    elif command_exists pacman; then
        sudo pacman -S --noconfirm aria2
    else
        print_msg "Unsupported distribution!" "$RED"
        exit 1
    fi
fi

# Create necessary directories
FONT_DIR="$REAL_HOME/.fonts"
CURSOR_DIR="$REAL_HOME/.icons"
DOWNLOAD_DIR="/tmp/downloads"
FONTS_DOWNLOAD_DIR="$DOWNLOAD_DIR/fonts"
CURSORS_DOWNLOAD_DIR="$DOWNLOAD_DIR/cursors"

print_msg "Creating directories..." "$BLUE"
print_msg "Font directory: $FONT_DIR" "$BLUE"
print_msg "Cursor directory: $CURSOR_DIR" "$BLUE"

create_dirs "$FONT_DIR" "$CURSOR_DIR" "$FONTS_DOWNLOAD_DIR" "$CURSORS_DOWNLOAD_DIR"

# Copy input files to download directories
cp fonts.txt "$FONTS_DOWNLOAD_DIR/"
cp cursors.txt "$CURSORS_DOWNLOAD_DIR/"

# Download files
if prompt_user "Do you want to download fonts and cursors?"; then
    print_msg "Downloading files..." "$BLUE"

    # Download fonts
    cd "$FONTS_DOWNLOAD_DIR" || exit
    aria2c -q --summary-interval=0 --console-log-level=warn \
          --max-concurrent-downloads=16 --continue=true \
          --auto-file-renaming=false -i fonts.txt

    # Download cursors
    cd "$CURSORS_DOWNLOAD_DIR" || exit
    aria2c -q --summary-interval=0 --console-log-level=warn \
          --max-concurrent-downloads=16 --continue=true \
          --auto-file-renaming=false -i cursors.txt
fi

# Extract and install fonts
if prompt_user "Do you want to install fonts?"; then
    print_msg "Installing fonts to: $FONT_DIR" "$BLUE"

    # Extract fonts to user's .fonts directory
    cd "$FONTS_DOWNLOAD_DIR" || exit
    for font in *.zip; do
        if [ -f "$font" ]; then
            # Get font name without .zip extension
            font_name="${font%.zip}"

            # Create specific directory for this font
            font_specific_dir="$FONT_DIR/$font_name"
            mkdir -p "$font_specific_dir"

            print_msg "Extracting $font to $font_specific_dir" "$BLUE"
            unzip -qq -o "$font" -d "$font_specific_dir"

            # Ensure correct ownership
            if [ -n "$SUDO_USER" ]; then
                chown -R "$SUDO_USER:$SUDO_USER" "$font_specific_dir"
            fi

            # Clean up unnecessary files in this specific font directory
            find "$font_specific_dir" -type f \( -name "README*" -o -name "readme*" \
                 -o -name "LICENSE*" -o -name "OFL*" -o -name "*.txt" -o -name "*.md" \) -delete
        fi
    done

    # Update font cache
    print_msg "Updating font cache..." "$BLUE"
    if [ -n "$SUDO_USER" ]; then
        su - "$SUDO_USER" -c "fc-cache -f"
    else
        fc-cache -f
    fi

    # Verify installation
    print_msg "Verifying font installation..." "$BLUE"
    ls -la "$FONT_DIR"
    print_msg "\nIndividual font directories:" "$BLUE"
    for dir in "$FONT_DIR"/*/ ; do
        if [ -d "$dir" ]; then
            print_msg "$(basename "$dir"):" "$YELLOW"
            ls -la "$dir"
        fi
    done
fi

# Extract and install cursors
if prompt_user "Do you want to install cursor themes?"; then
    print_msg "Installing cursor themes..." "$BLUE"
    cd "$CURSORS_DOWNLOAD_DIR" || exit
    for cursor in *.tar.xz; do
        if [ -f "$cursor" ]; then
            tar xf "$cursor"
            theme_name=$(tar tf "$cursor" | head -1 | cut -d/ -f1)
            if [ -n "$theme_name" ]; then
                sudo cp -r "$theme_name" "/usr/share/icons/"
                cp -r "$theme_name" "$CURSOR_DIR/"
                # Ensure correct ownership
                if [ -n "$SUDO_USER" ]; then
                    chown -R "$SUDO_USER:$SUDO_USER" "$CURSOR_DIR/$theme_name"
                fi
                print_msg "Installed cursor theme: $theme_name" "$BLUE"
            fi
        fi
    done
fi

# Cleanup
if prompt_user "Do you want to clean up downloaded files?"; then
    print_msg "Cleaning up..." "$BLUE"
    rm -rf "$DOWNLOAD_DIR"
fi

print_msg "Installation completed successfully!" "$GREEN"
print_msg "Fonts are installed in: $FONT_DIR" "$BLUE"
print_msg "Cursor themes are installed in: $CURSOR_DIR and /usr/share/icons/" "$BLUE"

# Final verification
print_msg "\nFinal verification:" "$YELLOW"
print_msg "Font directory contents:" "$BLUE"
ls -la "$FONT_DIR"
print_msg "\nCursor directory contents:" "$BLUE"
ls -la "$CURSOR_DIR"
