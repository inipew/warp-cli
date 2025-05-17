#!/bin/bash
# Originally by MmD, refactored for better reliability

# ---------------- COLOR DEFINITIONS ----------------
readonly GREEN=$(tput setaf 2)
readonly RED=$(tput setaf 1)
readonly BLUE=$(tput setaf 4)
readonly GOLD=$(tput setaf 3)
readonly CYAN=$(tput setaf 6)
readonly NC=$(tput sgr0) # No Color

# ---------------- FUNCTIONS ----------------

# Print formatted messages
print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_warning() {
    echo -e "${GOLD}[WARNING]${NC} $1"
}

# Check if script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "This script must be run as root!"
        exit 1
    fi
    print_info "Running with root privileges"
}

# Detect package manager and install dependencies
detect_package_manager() {
    if command -v apt &> /dev/null; then
        print_info "Detected APT-based system"
        install_apt_based
    elif command -v yum &> /dev/null; then
        print_info "Detected YUM-based system"
        install_yum_based
    else
        print_error "Unsupported package manager! Only APT and YUM are supported."
        exit 1
    fi
}

# Install on Debian/Ubuntu based systems
install_apt_based() {
    print_info "Updating package lists..."
    if ! apt update; then
        print_error "Failed to update package lists"
        exit 1
    fi
    
    print_info "Installing dependencies..."
    if ! apt install -y curl gpg lsb-release apt-transport-https ca-certificates sudo; then
        print_error "Failed to install dependencies"
        exit 1
    fi
    
    print_info "Adding Cloudflare repository key..."
    if ! curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg; then
        print_error "Failed to download and add repository key"
        exit 1
    fi
    
    print_info "Adding Cloudflare repository..."
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
    
    print_info "Updating package lists with new repository..."
    if ! apt update; then
        print_error "Failed to update package lists with new repository"
        exit 1
    fi
    
    print_info "Installing Cloudflare WARP..."
    if ! apt install -y cloudflare-warp; then
        print_error "Failed to install Cloudflare WARP"
        exit 1
    fi
    
    print_success "Cloudflare WARP installed successfully"
}

# Install on RHEL/CentOS/Fedora based systems
install_yum_based() {
    print_info "Adding Cloudflare repository..."
    if ! curl -fsSL https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | tee /etc/yum.repos.d/cloudflare-warp.repo; then
        print_error "Failed to add Cloudflare repository"
        exit 1
    fi
    
    print_info "Updating package lists..."
    if ! yum check-update; then
        print_warning "yum check-update returned non-zero exit code, but this might be normal"
    fi
    
    print_info "Installing dependencies..."
    if ! yum install -y curl sudo coreutils; then
        print_error "Failed to install dependencies"
        exit 1
    fi
    
    print_info "Installing Cloudflare WARP..."
    if ! yum install -y cloudflare-warp; then
        print_error "Failed to install Cloudflare WARP"
        exit 1
    fi
    
    print_success "Cloudflare WARP installed successfully"
}

# Configure WARP client
setup_warp() {
    print_info "Checking if WARP client is installed..."
    if ! command -v warp-cli &> /dev/null; then
        print_error "WARP client not found! Installation might have failed."
        exit 1
    fi
    
    print_info "Registering WARP client..."
    if ! yes | warp-cli registration new; then
        print_error "Failed to register WARP client"
        exit 1
    fi
    
    print_info "Setting WARP to proxy mode..."
    if ! warp-cli mode proxy; then
        print_error "Failed to set WARP to proxy mode"
        exit 1
    fi
    
    print_info "Setting proxy port to 10808..."
    if ! warp-cli proxy port 10808; then
        print_error "Failed to set proxy port"
        exit 1
    fi
    
    print_info "Connecting to WARP..."
    if ! warp-cli connect; then
        print_error "Failed to connect to WARP"
        exit 1
    fi
    
    print_success "WARP setup completed successfully!"
    echo ""
    echo -e "${CYAN}WARP is ready! ${GOLD}SOCKS5 proxy available at: localhost:10808${NC}"
    echo ""
}

# Check WARP status
check_warp_status() {
    if warp-cli status | grep -q "Connected"; then
        print_success "WARP is connected and running"
        echo -e "${BLUE}Current WARP status:${NC}"
        warp-cli status
        echo ""
        echo -e "${CYAN}SOCKS5 proxy available at: ${GOLD}localhost:10808${NC}"
    else
        print_warning "WARP is installed but not connected"
        echo -e "${BLUE}Current WARP status:${NC}"
        warp-cli status
        echo ""
        print_info "To connect, run: warp-cli connect"
    fi
}

# Main function to orchestrate the installation
main() {
    # Clear screen for better readability
    clear
    
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${CYAN}   Cloudflare WARP Installer (Improved)  ${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
    
    # Check if running as root
    check_root
    
    # Check if WARP is already installed
    if command -v warp-cli &> /dev/null; then
        print_info "Cloudflare WARP is already installed"
        check_warp_status
    else
        print_info "Installing Cloudflare WARP..."
        detect_package_manager
        setup_warp
    fi
    
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${GREEN}Installation process completed${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

# Execute main function
main
exit 0