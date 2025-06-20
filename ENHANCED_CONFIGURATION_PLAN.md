# 🔧 Enhanced Configuration Support Plan

## 🎯 **Custom Configuration Options**

### **📋 Supported Custom Parameters:**
1. **`--user-data-dir`** - Chrome profile directory
2. **`--remote-debugging-port`** - Chrome debugging port (default: 9222)
3. **`--remote-debugging-address`** - Debugging bind address (default: 0.0.0.0)
4. **`--display-size`** - Virtual display resolution (default: 1280x720x16)

## 🛠️ **Implementation Design**

### **📁 Configuration File Structure:**
```bash
config/
├── standard.conf           # Standard configuration
├── optimized.conf          # CPU-optimized configuration
├── custom.conf.example     # Template for custom config
└── presets/
    ├── high-quality.conf   # 1920x1080x24, port 9222
    ├── low-cpu.conf        # 800x600x16, port 9223
    ├── multi-instance.conf # Multiple Chrome instances
    └── development.conf    # Dev-friendly settings
```

### **⚙️ Configuration File Format:**
```bash
# config/standard.conf
DISPLAY_SIZE="1280x720x16"
CHROME_PORT="9222"
CHROME_ADDRESS="0.0.0.0"
USER_DATA_DIR="/tmp/chrome-standard-profile"
WINDOW_SIZE="1280,720"
CHROME_FLAGS="--disable-extensions --disable-plugins"

# config/optimized.conf
DISPLAY_SIZE="1280x720x16"
CHROME_PORT="9222"
CHROME_ADDRESS="0.0.0.0"
USER_DATA_DIR="/tmp/chrome-optimized-profile"
WINDOW_SIZE="1280,720"
CHROME_FLAGS="--disable-extensions --disable-plugins --disable-images --max_old_space_size=512"

# config/custom.conf.example
DISPLAY_SIZE="1920x1080x24"
CHROME_PORT="9223"
CHROME_ADDRESS="127.0.0.1"
USER_DATA_DIR="/home/user/chrome-custom-profile"
WINDOW_SIZE="1920,1080"
CHROME_FLAGS="--disable-web-security --allow-running-insecure-content"
```

## 🚀 **Enhanced Command Interface**

### **📋 start.sh Command Options:**
```bash
# Preset configurations
./start.sh                              # Use default optimized config
./start.sh --standard                   # Use standard config
./start.sh --optimized                  # Use CPU-optimized config
./start.sh --config path/to/config.conf # Use custom config file

# Direct parameter overrides
./start.sh --port 9223                  # Custom debugging port
./start.sh --address 127.0.0.1          # Custom debugging address
./start.sh --display-size 1920x1080x24  # Custom display resolution
./start.sh --user-data-dir /path/to/dir # Custom Chrome profile directory

# Combined usage
./start.sh --optimized --port 9223 --display-size 800x600x16
./start.sh --config custom.conf --port 9224
```

### **🔧 Advanced Configuration Examples:**
```bash
# Multi-instance setup
./start.sh --port 9222 --user-data-dir /tmp/chrome-instance-1 &
./start.sh --port 9223 --user-data-dir /tmp/chrome-instance-2 &
./start.sh --port 9224 --user-data-dir /tmp/chrome-instance-3 &

# High-security setup
./start.sh --address 127.0.0.1 --user-data-dir /secure/chrome-profile

# Development setup
./start.sh --config development.conf --port 9999 --display-size 1920x1080x24

# Production setup
./start.sh --config production.conf --address 0.0.0.0 --port 9222
```

## 📊 **Configuration Management Features**

### **🔍 Configuration Validation:**
```bash
# Validate configuration before starting
./start.sh --validate-config custom.conf
./start.sh --check-port 9223
./start.sh --test-display-size 1920x1080x24
```

### **📋 Configuration Discovery:**
```bash
# List available configurations
./start.sh --list-configs
# Output:
# Available configurations:
# - standard.conf (1280x720x16, port 9222)
# - optimized.conf (1280x720x16, port 9222, low CPU)
# - high-quality.conf (1920x1080x24, port 9222)
# - development.conf (1920x1080x24, port 9999)

# Show current configuration
./status.sh --show-config
# Output:
# Current Configuration:
# Display Size: 1280x720x16
# Chrome Port: 9222
# Chrome Address: 0.0.0.0
# User Data Dir: /tmp/chrome-optimized-profile
# Window Size: 1280,720
```

### **⚙️ Configuration Generator:**
```bash
# Interactive configuration creator
./setup.sh --create-config
# Prompts user for:
# - Display resolution (with recommendations)
# - Chrome debugging port
# - Debugging address (local/network)
# - Profile directory location
# - Performance preferences
# - Saves as custom.conf
```

## 🛠️ **Implementation Details**

### **📜 Enhanced start.sh Structure:**
```bash
#!/bin/bash
# Enhanced Chrome startup script with custom configuration support

# Default configuration
DEFAULT_CONFIG="config/optimized.conf"
DISPLAY_SIZE=""
CHROME_PORT=""
CHROME_ADDRESS=""
USER_DATA_DIR=""
WINDOW_SIZE=""
CHROME_FLAGS=""

# Function to load configuration file
load_config() {
    local config_file=$1
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        echo "✅ Loaded configuration: $config_file"
    else
        echo "❌ Configuration file not found: $config_file"
        exit 1
    fi
}

# Function to override configuration with command line arguments
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
                # Extract window size from display size
                WINDOW_SIZE=$(echo "$2" | sed 's/x.*x.*//' | sed 's/x/,/')
                shift 2
                ;;
            --user-data-dir)
                USER_DATA_DIR="$2"
                shift 2
                ;;
            --config)
                load_config "$2"
                shift 2
                ;;
            --standard)
                load_config "config/standard.conf"
                shift
                ;;
            --optimized)
                load_config "config/optimized.conf"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Validation functions
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
        echo "❌ Invalid port: $port (must be 1024-65535)"
        exit 1
    fi
    
    if netstat -tlnp 2>/dev/null | grep ":$port " > /dev/null; then
        echo "❌ Port $port is already in use"
        exit 1
    fi
}

validate_display_size() {
    local display_size=$1
    if ! [[ "$display_size" =~ ^[0-9]+x[0-9]+x[0-9]+$ ]]; then
        echo "❌ Invalid display size format: $display_size"
        echo "   Expected format: WIDTHxHEIGHTxDEPTH (e.g., 1280x720x16)"
        exit 1
    fi
}

validate_address() {
    local address=$1
    if [[ "$address" != "0.0.0.0" ]] && [[ "$address" != "127.0.0.1" ]] && ! [[ "$address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "❌ Invalid address format: $address"
        exit 1
    fi
}

# Main execution
main() {
    # Load default configuration
    load_config "$DEFAULT_CONFIG"
    
    # Override with command line arguments
    override_config "$@"
    
    # Validate configuration
    validate_port "$CHROME_PORT"
    validate_display_size "$DISPLAY_SIZE"
    validate_address "$CHROME_ADDRESS"
    
    # Start Chrome with custom configuration
    start_chrome_with_config
}
```

### **🔧 Enhanced run.sh for Custom Ports:**
```bash
#!/bin/bash
# Enhanced script runner with custom port support

# Auto-detect Chrome debugging port
detect_chrome_port() {
    local port
    for port in 9222 9223 9224 9225; do
        if curl -s "http://localhost:$port/json/version" > /dev/null 2>&1; then
            echo "$port"
            return 0
        fi
    done
    echo "9222"  # Default fallback
}

# Run script with custom Chrome connection
run_script() {
    local script_name=$1
    local chrome_port=${2:-$(detect_chrome_port)}
    
    echo "🚀 Running $script_name with Chrome on port $chrome_port"
    
    # Update script to use custom port
    if [[ "$script_name" == *.ts ]]; then
        # Deno script
        CHROME_PORT=$chrome_port deno run --allow-net --allow-read --allow-write --allow-env "$script_name"
    elif [[ "$script_name" == *.js ]]; then
        # Node.js script
        CHROME_PORT=$chrome_port node "$script_name"
    fi
}

# Usage: ./run.sh script_name [chrome_port]
run_script "$1" "$2"
```

## 📋 **Configuration Examples**

### **🎯 Use Case Examples:**

#### **Multi-Instance Development:**
```bash
# Terminal 1: Main development instance
./start.sh --port 9222 --user-data-dir /tmp/dev-main --display-size 1920x1080x24

# Terminal 2: Testing instance
./start.sh --port 9223 --user-data-dir /tmp/dev-test --display-size 1280x720x16

# Terminal 3: Production simulation
./start.sh --port 9224 --user-data-dir /tmp/dev-prod --config production.conf
```

#### **Security-Focused Setup:**
```bash
# Local-only access
./start.sh --address 127.0.0.1 --port 9222 --user-data-dir /secure/chrome

# Custom secure profile
./start.sh --config security.conf --user-data-dir /encrypted/chrome-profile
```

#### **Performance Testing:**
```bash
# High-quality baseline
./start.sh --display-size 1920x1080x24 --port 9222 --user-data-dir /tmp/hq-test

# Optimized comparison
./start.sh --display-size 1280x720x16 --port 9223 --user-data-dir /tmp/opt-test
```

## 🎯 **Enhanced User Experience**

### **📊 Smart Defaults:**
- Auto-detect available ports if default is in use
- Suggest optimal display size based on system resources
- Create user data directories automatically
- Validate configuration before starting

### **🔧 Configuration Helpers:**
```bash
# Configuration wizard
./setup.sh --configure
# Interactive prompts for all options

# Quick presets
./start.sh --preset development    # 1920x1080x24, port 9999, dev flags
./start.sh --preset production     # 1280x720x16, port 9222, optimized
./start.sh --preset testing        # 800x600x16, port 9223, minimal resources

# Configuration backup/restore
./setup.sh --backup-config my-config.backup
./setup.sh --restore-config my-config.backup
```

This enhanced configuration system provides maximum flexibility while maintaining ease of use. Users can start simple and customize as needed!
