#!/bin/bash
# Utility functions for Chrome automation setup

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_progress() {
    echo -e "${BLUE}⏳ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if port is available
is_port_available() {
    local port=$1
    ! netstat -tlnp 2>/dev/null | grep ":$port " > /dev/null
}

# Find available port starting from given port
find_available_port() {
    local start_port=${1:-9222}
    local port=$start_port
    
    while [ $port -le 9999 ]; do
        if is_port_available $port; then
            echo $port
            return 0
        fi
        ((port++))
    done
    
    echo ""
    return 1
}

# Validate port number
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
        log_error "Invalid port: $port (must be 1024-65535)"
        return 1
    fi
    return 0
}

# Validate display size format
validate_display_size() {
    local display_size=$1
    if ! [[ "$display_size" =~ ^[0-9]+x[0-9]+x[0-9]+$ ]]; then
        log_error "Invalid display size format: $display_size"
        log_error "Expected format: WIDTHxHEIGHTxDEPTH (e.g., 1280x720x16)"
        return 1
    fi
    return 0
}

# Validate IP address
validate_address() {
    local address=$1
    if [[ "$address" != "0.0.0.0" ]] && [[ "$address" != "127.0.0.1" ]] && ! [[ "$address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid address format: $address"
        return 1
    fi
    return 0
}

# Extract window size from display size
get_window_size() {
    local display_size=$1
    echo "$display_size" | sed 's/x[0-9]*$//' | sed 's/x/,/'
}

# Check if Chrome is running on port
is_chrome_running() {
    local port=${1:-9222}
    curl -s "http://localhost:$port/json/version" > /dev/null 2>&1
}

# Get Chrome process PID by port
get_chrome_pid_by_port() {
    local port=${1:-9222}
    lsof -ti:$port 2>/dev/null | head -1
}

# Kill process by PID with timeout
kill_process_with_timeout() {
    local pid=$1
    local timeout=${2:-10}
    
    if [ -z "$pid" ]; then
        return 0
    fi
    
    # Check if process exists
    if ! kill -0 "$pid" 2>/dev/null; then
        return 0
    fi
    
    # Try graceful shutdown
    kill "$pid" 2>/dev/null
    
    # Wait for process to exit
    local count=0
    while [ $count -lt $timeout ] && kill -0 "$pid" 2>/dev/null; do
        sleep 1
        ((count++))
    done
    
    # Force kill if still running
    if kill -0 "$pid" 2>/dev/null; then
        log_warning "Force killing process $pid"
        kill -9 "$pid" 2>/dev/null
        sleep 1
    fi
    
    return 0
}

# Create directory if it doesn't exist
ensure_directory() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" 2>/dev/null || {
            log_error "Failed to create directory: $dir"
            return 1
        }
    fi
    return 0
}

# Check system resources
check_system_resources() {
    local memory_gb=$(free -g | awk '/^Mem:/{print $2}')
    local cpu_cores=$(nproc)
    local disk_space_gb=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
    
    log_info "System Resources:"
    log_info "  Memory: ${memory_gb}GB"
    log_info "  CPU Cores: ${cpu_cores}"
    log_info "  Available Disk: ${disk_space_gb}GB"
    
    # Recommendations based on resources
    if [ $memory_gb -lt 2 ]; then
        log_warning "Low memory detected. Consider using testing configuration."
    elif [ $memory_gb -gt 8 ] && [ $cpu_cores -gt 4 ]; then
        log_info "High-performance system detected. Standard configuration recommended."
    else
        log_info "Balanced system detected. Optimized configuration recommended."
    fi
}

# Wait for Chrome to be ready
wait_for_chrome() {
    local port=${1:-9222}
    local timeout=${2:-30}
    local count=0
    
    log_progress "Waiting for Chrome to be ready on port $port..."
    
    while [ $count -lt $timeout ]; do
        if is_chrome_running $port; then
            log_success "Chrome is ready on port $port"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    log_error "Chrome failed to start within $timeout seconds"
    return 1
}

# Show help for configuration options
show_config_help() {
    echo "Configuration Options:"
    echo "  --port PORT              Chrome debugging port (default: 9222)"
    echo "  --address ADDRESS        Chrome debugging address (default: 0.0.0.0)"
    echo "  --display-size SIZE      Virtual display size (default: 1280x720x16)"
    echo "  --user-data-dir DIR      Chrome profile directory"
    echo "  --config FILE            Configuration file to use"
    echo ""
    echo "Preset Configurations:"
    echo "  --standard               High quality 1920x1024x24"
    echo "  --optimized              CPU optimized 1280x720x16"
    echo "  --development            Development setup with debug features"
    echo "  --production             Secure production setup"
    echo "  --testing                Minimal resources for testing"
    echo ""
    echo "Examples:"
    echo "  ./start.sh --optimized"
    echo "  ./start.sh --port 9223 --display-size 800x600x16"
    echo "  ./start.sh --config config/custom.conf --port 9224"
}

# Export functions for use in other scripts
export -f log_info log_success log_warning log_error log_progress
export -f command_exists is_port_available find_available_port
export -f validate_port validate_display_size validate_address
export -f get_window_size is_chrome_running get_chrome_pid_by_port
export -f kill_process_with_timeout ensure_directory check_system_resources
export -f wait_for_chrome show_config_help
