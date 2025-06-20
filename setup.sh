#!/bin/bash
# Enhanced Setup Script for Chrome Headless Automation
# Supports Google Chrome installation, Deno setup, and configuration

set -e

# Source utilities
source "lib/utils.sh"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Show banner
show_banner() {
    echo "🚀 Chrome Headless Automation Setup"
    echo "===================================="
    echo ""
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        log_error "Unsupported operating system"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_warning "This script is optimized for Ubuntu. Other distributions may work but are not tested."
    fi
    
    # Check Ubuntu version and warn about potential issues
    if [[ -n "$VERSION_ID" ]]; then
        local version_major=$(echo "$VERSION_ID" | cut -d. -f1)
        log_info "Detected Ubuntu $VERSION_ID"
        
        if [[ "$version_major" -ge 22 ]]; then
            log_info "Modern Ubuntu detected - using updated package management"
        elif [[ "$version_major" -ge 20 ]]; then
            log_info "Ubuntu 20.04+ detected - compatible"
        else
            log_warning "Older Ubuntu version detected. Some features may not work as expected."
        fi
    fi
    
    # Check internet connection
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "Internet connection required for installation"
        exit 1
    fi
    
    # Check if running as root (not recommended)
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root is not recommended. Consider using a regular user with sudo access."
    fi
    
    # Check available disk space (need at least 2GB)
    local available_space=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
    if [[ $available_space -lt 2 ]]; then
        log_warning "Low disk space detected (${available_space}GB available). At least 2GB recommended."
    fi
    
    log_success "System requirements check passed"
}

# Install system dependencies
install_system_dependencies() {
    log_info "Installing system dependencies..."
    
    # Update package list
    sudo apt update
    
    # Install basic dependencies
    sudo apt install -y curl gnupg wget software-properties-common apt-transport-https ca-certificates
    
    # Install Chrome dependencies
    sudo apt install -y libnspr4 libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 libxcomposite1 \
        libxdamage1 libxrandr2 libgbm1 libxss1 libasound2t64 libcups2t64 libgtk-3-0t64
    
    # Install Xvfb and display utilities
    sudo apt install -y xvfb x11-utils
    
    log_success "System dependencies installed"
}

# Install Node.js
install_nodejs() {
    if command_exists node && command_exists npm; then
        log_info "Node.js is already installed ($(node --version))"
        return 0
    fi
    
    log_info "Installing Node.js..."
    
    # Install Node.js LTS
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    
    # Verify installation
    if command_exists node && command_exists npm; then
        log_success "Node.js installed successfully ($(node --version))"
    else
        log_error "Node.js installation failed"
        exit 1
    fi
}

# Install Google Chrome
install_chrome() {
    if command_exists google-chrome || command_exists google-chrome-stable; then
        log_info "Google Chrome is already installed"
        return 0
    fi
    
    log_info "Installing Google Chrome..."
    
    # Try modern approach first (for Ubuntu 22.04+)
    if install_chrome_modern; then
        return 0
    fi
    
    # Fallback to direct .deb download if repository method fails
    log_warning "Repository method failed, trying direct download..."
    install_chrome_direct
}

# Modern Chrome installation (Ubuntu 22.04+)
install_chrome_modern() {
    log_info "Using modern repository method..."
    
    # Download and install the signing key
    if ! wget -q -O /tmp/google-chrome-key.pub https://dl.google.com/linux/linux_signing_key.pub; then
        log_error "Failed to download Chrome signing key"
        return 1
    fi
    
    # Add the key to the trusted keyring
    if ! sudo gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg /tmp/google-chrome-key.pub 2>/dev/null; then
        log_error "Failed to add Chrome signing key"
        rm -f /tmp/google-chrome-key.pub
        return 1
    fi
    
    # Add the repository with the keyring reference
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
    
    # Clean up temporary key file
    rm -f /tmp/google-chrome-key.pub
    
    # Update and install Chrome
    if sudo apt update && sudo apt install -y google-chrome-stable; then
        log_success "Google Chrome installed successfully via repository"
        return 0
    else
        log_error "Repository installation failed"
        return 1
    fi
}

# Direct Chrome installation (fallback method)
install_chrome_direct() {
    log_info "Using direct download method..."
    
    # Download Chrome .deb package directly
    local chrome_deb="/tmp/google-chrome-stable.deb"
    
    if ! wget -q -O "$chrome_deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; then
        log_error "Failed to download Chrome package"
        return 1
    fi
    
    # Install the package
    if sudo dpkg -i "$chrome_deb" 2>/dev/null; then
        log_success "Chrome package installed"
    else
        log_warning "Chrome package installation had dependency issues, fixing..."
        # Fix dependencies
        sudo apt-get install -f -y
    fi
    
    # Clean up
    rm -f "$chrome_deb"
    
    # Verify installation
    if command_exists google-chrome-stable; then
        log_success "Google Chrome installed successfully via direct download"
        return 0
    else
        log_error "Chrome installation failed"
        return 1
    fi
}

# Install Playwright (fallback)
install_playwright() {
    log_info "Installing Playwright as fallback..."
    
    # Initialize npm project if needed
    if [[ ! -f package.json ]]; then
        npm init -y > /dev/null
    fi
    
    # Install Playwright
    npm install playwright
    npx playwright install chromium
    
    log_success "Playwright installed successfully"
}

# Install Deno
install_deno() {
    if command_exists deno; then
        log_info "Deno is already installed ($(deno --version | head -1))"
        return 0
    fi
    
    log_info "Installing Deno..."
    
    # Install Deno
    curl -fsSL https://deno.land/install.sh | sh -s -- -y
    
    # Add to PATH
    export PATH="$HOME/.deno/bin:$PATH"
    echo 'export PATH="$HOME/.deno/bin:$PATH"' >> ~/.bashrc
    
    # Verify installation
    if command_exists deno; then
        log_success "Deno installed successfully ($(deno --version | head -1))"
    else
        log_error "Deno installation failed"
        exit 1
    fi
}

# Setup configuration files
setup_configurations() {
    log_info "Setting up configuration files..."
    
    # Ensure config directory exists
    mkdir -p config
    
    # Check if configurations exist
    local configs=("standard.conf" "optimized.conf" "development.conf" "production.conf" "testing.conf")
    local missing_configs=()
    
    for config in "${configs[@]}"; do
        if [[ ! -f "config/$config" ]]; then
            missing_configs+=("$config")
        fi
    done
    
    if [[ ${#missing_configs[@]} -gt 0 ]]; then
        log_warning "Some configuration files are missing: ${missing_configs[*]}"
        log_info "Please ensure all configuration files are present in the config/ directory"
    else
        log_success "All configuration files are present"
    fi
}

# Create example scripts
create_example_scripts() {
    log_info "Creating example scripts..."
    
    # Ensure scripts directory exists
    mkdir -p scripts examples
    
    # Move existing deno_script.ts to scripts if it exists
    if [[ -f deno_script.ts ]]; then
        mv deno_script.ts scripts/basic_example.ts
        log_info "Moved existing deno_script.ts to scripts/basic_example.ts"
    fi
    
    log_success "Example scripts directory created"
}

# Validate installation
validate_installation() {
    log_info "Validating installation..."
    
    local errors=0
    
    # Check Chrome
    if ! command_exists google-chrome-stable && ! command_exists google-chrome && ! find "$HOME/.cache/ms-playwright" -name "chrome" -type f -executable 2>/dev/null | head -1 > /dev/null; then
        log_error "Chrome installation not found"
        ((errors++))
    fi
    
    # Check Deno
    if ! command_exists deno; then
        log_error "Deno installation not found"
        ((errors++))
    fi
    
    # Check Xvfb
    if ! command_exists Xvfb; then
        log_error "Xvfb installation not found"
        ((errors++))
    fi
    
    # Check configurations
    if [[ ! -f config/optimized.conf ]]; then
        log_error "Default configuration not found"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "Installation validation passed"
        return 0
    else
        log_error "Installation validation failed with $errors errors"
        return 1
    fi
}

# Show completion message
show_completion() {
    echo ""
    log_success "🎉 Setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Start Chrome:    ./start.sh"
    echo "2. Run automation:  ./run.sh scripts/basic_example.ts"
    echo "3. Check status:    ./status.sh"
    echo "4. Stop Chrome:     ./stop.sh"
    echo ""
    echo "Configuration options:"
    echo "  ./start.sh --optimized     # CPU-optimized (recommended)"
    echo "  ./start.sh --standard      # High quality"
    echo "  ./start.sh --development   # Development setup"
    echo ""
    echo "For help: ./start.sh --help"
    echo ""
    check_system_resources
}

# Handle command line arguments
handle_arguments() {
    case "${1:-}" in
        --help|-h)
            show_banner
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --help, -h           Show this help message"
            echo "  --configure          Run configuration wizard"
            echo "  --repair             Repair installation"
            echo "  --check              Check installation status"
            echo "  --fix-chrome         Fix Chrome installation issues"
            echo "  --clean              Clean up temporary files and caches"
            echo ""
            echo "Troubleshooting:"
            echo "  If you encounter 'apt-key: command not found':"
            echo "    ./setup.sh --fix-chrome"
            echo ""
            echo "  If installation fails:"
            echo "    ./setup.sh --clean && ./setup.sh --repair"
            echo ""
            exit 0
            ;;
        --configure)
            log_info "Configuration wizard not yet implemented"
            exit 0
            ;;
        --repair)
            log_info "Running repair installation..."
            # Re-run key installation steps
            install_system_dependencies
            install_chrome
            install_deno
            validate_installation
            exit 0
            ;;
        --check)
            validate_installation
            exit $?
            ;;
        --fix-chrome)
            log_info "Fixing Chrome installation..."
            # Remove any problematic Chrome repository files
            sudo rm -f /etc/apt/sources.list.d/google-chrome.list
            sudo rm -f /usr/share/keyrings/google-chrome-keyring.gpg
            # Try to install Chrome again
            install_chrome
            exit $?
            ;;
        --clean)
            log_info "Cleaning up temporary files and caches..."
            # Clean up temporary files
            rm -f /tmp/google-chrome-*.deb /tmp/google-chrome-key.pub
            # Clean npm cache if it exists
            if command_exists npm; then
                npm cache clean --force 2>/dev/null || true
            fi
            # Clean apt cache
            sudo apt clean
            log_success "Cleanup completed"
            exit 0
            ;;
        "")
            # Default setup
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Main setup function
main() {
    handle_arguments "$@"
    
    show_banner
    check_requirements
    install_system_dependencies
    install_nodejs
    install_chrome
    install_playwright
    install_deno
    setup_configurations
    create_example_scripts
    
    if validate_installation; then
        show_completion
    else
        log_error "Setup completed with errors. Run './setup.sh --repair' to fix issues."
        exit 1
    fi
}

# Run main function
main "$@"
