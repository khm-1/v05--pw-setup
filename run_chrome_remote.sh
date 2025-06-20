#!/bin/bash

# Chrome Remote Debugging Launcher
# This script starts Chrome with remote debugging enabled for Deno script interaction

set -e

# Configuration
DISPLAY_NUM=99
CHROME_PORT=9222
SCREEN_RESOLUTION="1920x1024x24"
WINDOW_SIZE="1920,1024"

# Function to cleanup existing processes
cleanup_existing() {
    echo "Cleaning up existing processes..."
    
    # Kill existing Xvfb processes
    sudo pkill -f "Xvfb :$DISPLAY_NUM" || true
    
    # Kill existing Chrome processes on the debugging port
    sudo pkill -f "remote-debugging-port=$CHROME_PORT" || true
    
    # Remove X server lock files
    sudo rm -f /tmp/.X$DISPLAY_NUM-lock || true
    
    # Wait a moment for processes to fully terminate
    sleep 2
}

# Function to start virtual display
start_virtual_display() {
    echo "Starting Xvfb virtual display on :$DISPLAY_NUM with resolution $SCREEN_RESOLUTION..."
    
    # Start Xvfb in background
    Xvfb :$DISPLAY_NUM -screen 0 $SCREEN_RESOLUTION -ac +extension GLX +render -noreset &
    
    # Set display environment variable
    export DISPLAY=:$DISPLAY_NUM
    
    # Wait for Xvfb to start
    sleep 3
    
    # Verify Xvfb is running
    if ! pgrep -f "Xvfb :$DISPLAY_NUM" > /dev/null; then
        echo "Error: Failed to start Xvfb"
        exit 1
    fi
    
    echo "Virtual display started successfully"
}

# Function to find Chrome executable
find_chrome_executable() {
    # Priority order: Google Chrome, Playwright Chromium, system Chromium
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
    
    echo ""
    return 1
}

# Function to start Chrome with remote debugging
start_chrome_remote() {
    local chrome_path=$(find_chrome_executable)
    
    if [[ -z "$chrome_path" ]]; then
        echo "Error: No Chrome/Chromium executable found!"
        echo "Please ensure Google Chrome or Chromium is installed."
        exit 1
    fi
    
    echo "Using Chrome executable: $chrome_path"
    echo "Starting Chrome with remote debugging on port $CHROME_PORT..."
    
    # Chrome arguments for headless remote debugging
    local chrome_args=(
        --headless=new
        --remote-debugging-port=$CHROME_PORT
        --remote-debugging-address=0.0.0.0
        --disable-gpu
        --no-sandbox
        --disable-dev-shm-usage
        --disable-extensions
        --disable-plugins
        --disable-images
        --disable-javascript
        --window-size=$WINDOW_SIZE
        --user-data-dir=/tmp/chrome-remote-profile
        --no-first-run
        --no-default-browser-check
    )
    
    # Start Chrome in background and redirect output
    "$chrome_path" "${chrome_args[@]}" &> chrome_remote.log &
    local chrome_pid=$!
    
    # Wait for Chrome to start
    echo "Waiting for Chrome to start..."
    sleep 5
    
    # Verify Chrome is running and accessible
    if ! curl -s "http://localhost:$CHROME_PORT/json/version" > /dev/null; then
        echo "Error: Chrome remote debugging is not accessible on port $CHROME_PORT"
        echo "Check chrome_remote.log for details"
        exit 1
    fi
    
    echo "Chrome started successfully with PID: $chrome_pid"
    echo "Remote debugging available at: http://localhost:$CHROME_PORT"
    
    # Save PID for later cleanup
    echo $chrome_pid > chrome_remote.pid
}

# Function to show status
show_status() {
    echo "=== Chrome Remote Debugging Status ==="
    echo "Display: :$DISPLAY_NUM"
    echo "Chrome Port: $CHROME_PORT"
    echo "Window Size: $WINDOW_SIZE"
    echo ""
    
    if pgrep -f "Xvfb :$DISPLAY_NUM" > /dev/null; then
        echo "✓ Xvfb is running"
    else
        echo "✗ Xvfb is not running"
    fi
    
    if pgrep -f "remote-debugging-port=$CHROME_PORT" > /dev/null; then
        echo "✓ Chrome is running with remote debugging"
        
        # Try to get Chrome version info
        if curl -s "http://localhost:$CHROME_PORT/json/version" > /dev/null; then
            echo "✓ Chrome remote debugging is accessible"
            echo "  URL: http://localhost:$CHROME_PORT"
        else
            echo "✗ Chrome remote debugging is not accessible"
        fi
    else
        echo "✗ Chrome is not running"
    fi
    
    echo ""
    echo "Log files:"
    echo "  Chrome output: chrome_remote.log"
    echo "  Chrome PID: chrome_remote.pid"
}

# Function to stop Chrome and Xvfb
stop_services() {
    echo "Stopping Chrome and Xvfb..."
    
    # Stop Chrome
    if [[ -f chrome_remote.pid ]]; then
        local chrome_pid=$(cat chrome_remote.pid)
        if kill -0 $chrome_pid 2>/dev/null; then
            kill $chrome_pid
            echo "Chrome process $chrome_pid stopped"
        fi
        rm -f chrome_remote.pid
    fi
    
    # Cleanup all processes
    cleanup_existing
    
    echo "Services stopped"
}

# Main script logic
case "${1:-start}" in
    start)
        cleanup_existing
        start_virtual_display
        start_chrome_remote
        show_status
        echo ""
        echo "Chrome is ready for Deno script interaction!"
        echo "Run: deno run --allow-net --allow-read --allow-write --allow-env deno_script.ts"
        ;;
    stop)
        stop_services
        ;;
    status)
        show_status
        ;;
    restart)
        stop_services
        sleep 2
        cleanup_existing
        start_virtual_display
        start_chrome_remote
        show_status
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        echo ""
        echo "Commands:"
        echo "  start   - Start Xvfb and Chrome with remote debugging (default)"
        echo "  stop    - Stop Chrome and Xvfb"
        echo "  status  - Show current status"
        echo "  restart - Stop and start services"
        exit 1
        ;;
esac
