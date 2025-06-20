#!/bin/bash
# Chrome management functions

# Source utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Default configuration
DEFAULT_CONFIG="config/optimized.conf"

# Configuration variables
DISPLAY_SIZE=""
CHROME_PORT=""
CHROME_ADDRESS=""
USER_DATA_DIR=""
WINDOW_SIZE=""
CHROME_FLAGS=""
CONFIG_NAME=""
CONFIG_DESCRIPTION=""

# Load configuration from file
load_config() {
    local config_file=$1
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Source the configuration file
    source "$config_file"
    
    # Validate required variables
    if [[ -z "$DISPLAY_SIZE" ]] || [[ -z "$CHROME_PORT" ]] || [[ -z "$CHROME_ADDRESS" ]]; then
        log_error "Invalid configuration file: missing required variables"
        return 1
    fi
    
    # Set window size if not specified
    if [[ -z "$WINDOW_SIZE" ]]; then
        WINDOW_SIZE=$(get_window_size "$DISPLAY_SIZE")
    fi
    
    # Set default user data dir if not specified
    if [[ -z "$USER_DATA_DIR" ]]; then
        USER_DATA_DIR="/tmp/chrome-profile-$CHROME_PORT"
    fi
    
    log_success "Loaded configuration: $config_file"
    if [[ -n "$CONFIG_NAME" ]]; then
        log_info "Configuration: $CONFIG_NAME - $CONFIG_DESCRIPTION"
    fi
    
    return 0
}

# Override configuration with command line arguments
override_config() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port)
                CHROME_PORT="$2"
                shift 2
                ;;
            --address)
                CHROME_ADDRESS="$2"
                shift 2
                ;;
            --display-size)
                DISPLAY_SIZE="$2"
                WINDOW_SIZE=$(get_window_size "$2")
                shift 2
                ;;
            --user-data-dir)
                USER_DATA_DIR="$2"
                shift 2
                ;;
            --config)
                load_config "$2" || return 1
                shift 2
                ;;
            --standard)
                load_config "config/standard.conf" || return 1
                shift
                ;;
            --optimized)
                load_config "config/optimized.conf" || return 1
                shift
                ;;
            --development)
                load_config "config/development.conf" || return 1
                shift
                ;;
            --production)
                load_config "config/production.conf" || return 1
                shift
                ;;
            --testing)
                load_config "config/testing.conf" || return 1
                shift
                ;;
            --auto-port)
                CHROME_PORT=$(find_available_port ${CHROME_PORT:-9222})
                if [[ -z "$CHROME_PORT" ]]; then
                    log_error "No available ports found"
                    return 1
                fi
                log_info "Using auto-detected port: $CHROME_PORT"
                shift
                ;;
            --help)
                show_config_help
                return 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_config_help
                return 1
                ;;
        esac
    done
    return 0
}

# Validate configuration
validate_config() {
    local errors=0
    
    # Validate port
    if ! validate_port "$CHROME_PORT"; then
        ((errors++))
    fi
    
    # Check if port is available
    if ! is_port_available "$CHROME_PORT"; then
        log_error "Port $CHROME_PORT is already in use"
        ((errors++))
    fi
    
    # Validate display size
    if ! validate_display_size "$DISPLAY_SIZE"; then
        ((errors++))
    fi
    
    # Validate address
    if ! validate_address "$CHROME_ADDRESS"; then
        ((errors++))
    fi
    
    # Validate user data directory
    if ! ensure_directory "$(dirname "$USER_DATA_DIR")"; then
        ((errors++))
    fi
    
    return $errors
}

# Find Chrome executable
find_chrome_executable() {
    local chrome_paths=(
        "/usr/bin/google-chrome"
        "/usr/bin/google-chrome-stable"
        "$HOME/.cache/ms-playwright/chromium-*/chrome-linux/chrome"
        "/usr/bin/chromium"
        "/usr/bin/chromium-browser"
    )
    
    for path in "${chrome_paths[@]}"; do
        if [[ "$path" == *"*"* ]]; then
            # Handle wildcard paths
            local expanded_path=$(ls $path 2>/dev/null | head -1)
            if [[ -x "$expanded_path" ]]; then
                echo "$expanded_path"
                return 0
            fi
        elif [[ -x "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Start Xvfb virtual display
start_xvfb() {
    local display_num=${1:-99}
    local display_size=$2
    
    # Kill existing Xvfb on this display
    pkill -f "Xvfb :$display_num" 2>/dev/null || true
    sleep 2
    
    # Remove lock file
    sudo rm -f "/tmp/.X$display_num-lock" 2>/dev/null || true
    
    log_progress "Starting Xvfb virtual display :$display_num with $display_size"
    
    # Start Xvfb
    Xvfb ":$display_num" -screen 0 "$display_size" -ac +extension GLX +render -noreset &
    local xvfb_pid=$!
    
    # Set display environment variable
    export DISPLAY=":$display_num"
    
    # Wait for Xvfb to start
    sleep 3
    
    # Verify Xvfb is running
    if ! pgrep -f "Xvfb :$display_num" > /dev/null; then
        log_error "Failed to start Xvfb"
        return 1
    fi
    
    log_success "Xvfb started successfully on display :$display_num"
    return 0
}

# Start Chrome with configuration
start_chrome() {
    local chrome_path=$(find_chrome_executable)
    
    if [[ -z "$chrome_path" ]]; then
        log_error "Chrome executable not found!"
        log_error "Please install Google Chrome or Chromium"
        return 1
    fi
    
    log_info "Using Chrome executable: $chrome_path"
    log_progress "Starting Chrome with remote debugging on port $CHROME_PORT"
    
    # Ensure user data directory exists
    ensure_directory "$USER_DATA_DIR" || return 1
    
    # Build Chrome arguments
    local chrome_args=(
        --headless=new
        --remote-debugging-port="$CHROME_PORT"
        --remote-debugging-address="$CHROME_ADDRESS"
        --disable-gpu
        --no-sandbox
        --disable-dev-shm-usage
        --window-size="$WINDOW_SIZE"
        --user-data-dir="$USER_DATA_DIR"
        --no-first-run
        --no-default-browser-check
    )
    
    # Add custom Chrome flags
    if [[ -n "$CHROME_FLAGS" ]]; then
        IFS=' ' read -ra ADDR <<< "$CHROME_FLAGS"
        chrome_args+=("${ADDR[@]}")
    fi
    
    # Start Chrome in background
    "$chrome_path" "${chrome_args[@]}" &> "chrome-$CHROME_PORT.log" &
    local chrome_pid=$!
    
    # Save PID
    echo "$chrome_pid" > "chrome-$CHROME_PORT.pid"
    
    log_info "Chrome started with PID: $chrome_pid"
    
    # Wait for Chrome to be ready
    if wait_for_chrome "$CHROME_PORT" 30; then
        log_success "Chrome is ready for connections"
        log_info "Remote debugging available at: http://localhost:$CHROME_PORT"
        return 0
    else
        log_error "Chrome failed to start properly"
        return 1
    fi
}

# Stop Chrome by port
stop_chrome() {
    local port=${1:-$CHROME_PORT}
    
    log_progress "Stopping Chrome on port $port"
    
    # Get Chrome PID
    local chrome_pid
    if [[ -f "chrome-$port.pid" ]]; then
        chrome_pid=$(cat "chrome-$port.pid")
    else
        chrome_pid=$(get_chrome_pid_by_port "$port")
    fi
    
    if [[ -n "$chrome_pid" ]]; then
        kill_process_with_timeout "$chrome_pid" 10
        log_success "Chrome process $chrome_pid stopped"
        
        # Remove PID file
        rm -f "chrome-$port.pid"
    else
        log_warning "No Chrome process found on port $port"
    fi
    
    # Stop Xvfb if no other Chrome instances are running
    if ! pgrep -f "remote-debugging-port" > /dev/null; then
        pkill -f "Xvfb :99" 2>/dev/null || true
        log_info "Xvfb stopped"
    fi
    
    return 0
}

# Get Chrome status
get_chrome_status() {
    local port=${1:-$CHROME_PORT}
    
    if is_chrome_running "$port"; then
        local chrome_pid=$(get_chrome_pid_by_port "$port")
        echo "✅ Chrome is running on port $port (PID: $chrome_pid)"
        
        # Get Chrome version info
        local version_info=$(curl -s "http://localhost:$port/json/version" 2>/dev/null)
        if [[ -n "$version_info" ]]; then
            local browser_version=$(echo "$version_info" | grep -o '"Browser":"[^"]*"' | cut -d'"' -f4)
            echo "   Browser: $browser_version"
        fi
        
        return 0
    else
        echo "❌ Chrome is not running on port $port"
        return 1
    fi
}

# List all running Chrome instances
list_chrome_instances() {
    echo "Chrome Instances:"
    local found=false
    
    for port in {9222..9230}; do
        if is_chrome_running "$port"; then
            get_chrome_status "$port"
            found=true
        fi
    done
    
    if [[ "$found" == false ]]; then
        echo "No Chrome instances found"
    fi
}

# Show current configuration
show_current_config() {
    echo "Current Configuration:"
    echo "  Display Size: $DISPLAY_SIZE"
    echo "  Chrome Port: $CHROME_PORT"
    echo "  Chrome Address: $CHROME_ADDRESS"
    echo "  User Data Dir: $USER_DATA_DIR"
    echo "  Window Size: $WINDOW_SIZE"
    if [[ -n "$CONFIG_NAME" ]]; then
        echo "  Config Name: $CONFIG_NAME"
        echo "  Description: $CONFIG_DESCRIPTION"
    fi
}

# Export functions
export -f load_config override_config validate_config find_chrome_executable
export -f start_xvfb start_chrome stop_chrome get_chrome_status
export -f list_chrome_instances show_current_config
