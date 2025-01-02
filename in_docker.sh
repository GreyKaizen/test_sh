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

while getopts "yn" opt; do
    case $opt in
        y) CONFIRM_ALL=true ;;
        n) CONFIRM_ALL=false ;;
        *) exit 1 ;;
    esac
done

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
    print_status "[+] "
    while true; do
        printf "%s" "" && read -p "
        Docker service configuration:
        1) Enable and start
        2) Start only
        3) No service configuration
        Select option [1-3]: " service_choice
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

    if confirm_action "installing DNF plugins core"; then
        print_status "Installing DNF plugins core..."
        if [ "$CONFIRM_ALL" = true ]; then
            dnf install -y dnf-plugins-core
        else
            dnf install dnf-plugins-core
        fi
    fi

    if confirm_action "creating Docker repository file"; then
        print_status "Creating Docker repository file..."
        cat > /etc/yum.repos.d/docker-ce.repo << EOL
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOL
    fi

    if confirm_action "installing Docker packages"; then
        print_status "Installing Docker packages..."
        if [ "$CONFIRM_ALL" = true ]; then
            dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        else
            dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        fi
    fi

    service_mode=$(get_service_mode)
    case $service_mode in
        "enable_start")
            sudo systemctl enable --now docker
            ;;
        "start_only")
            sudo systemctl start docker
            ;;
    esac

    if [ "$service_mode" != "none" ]; then
        print_status "Docker version:"
        docker --version
        print_status "running hello-world test"
        docker run hello-world
    fi

    print_success "Docker setup completed"
}

main
