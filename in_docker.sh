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

get_service_mode() {
    print_status "Docker service configuration:"
    echo "1) Enable and start"
    echo "2) Start only"
    echo "3) No service configuration"
    while true; do
        read -p "Select option [1-3]: " service_choice
        case $service_choice in
            1) echo "enable_start"; break ;;
            2) echo "start_only"; break ;;
            3) echo "none"; break ;;
            *) print_error "Invalid choice" ;;
        esac
    done
}

main() {
    get_confirmation_mode

    if confirm_action "adding Docker repository"; then
        print_status "Adding Docker repository..."
        dnf config-manager --add-repo=https://download.docker.com/linux/fedora/docker-ce.repo
    fi

    if confirm_action "installing Docker"; then
        print_status "Installing Docker packages..."
        if [ "$CONFIRM_ALL" = true ]; then
            dnf install -y docker-ce docker-ce-cli containerd.io
        else
            dnf install docker-ce docker-ce-cli containerd.io
        fi
    fi

    service_mode=$(get_service_mode)
    case $service_mode in
        "enable_start")
            systemctl enable --now docker
            ;;
        "start_only")
            systemctl start docker
            ;;
    esac

    if [ "$service_mode" != "none" ]; then
        print_status "Docker version:"
        docker --version
        
        if confirm_action "running hello-world test"; then
            docker run hello-world
        fi
    fi

    print_success "Docker setup completed"
}

main