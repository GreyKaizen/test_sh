#!/bin/bash

# Colors
if [ -t 1 ]; then
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    CYAN=$(printf '\033[36m')
    NC=$(printf '\033[0m')
fi

# Utils
print_status() { printf "${BLUE}[*]${NC} %s\n" "$1"; }
print_success() { printf "${GREEN}[+]${NC} %s\n" "$1"; }
print_error() { printf "${RED}[-]${NC} %s\n" "$1"; }
print_warning() { printf "${YELLOW}[!]${NC} %s\n" "$1"; }

# Process command line arguments
while getopts "yn" opt; do
    case $opt in
        y) CONFIRM_ALL=true ;;
        n) CONFIRM_ALL=false ;;
        *) exit 1 ;;
    esac
done

# Check distribution
check_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $ID in
            fedora|arch)
                print_success "Detected $NAME"
                return 0
                ;;
            *)
                print_error "Unsupported distribution: $NAME"
                return 1
                ;;
        esac
    else
        print_error "Cannot determine distribution"
        return 1
    fi
}

# Get confirmation mode if not set via flags
get_confirmation_mode() {
    if [ -z "$CONFIRM_ALL" ]; then
        while true; do
            print_status "How would you like to handle confirmations?"
            echo "1) Yes to all prompts (automatic)"
            echo "2) Ask for each operation"
            read -p "Enter choice [1/2]: " choice
            case $choice in
                1) CONFIRM_ALL=true; break ;;
                2) CONFIRM_ALL=false; break ;;
                *) print_error "Invalid choice" ;;
            esac
        done
    fi
}

# Confirm action
confirm_action() {
    if [ "$CONFIRM_ALL" = true ]; then
        return 0
    fi
    read -p "Proceed with $1? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check and install flatpak
setup_flatpak() {
    if ! command -v flatpak >/dev/null 2>&1; then
        print_warning "Flatpak not found. Installing..."
        if [ "$ID" = "fedora" ]; then
            if [ "$CONFIRM_ALL" = true ]; then
                dnf install -y flatpak
            else
                dnf install flatpak
            fi
        elif [ "$ID" = "arch" ]; then
            if [ "$CONFIRM_ALL" = true ]; then
                pacman -S --noconfirm flatpak
            else
                pacman -S flatpak
            fi
        fi
    fi

    # Add Flathub repository
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

# Flatpak packages
packages=(
    "com.brave.Browser"
    "io.github.zen_browser.zen"
    "io.github.dvlv.boxbuddyrs"
    "org.jousse.vincent.Pomodorolm"
    "org.telegram.desktop"
    "com.github.tchx84.Flatseal"
)

# Main
main() {
    check_distro || exit 1
    get_confirmation_mode

    if confirm_action "flatpak setup"; then
        setup_flatpak
    fi

    print_status "Installing Flatpak packages..."
    if confirm_action "installing all packages"; then
        echo "Adding Flathub"
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        if [ "$CONFIRM_ALL" = true ]; then
            flatpak install -y flathub "${packages[@]}"
        else
            flatpak install flathub "${packages[@]}"
        fi
    fi

    print_success "Installation completed"
}

main
