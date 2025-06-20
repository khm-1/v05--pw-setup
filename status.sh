#!/bin/bash
# Enhanced Chrome Status Script with Detailed Information

set -e

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source "lib/utils.sh"
source "lib/chrome_manager.sh"

# Show banner
show_banner() {
    echo "📊 Chrome Remote Debugging Status"
    echo "================================="
    echo ""
}

# Show system information
show_system_info() {
    echo "System Information:"
    echo "==================="
    
    # System resources
    local memory_total=$(free -h | awk '/^Mem:/{print $2}')
    local memory_used=$(free -h | awk '/^Mem:/{print $3}')
    local memory_available=$(free -h | awk '/^Mem:/{print $7}')
    local cpu_cores=$(nproc)
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    
    echo "  Memory: $memory_used / $memory_total (Available: $memory_available)"
    echo "  CPU Cores: $cpu_cores"
    echo "  Load Average: $load_avg"
    
    # Disk space
    local disk_info=$(df -h . | awk 'NR==2 {print $3 " / " $2 " (Available: " $4 ")"}')
    echo "  Disk Usage: $disk_info"
    
    echo ""
}

# Show Chrome instances with detailed information
show_chrome_instances() {
    echo "Chrome Instances:"
    echo "================="
    
    local found=false
    
    for port in {9222..9230}; do
        if is_chrome_running "$port"; then
            found=true
            
            # Get basic status
            get_chrome_status "$port"
            
            # Get additional details
            local chrome_pid=$(get_chrome_pid_by_port "$port")
            if [[ -n "$chrome_pid" ]]; then
                # Get process information
                local process_info=$(ps -p "$chrome_pid" -o pid,ppid,%cpu,%mem,etime,cmd --no-headers 2>/dev/null || echo "Process info unavailable")
                echo "   Process Info: $process_info"
                
                # Get user data directory
                local user_data_dir=$(ps -p "$chrome_pid" -o cmd --no-headers | grep -o 'user-data-dir=[^ ]*' | cut -d'=' -f2 || echo "Unknown")
                echo "   Profile Dir: $user_data_dir"
                
                # Get Chrome flags
                local chrome_flags=$(ps -p "$chrome_pid" -o cmd --no-headers | sed 's/.*chrome[^ ]* //' | tr ' ' '\n' | grep '^--' | head -5 | tr '\n' ' ')
                if [[ -n "$chrome_flags" ]]; then
                    echo "   Chrome Flags: $chrome_flags..."
                fi
                
                # Get debugging info
                local debug_info=$(curl -s "http://localhost:$port/json" 2>/dev/null | jq -r 'length' 2>/dev/null || echo "0")
                echo "   Open Tabs: $debug_info"
            fi
            
            echo ""
        fi
    done
    
    if [[ "$found" == false ]]; then
        echo "❌ No Chrome instances found"
        echo ""
    fi
}

# Show Xvfb status
show_xvfb_status() {
    echo "Virtual Display (Xvfb):"
    echo "======================="
    
    if pgrep -f "Xvfb :99" > /dev/null; then
        local xvfb_pid=$(pgrep -f "Xvfb :99")
        local xvfb_info=$(ps -p "$xvfb_pid" -o pid,%cpu,%mem,etime,cmd --no-headers 2>/dev/null || echo "Process info unavailable")
        echo "✅ Xvfb is running on display :99"
        echo "   Process Info: $xvfb_info"
        
        # Extract display configuration
        local display_config=$(ps -p "$xvfb_pid" -o cmd --no-headers | grep -o '\-screen 0 [^ ]*' | cut -d' ' -f3 || echo "Unknown")
        echo "   Display Config: $display_config"
    else
        echo "❌ Xvfb is not running"
    fi
    
    echo ""
}

# Show network information
show_network_info() {
    echo "Network Information:"
    echo "==================="
    
    # Show listening ports
    local listening_ports=$(netstat -tlnp 2>/dev/null | grep ':92[0-9][0-9]' | awk '{print $4}' | cut -d':' -f2 | sort -n | tr '\n' ' ')
    if [[ -n "$listening_ports" ]]; then
        echo "  Listening Ports: $listening_ports"
    else
        echo "  No Chrome debugging ports found"
    fi
    
    # Show external access information
    local external_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "Unknown")
    if [[ "$external_ip" != "Unknown" ]]; then
        echo "  External IP: $external_ip"
        echo "  External Access: http://$external_ip:PORT (if Chrome address is 0.0.0.0)"
    fi
    
    echo ""
}

# Show configuration files
show_configurations() {
    echo "Available Configurations:"
    echo "========================="
    
    if [[ -d config ]]; then
        for config_file in config/*.conf; do
            if [[ -f "$config_file" ]]; then
                local config_name=$(basename "$config_file" .conf)
                
                # Try to extract metadata
                if grep -q "CONFIG_NAME=" "$config_file" 2>/dev/null; then
                    source "$config_file"
                    echo "  $config_name: $CONFIG_DESCRIPTION"
                    echo "    Display: $DISPLAY_SIZE, Port: $CHROME_PORT, CPU: $CPU_USAGE, Quality: $QUALITY"
                else
                    echo "  $config_name: $(basename "$config_file")"
                fi
            fi
        done
    else
        echo "❌ Configuration directory not found"
    fi
    
    echo ""
}

# Show performance metrics
show_performance_metrics() {
    echo "Performance Metrics:"
    echo "==================="
    
    local total_cpu=0
    local total_memory=0
    local instance_count=0
    
    for port in {9222..9230}; do
        if is_chrome_running "$port"; then
            local chrome_pid=$(get_chrome_pid_by_port "$port")
            if [[ -n "$chrome_pid" ]]; then
                local cpu_usage=$(ps -p "$chrome_pid" -o %cpu --no-headers 2>/dev/null | xargs || echo "0")
                local mem_usage=$(ps -p "$chrome_pid" -o %mem --no-headers 2>/dev/null | xargs || echo "0")
                
                total_cpu=$(echo "$total_cpu + $cpu_usage" | bc -l 2>/dev/null || echo "$total_cpu")
                total_memory=$(echo "$total_memory + $mem_usage" | bc -l 2>/dev/null || echo "$total_memory")
                ((instance_count++))
                
                echo "  Port $port: CPU ${cpu_usage}%, Memory ${mem_usage}%"
            fi
        fi
    done
    
    if [[ $instance_count -gt 0 ]]; then
        echo "  Total: CPU ${total_cpu}%, Memory ${total_memory}% ($instance_count instances)"
    else
        echo "  No Chrome instances running"
    fi
    
    echo ""
}

# Show log files
show_log_files() {
    echo "Log Files:"
    echo "=========="
    
    local log_files=(chrome-*.log chrome-*.pid)
    local found_logs=false
    
    for log_pattern in "${log_files[@]}"; do
        for log_file in $log_pattern; do
            if [[ -f "$log_file" ]]; then
                found_logs=true
                local file_size=$(stat -c%s "$log_file" 2>/dev/null || echo "0")
                local file_date=$(stat -c%y "$log_file" 2>/dev/null | cut -d' ' -f1 || echo "Unknown")
                echo "  $log_file: ${file_size} bytes (Modified: $file_date)"
            fi
        done
    done
    
    if [[ "$found_logs" == false ]]; then
        echo "  No log files found"
    fi
    
    echo ""
}

# Show help
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h               Show this help message"
    echo "  --port PORT              Show status for specific port"
    echo "  --detailed               Show detailed system information"
    echo "  --performance            Show performance metrics"
    echo "  --configs                Show available configurations"
    echo "  --logs                   Show log file information"
    echo "  --all-ports              Scan all common Chrome ports"
    echo "  --json                   Output in JSON format"
    echo ""
    echo "Examples:"
    echo "  ./status.sh                      # Show basic status"
    echo "  ./status.sh --detailed           # Show detailed information"
    echo "  ./status.sh --port 9223          # Show status for port 9223"
    echo "  ./status.sh --performance        # Show performance metrics"
    echo ""
}

# Output JSON format
output_json() {
    echo "{"
    echo "  \"chrome_instances\": ["
    
    local first=true
    for port in {9222..9230}; do
        if is_chrome_running "$port"; then
            if [[ "$first" == false ]]; then
                echo ","
            fi
            first=false
            
            local chrome_pid=$(get_chrome_pid_by_port "$port")
            local cpu_usage=$(ps -p "$chrome_pid" -o %cpu --no-headers 2>/dev/null | xargs || echo "0")
            local mem_usage=$(ps -p "$chrome_pid" -o %mem --no-headers 2>/dev/null | xargs || echo "0")
            
            echo "    {"
            echo "      \"port\": $port,"
            echo "      \"pid\": $chrome_pid,"
            echo "      \"cpu_usage\": \"$cpu_usage%\","
            echo "      \"memory_usage\": \"$mem_usage%\","
            echo "      \"status\": \"running\""
            echo "    }"
        fi
    done
    
    echo "  ],"
    echo "  \"xvfb_running\": $(pgrep -f "Xvfb :99" > /dev/null && echo "true" || echo "false"),"
    echo "  \"timestamp\": \"$(date -Iseconds)\""
    echo "}"
}

# Main function
main() {
    local show_detailed=false
    local show_performance=false
    local show_configs=false
    local show_logs=false
    local specific_port=""
    local json_output=false
    local scan_all_ports=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_banner
                show_help
                exit 0
                ;;
            --detailed)
                show_detailed=true
                shift
                ;;
            --performance)
                show_performance=true
                shift
                ;;
            --configs)
                show_configs=true
                shift
                ;;
            --logs)
                show_logs=true
                shift
                ;;
            --port)
                specific_port="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            --all-ports)
                scan_all_ports=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Handle JSON output
    if [[ "$json_output" == true ]]; then
        output_json
        exit 0
    fi
    
    show_banner
    
    # Handle specific port
    if [[ -n "$specific_port" ]]; then
        if ! validate_port "$specific_port"; then
            exit 1
        fi
        get_chrome_status "$specific_port"
        exit 0
    fi
    
    # Show basic status
    show_chrome_instances
    show_xvfb_status
    
    # Show additional information based on flags
    if [[ "$show_detailed" == true ]]; then
        show_system_info
        show_network_info
    fi
    
    if [[ "$show_performance" == true ]]; then
        show_performance_metrics
    fi
    
    if [[ "$show_configs" == true ]]; then
        show_configurations
    fi
    
    if [[ "$show_logs" == true ]]; then
        show_log_files
    fi
    
    # Show summary
    local running_count=$(pgrep -f "remote-debugging-port" | wc -l)
    if [[ $running_count -gt 0 ]]; then
        log_success "Chrome automation is ready ($running_count instance(s) running)"
    else
        log_info "No Chrome instances running. Use './start.sh' to start Chrome."
    fi
}

# Run main function
main "$@"
