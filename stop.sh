#!/bin/bash
# Enhanced Chrome Stop Script with Multi-Instance Support

set -e

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source "lib/utils.sh"
source "lib/chrome_manager.sh"

# Show banner
show_banner() {
    echo "⏹️  Chrome Remote Debugging Stop"
    echo "==============================="
    echo ""
}

# Stop all Chrome instances
stop_all_chrome() {
    log_info "Stopping all Chrome instances..."
    
    local stopped=false
    
    # Check common ports
    for port in {9222..9230}; do
        if is_chrome_running "$port"; then
            stop_chrome "$port"
            stopped=true
        fi
    done
    
    # Force kill any remaining Chrome processes
    if pgrep -f "remote-debugging-port" > /dev/null; then
        log_warning "Force stopping remaining Chrome processes..."
        pkill -f "remote-debugging-port" || true
        sleep 2
    fi
    
    # Stop Xvfb
    if pgrep -f "Xvfb :99" > /dev/null; then
        log_info "Stopping Xvfb virtual display..."
        pkill -f "Xvfb :99" || true
        sudo rm -f /tmp/.X99-lock || true
    fi
    
    # Clean up PID files
    rm -f chrome-*.pid
    
    if [[ "$stopped" == true ]]; then
        log_success "All Chrome instances stopped"
    else
        log_info "No Chrome instances were running"
    fi
}

# Stop Chrome by user data directory
stop_chrome_by_profile() {
    local user_data_dir=$1
    
    log_info "Stopping Chrome instances using profile: $user_data_dir"
    
    # Find Chrome processes using this profile
    local pids=$(pgrep -f "user-data-dir=$user_data_dir" || true)
    
    if [[ -n "$pids" ]]; then
        for pid in $pids; do
            log_info "Stopping Chrome process $pid"
            kill_process_with_timeout "$pid" 10
        done
        log_success "Chrome instances using profile $user_data_dir stopped"
    else
        log_info "No Chrome instances found using profile: $user_data_dir"
    fi
}

# Force cleanup
force_cleanup() {
    log_warning "Performing force cleanup..."
    
    # Kill all Chrome processes
    pkill -f chrome || true
    pkill -f chromium || true
    
    # Kill Xvfb
    pkill -f Xvfb || true
    
    # Remove lock files
    sudo rm -f /tmp/.X*-lock || true
    
    # Clean up PID files
    rm -f chrome-*.pid
    
    # Clean up temporary profiles
    rm -rf /tmp/chrome-*-profile || true
    
    log_success "Force cleanup completed"
}

# Show help
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h               Show this help message"
    echo "  --port PORT              Stop Chrome on specific port"
    echo "  --all                    Stop all Chrome instances (default)"
    echo "  --user-data-dir DIR      Stop Chrome using specific profile"
    echo "  --force                  Force stop all processes and cleanup"
    echo "  --list                   List running Chrome instances"
    echo ""
    echo "Examples:"
    echo "  ./stop.sh                        # Stop all Chrome instances"
    echo "  ./stop.sh --port 9223            # Stop Chrome on port 9223"
    echo "  ./stop.sh --user-data-dir /tmp/chrome-test"
    echo "  ./stop.sh --force                # Force cleanup everything"
    echo ""
}

# List running instances
list_running_instances() {
    echo "Running Chrome Instances:"
    echo "========================="
    list_chrome_instances
}

# Main function
main() {
    local port=""
    local user_data_dir=""
    local force_mode=false
    local list_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_banner
                show_help
                exit 0
                ;;
            --port)
                port="$2"
                shift 2
                ;;
            --user-data-dir)
                user_data_dir="$2"
                shift 2
                ;;
            --all)
                # Default behavior, no action needed
                shift
                ;;
            --force)
                force_mode=true
                shift
                ;;
            --list)
                list_only=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    show_banner
    
    # Handle list option
    if [[ "$list_only" == true ]]; then
        list_running_instances
        exit 0
    fi
    
    # Handle force cleanup
    if [[ "$force_mode" == true ]]; then
        force_cleanup
        exit 0
    fi
    
    # Handle specific port
    if [[ -n "$port" ]]; then
        if ! validate_port "$port"; then
            exit 1
        fi
        
        if is_chrome_running "$port"; then
            stop_chrome "$port"
        else
            log_info "No Chrome instance running on port $port"
        fi
        exit 0
    fi
    
    # Handle specific user data directory
    if [[ -n "$user_data_dir" ]]; then
        stop_chrome_by_profile "$user_data_dir"
        exit 0
    fi
    
    # Default: stop all Chrome instances
    stop_all_chrome
}

# Run main function
main "$@"
