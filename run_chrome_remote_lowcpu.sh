#!/bin/bash

# Low CPU Chrome Remote Debugging Launcher
set -e

# Configuration for lower CPU usage
DISPLAY_NUM=99
CHROME_PORT=9222
SCREEN_RESOLUTION="1280x720x16"  # Reduced resolution and color depth
WINDOW_SIZE="1280,720"

# Function to cleanup existing processes
cleanup_existing() {
    echo "Cleaning up existing processes..."
    sudo pkill -f "Xvfb :$DISPLAY_NUM" || true
    sudo pkill -f "remote-debugging-port=$CHROME_PORT" || true
    sudo rm -f /tmp/.X$DISPLAY_NUM-lock || true
    sleep 2
}

# Function to start virtual display with lower CPU usage
start_virtual_display() {
    echo "Starting Xvfb virtual display on :$DISPLAY_NUM with resolution $SCREEN_RESOLUTION..."
    
    # Start Xvfb with CPU optimization flags
    Xvfb :$DISPLAY_NUM -screen 0 $SCREEN_RESOLUTION \
        -ac +extension GLX +render -noreset \
        -dpi 96 \
        -fbdir /tmp &
    
    export DISPLAY=:$DISPLAY_NUM
    sleep 3
    
    if ! pgrep -f "Xvfb :$DISPLAY_NUM" > /dev/null; then
        echo "Error: Failed to start Xvfb"
        exit 1
    fi
    
    echo "Virtual display started successfully"
}

# Function to find Chrome executable
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

# Function to start Chrome with low CPU usage
start_chrome_remote() {
    local chrome_path=$(find_chrome_executable)
    
    if [[ -z "$chrome_path" ]]; then
        echo "Error: No Chrome/Chromium executable found!"
        exit 1
    fi
    
    echo "Using Chrome executable: $chrome_path"
    echo "Starting Chrome with low CPU configuration..."
    
    # Chrome arguments optimized for low CPU usage
    local chrome_args=(
        --headless=new
        --remote-debugging-port=$CHROME_PORT
        --remote-debugging-address=0.0.0.0
        --disable-gpu
        --no-sandbox
        --disable-dev-shm-usage
        --disable-extensions
        --disable-plugins
        --disable-images                    # Don't load images
        --disable-javascript               # Disable JS if not needed
        --disable-web-security
        --disable-features=TranslateUI
        --disable-ipc-flooding-protection
        --disable-renderer-backgrounding
        --disable-backgrounding-occluded-windows
        --disable-background-timer-throttling
        --disable-background-networking
        --disable-client-side-phishing-detection
        --disable-sync
        --disable-default-apps
        --disable-prompt-on-repost
        --no-first-run
        --no-default-browser-check
        --memory-pressure-off
        --max_old_space_size=512           # Limit memory usage
        --window-size=$WINDOW_SIZE
        --user-data-dir=/tmp/chrome-lowcpu-profile
        --single-process                   # Use single process mode
    )
    
    # Start Chrome in background
    "$chrome_path" "${chrome_args[@]}" &> chrome_lowcpu.log &
    local chrome_pid=$!
    
    echo "Waiting for Chrome to start..."
    sleep 5
    
    # Verify Chrome is accessible
    if ! curl -s "http://localhost:$CHROME_PORT/json/version" > /dev/null; then
        echo "Error: Chrome remote debugging is not accessible"
        echo "Check chrome_lowcpu.log for details"
        exit 1
    fi
    
    echo "Chrome started successfully with PID: $chrome_pid"
    echo "Remote debugging available at: http://localhost:$CHROME_PORT"
    echo $chrome_pid > chrome_lowcpu.pid
}

# Function to show status
show_status() {
    echo "=== Low CPU Chrome Remote Debugging Status ==="
    echo "Display: :$DISPLAY_NUM ($SCREEN_RESOLUTION)"
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
        if curl -s "http://localhost:$CHROME_PORT/json/version" > /dev/null; then
            echo "✓ Chrome remote debugging is accessible"
        else
            echo "✗ Chrome remote debugging is not accessible"
        fi
    else
        echo "✗ Chrome is not running"
    fi
    
    echo ""
    echo "Log files:"
    echo "  Chrome output: chrome_lowcpu.log"
    echo "  Chrome PID: chrome_lowcpu.pid"
}

# Function to stop services
stop_services() {
    echo "Stopping Chrome and Xvfb..."
    
    if [[ -f chrome_lowcpu.pid ]]; then
        local chrome_pid=$(cat chrome_lowcpu.pid)
        if kill -0 $chrome_pid 2>/dev/null; then
            kill $chrome_pid
            echo "Chrome process $chrome_pid stopped"
        fi
        rm -f chrome_lowcpu.pid
    fi
    
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
        echo "Low CPU Chrome is ready!"
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
        echo "Low CPU Chrome Remote Debugging Script"
        echo "Optimized for minimal CPU usage"
        exit 1
        ;;
esac
