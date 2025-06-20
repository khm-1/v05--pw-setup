#!/bin/bash
# Enhanced Chrome Startup Script with Custom Configuration Support

set -e

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source "lib/utils.sh"
source "lib/chrome_manager.sh"

# Show banner
show_banner() {
    echo "🚀 Chrome Remote Debugging Startup"
    echo "=================================="
    echo ""
}

# Show available configurations
list_configurations() {
    echo "Available Configurations:"
    echo ""
    
    local configs=(
        "config/standard.conf:Standard:High quality 1920x1024x24"
        "config/optimized.conf:Optimized:CPU optimized 1280x720x16 (recommended)"
        "config/development.conf:Development:Development setup with debug features"
        "config/production.conf:Production:Secure production setup"
        "config/testing.conf:Testing:Minimal resources for testing"
    )
    
    for config_info in "${configs[@]}"; do
        IFS=':' read -r config_file config_name config_desc <<< "$config_info"
        if [[ -f "$config_file" ]]; then
            echo "  --$(echo "$config_name" | tr '[:upper:]' '[:lower:]')    $config_desc"
        fi
    done
    
    echo ""
    echo "Custom Options:"
    echo "  --port PORT              Chrome debugging port (default: 9222)"
    echo "  --address ADDRESS        Chrome debugging address (default: 0.0.0.0)"
    echo "  --display-size SIZE      Virtual display size (default: 1280x720x16)"
    echo "  --user-data-dir DIR      Chrome profile directory"
    echo "  --config FILE            Use custom configuration file"
    echo "  --auto-port              Automatically find available port"
    echo ""
    echo "Examples:"
    echo "  ./start.sh                                    # Use optimized defaults"
    echo "  ./start.sh --standard                         # High quality setup"
    echo "  ./start.sh --port 9223 --display-size 800x600x16"
    echo "  ./start.sh --config config/custom.conf --port 9224"
    echo ""
}

# Validate prerequisites
check_prerequisites() {
    # Check if Chrome is available
    if ! find_chrome_executable > /dev/null; then
        log_error "Chrome executable not found!"
        log_error "Please run './setup.sh' first to install Chrome"
        exit 1
    fi
    
    # Check if Xvfb is available
    if ! command_exists Xvfb; then
        log_error "Xvfb not found!"
        log_error "Please run './setup.sh' first to install Xvfb"
        exit 1
    fi
    
    # Check if configuration directory exists
    if [[ ! -d config ]]; then
        log_error "Configuration directory not found!"
        log_error "Please run './setup.sh' first to create configurations"
        exit 1
    fi
}

# Main startup function
start_chrome_with_config() {
    log_info "Starting Chrome with configuration..."
    
    # Show current configuration
    show_current_config
    echo ""
    
    # Start Xvfb virtual display
    if ! start_xvfb 99 "$DISPLAY_SIZE"; then
        log_error "Failed to start virtual display"
        exit 1
    fi
    
    # Start Chrome
    if ! start_chrome; then
        log_error "Failed to start Chrome"
        exit 1
    fi
    
    echo ""
    log_success "🎉 Chrome is ready for automation!"
    echo ""
    echo "Next steps:"
    echo "  Check status:    ./status.sh"
    echo "  Run automation:  ./run.sh scripts/basic_example.ts"
    echo "  Stop Chrome:     ./stop.sh"
    echo ""
    echo "Chrome debugging URL: http://localhost:$CHROME_PORT"
    if [[ "$CHROME_ADDRESS" == "0.0.0.0" ]]; then
        echo "External access:      http://$(hostname -I | awk '{print $1}'):$CHROME_PORT"
    fi
}

# Handle special arguments
handle_special_args() {
    case "${1:-}" in
        --help|-h)
            show_banner
            list_configurations
            exit 0
            ;;
        --list-configs)
            list_configurations
            exit 0
            ;;
        --validate-config)
            if [[ -z "$2" ]]; then
                log_error "Configuration file required for validation"
                exit 1
            fi
            load_config "$2"
            validate_config
            log_success "Configuration is valid"
            exit 0
            ;;
        --check-port)
            if [[ -z "$2" ]]; then
                log_error "Port number required"
                exit 1
            fi
            if is_port_available "$2"; then
                log_success "Port $2 is available"
            else
                log_error "Port $2 is in use"
                exit 1
            fi
            exit 0
            ;;
        --test-display-size)
            if [[ -z "$2" ]]; then
                log_error "Display size required"
                exit 1
            fi
            if validate_display_size "$2"; then
                log_success "Display size $2 is valid"
            else
                exit 1
            fi
            exit 0
            ;;
    esac
}

# Main function
main() {
    # Handle special arguments first
    handle_special_args "$@"
    
    show_banner
    check_prerequisites
    
    # Load default configuration
    if ! load_config "$DEFAULT_CONFIG"; then
        log_error "Failed to load default configuration"
        exit 1
    fi
    
    # Override with command line arguments
    if ! override_config "$@"; then
        case $? in
            2) exit 0 ;;  # Help was shown
            *) exit 1 ;;  # Error occurred
        esac
    fi
    
    # Validate final configuration
    if ! validate_config; then
        log_error "Configuration validation failed"
        exit 1
    fi
    
    # Check if Chrome is already running on this port
    if is_chrome_running "$CHROME_PORT"; then
        log_warning "Chrome is already running on port $CHROME_PORT"
        echo ""
        get_chrome_status "$CHROME_PORT"
        echo ""
        read -p "Stop existing Chrome and start new instance? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            stop_chrome "$CHROME_PORT"
            sleep 2
        else
            log_info "Keeping existing Chrome instance"
            exit 0
        fi
    fi
    
    # Start Chrome with configuration
    start_chrome_with_config
}

# Run main function
main "$@"
