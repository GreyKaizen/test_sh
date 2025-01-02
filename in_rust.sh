#!/bin/bash

# Colors
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

# Handle flags
while getopts "yn" opt; do
    case $opt in
        y) CONFIRM_ALL=true ;;
        n) CONFIRM_ALL=false ;;
        *) exit 1 ;;
    esac
done

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    exit 1
fi

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

    # Step 1: Install Rust
    if confirm_action "installing Rust using rustup"; then
        print_status "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        print_success "Rust installed successfully"
    fi

    # Step 2: Update PATH
    if confirm_action "updating system PATH for Rust"; then
        print_status "Updating PATH..."
        export PATH="$HOME/.cargo/bin:$PATH"
        if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc; then
            echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
        fi
        print_success "PATH updated successfully"
    fi

    # Step 3: Verify Rust Installation
    if confirm_action "verifying Rust installation"; then
        print_status "Verifying Rust installation..."
        rustc --version && cargo --version
        print_success "Rust verification completed"
    fi

    # Step 4: Update Rust
    if confirm_action "updating Rust to the latest version"; then
        print_status "Updating Rust..."
        rustup update
        print_success "Rust updated to the latest version"
    fi

    # Step 5: Add Components
    if confirm_action "adding rustfmt and clippy components"; then
        print_status "Adding rustfmt and clippy..."
        rustup component add rustfmt
        rustup component add clippy
        print_success "Components added successfully"
    fi

    # Step 6: Set Default to Stable
    if confirm_action "setting Rust default to stable"; then
        print_status "Setting Rust default to stable..."
        rustup default stable
        print_success "Rust default set to stable"
    fi

    # Step 7: Create and Run a Sample Project
    if confirm_action "creating and running a sample Rust project"; then
        print_status "Creating a sample Rust project..."
        cargo new hello_rust
        cd hello_rust || exit
        cargo run
        print_success "Sample Rust project created and executed successfully"
    fi

    print_success "Rust installation process completed"
}

main
