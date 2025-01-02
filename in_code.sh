#!/bin/bash

# Color setup
if [ -t 1 ]; then
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    NC=$(printf '\033[0m')
fi

print_status() { printf "${BLUE}[*]${NC} %s\n" "$1"; }
print_success() { printf "${GREEN}[+]${NC} %s\n" "$1"; }
print_error() { printf "${RED}[-]${NC} %s\n" "$1"; }
print_warning() { printf "${YELLOW}[!]${NC} %s\n" "$1"; }

# Process flags
while getopts "yn" opt; do
    case $opt in
        y) CONFIRM_ALL=true ;;
        n) CONFIRM_ALL=false ;;
        *) exit 1 ;;
    esac
done

# Root check
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    exit 1
fi

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

confirm_action() {
    if [ "$CONFIRM_ALL" = true ]; then
        return 0
    fi
    read -p "Proceed with $1? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

main() {
    get_confirmation_mode

    if confirm_action "importing Microsoft GPG key"; then
        print_status "Importing Microsoft GPG key..."
        rpm --import https://packages.microsoft.com/keys/microsoft.asc
    fi

    if confirm_action "adding VS Code repository"; then
        print_status "Adding VS Code repository..."
        cat > /etc/yum.repos.d/vscode.repo << EOL
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOL
    fi

    if confirm_action "updating package list"; then
        print_status "Updating package list..."
        dnf check-update
    fi

    if confirm_action "installing VS Code"; then
        print_status "Installing VS Code..."
        if [ "$CONFIRM_ALL" = true ]; then
            dnf install -y code
        else
            dnf install code
        fi
    fi

    print_success "VS Code setup completed"
}

main