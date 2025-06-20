#!/bin/bash
# Enhanced Script Runner with Auto-Detection and Multi-Instance Support

set -e

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source "lib/utils.sh"

# Show banner
show_banner() {
    echo "🏃 Chrome Automation Script Runner"
    echo "=================================="
    echo ""
}

# Auto-detect Chrome debugging port
detect_chrome_port() {
    local ports=(9222 9223 9224 9225 9226 9227 9228 9229 9230)
    
    for port in "${ports[@]}"; do
        if is_chrome_running "$port"; then
            echo "$port"
            return 0
        fi
    done
    
    # Return default port if none found
    echo "9222"
    return 1
}

# List available scripts
list_available_scripts() {
    echo "Available Scripts:"
    echo "=================="
    
    local script_dirs=("scripts" "examples" ".")
    local found_scripts=false
    
    for dir in "${script_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            for script in "$dir"/*.ts "$dir"/*.js; do
                if [[ -f "$script" ]]; then
                    found_scripts=true
                    local script_name=$(basename "$script")
                    local script_size=$(stat -c%s "$script" 2>/dev/null || echo "0")
                    echo "  $script ($script_size bytes)"
                    
                    # Try to extract description from script comments
                    local description=$(head -10 "$script" | grep -E "^//.*[Dd]escription|^#.*[Dd]escription" | head -1 | sed 's/^[#/]* *//' || echo "")
                    if [[ -n "$description" ]]; then
                        echo "    $description"
                    fi
                fi
            done
        fi
    done
    
    if [[ "$found_scripts" == false ]]; then
        echo "  No scripts found in scripts/, examples/, or current directory"
        echo "  Create scripts in the scripts/ directory or use full path"
    fi
    
    echo ""
}

# Create basic example script if none exists
create_basic_example() {
    local example_file="scripts/basic_example.ts"
    
    if [[ ! -f "$example_file" ]]; then
        log_info "Creating basic example script..."
        
        mkdir -p scripts
        
        cat > "$example_file" << 'EOF'
// Basic Chrome automation example
// Description: Takes a screenshot of Google homepage

import puppeteer from 'https://deno.land/x/puppeteer@16.2.0/mod.ts';

const CHROME_PORT = Deno.env.get('CHROME_PORT') || '9222';
const browserURL = `http://127.0.0.1:${CHROME_PORT}`;

async function run() {
  let browser;
  try {
    console.log(`Connecting to Chrome on port ${CHROME_PORT}...`);
    browser = await puppeteer.connect({
      browserURL,
      defaultViewport: null,
    });

    const page = await browser.newPage();
    const targetUrl = 'https://www.google.com';
    
    console.log(`Navigating to ${targetUrl}...`);
    await page.goto(targetUrl, { waitUntil: 'networkidle2' });

    const title = await page.title();
    console.log(`Page Title: ${title}`);

    const screenshotPath = 'screenshot.png';
    await page.screenshot({ path: screenshotPath });
    console.log(`Screenshot saved to ${screenshotPath}`);

    const logFilePath = 'page_info.log';
    await Deno.writeTextFile(logFilePath, `URL: ${targetUrl}\nTitle: ${title}\nTimestamp: ${new Date().toISOString()}\n`);
    console.log(`Page info logged to ${logFilePath}`);

    await page.close();
  } catch (error) {
    console.error('Error:', error);
    Deno.exit(1);
  } finally {
    if (browser) {
      await browser.disconnect();
    }
  }
}

if (import.meta.main) {
  run();
}
EOF
        
        log_success "Created basic example script: $example_file"
    fi
}

# Run Deno script
run_deno_script() {
    local script_path=$1
    local chrome_port=$2
    
    log_info "Running Deno script: $script_path"
    log_info "Chrome port: $chrome_port"
    
    # Set environment variable for Chrome port
    export CHROME_PORT="$chrome_port"
    
    # Run the script with required permissions
    deno run \
        --allow-net \
        --allow-read \
        --allow-write \
        --allow-env \
        "$script_path"
}

# Run Node.js script
run_nodejs_script() {
    local script_path=$1
    local chrome_port=$2
    
    log_info "Running Node.js script: $script_path"
    log_info "Chrome port: $chrome_port"
    
    # Set environment variable for Chrome port
    export CHROME_PORT="$chrome_port"
    
    # Check if package.json exists
    if [[ ! -f package.json ]]; then
        log_warning "package.json not found. Creating basic package.json..."
        npm init -y > /dev/null
        npm install playwright > /dev/null
    fi
    
    # Run the script
    node "$script_path"
}

# Determine script type and run appropriately
run_script() {
    local script_path=$1
    local chrome_port=$2
    
    # Check if script exists
    if [[ ! -f "$script_path" ]]; then
        # Try to find script in common directories
        local search_paths=("scripts/$script_path" "examples/$script_path" "./$script_path")
        local found=false
        
        for search_path in "${search_paths[@]}"; do
            if [[ -f "$search_path" ]]; then
                script_path="$search_path"
                found=true
                break
            fi
        done
        
        if [[ "$found" == false ]]; then
            log_error "Script not found: $script_path"
            echo ""
            list_available_scripts
            exit 1
        fi
    fi
    
    # Determine script type by extension
    case "$script_path" in
        *.ts)
            run_deno_script "$script_path" "$chrome_port"
            ;;
        *.js)
            run_nodejs_script "$script_path" "$chrome_port"
            ;;
        *)
            log_error "Unsupported script type: $script_path"
            log_error "Supported types: .ts (Deno), .js (Node.js)"
            exit 1
            ;;
    esac
}

# Show help
show_help() {
    echo "Usage: $0 [script] [options]"
    echo ""
    echo "Arguments:"
    echo "  script                   Script file to run (.ts or .js)"
    echo ""
    echo "Options:"
    echo "  --help, -h               Show this help message"
    echo "  --port PORT              Use specific Chrome port"
    echo "  --list                   List available scripts"
    echo "  --create-example         Create basic example script"
    echo ""
    echo "Examples:"
    echo "  ./run.sh basic_example.ts            # Run with auto-detected port"
    echo "  ./run.sh scripts/my_script.ts        # Run specific script"
    echo "  ./run.sh my_script.js --port 9223    # Run with specific port"
    echo "  ./run.sh --list                      # List available scripts"
    echo ""
    echo "Environment Variables:"
    echo "  CHROME_PORT              Chrome debugging port (set automatically)"
    echo ""
}

# Validate Chrome connection
validate_chrome_connection() {
    local chrome_port=$1
    
    if ! is_chrome_running "$chrome_port"; then
        log_error "Chrome is not running on port $chrome_port"
        log_error "Please start Chrome first: ./start.sh"
        
        # Show available Chrome instances
        echo ""
        log_info "Checking for other Chrome instances..."
        local found_instances=false
        for port in {9222..9230}; do
            if is_chrome_running "$port"; then
                log_info "Found Chrome running on port $port"
                found_instances=true
            fi
        done
        
        if [[ "$found_instances" == false ]]; then
            log_info "No Chrome instances found. Run './start.sh' to start Chrome."
        fi
        
        exit 1
    fi
    
    log_success "Chrome connection validated on port $chrome_port"
}

# Main function
main() {
    local script_path=""
    local chrome_port=""
    local list_scripts=false
    local create_example=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_banner
                show_help
                exit 0
                ;;
            --port)
                chrome_port="$2"
                shift 2
                ;;
            --list)
                list_scripts=true
                shift
                ;;
            --create-example)
                create_example=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$script_path" ]]; then
                    script_path="$1"
                else
                    log_error "Multiple script paths specified"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    show_banner
    
    # Handle list scripts
    if [[ "$list_scripts" == true ]]; then
        list_available_scripts
        exit 0
    fi
    
    # Handle create example
    if [[ "$create_example" == true ]]; then
        create_basic_example
        exit 0
    fi
    
    # Check if script path is provided
    if [[ -z "$script_path" ]]; then
        log_error "No script specified"
        echo ""
        show_help
        echo ""
        list_available_scripts
        exit 1
    fi
    
    # Auto-detect Chrome port if not specified
    if [[ -z "$chrome_port" ]]; then
        chrome_port=$(detect_chrome_port)
        if [[ $? -ne 0 ]]; then
            log_warning "No running Chrome instances detected, using default port $chrome_port"
        else
            log_info "Auto-detected Chrome port: $chrome_port"
        fi
    fi
    
    # Validate port
    if ! validate_port "$chrome_port"; then
        exit 1
    fi
    
    # Validate Chrome connection
    validate_chrome_connection "$chrome_port"
    
    # Create basic example if no scripts exist
    if [[ ! -d scripts ]] || [[ -z "$(find scripts -name "*.ts" -o -name "*.js" 2>/dev/null)" ]]; then
        log_info "No scripts found, creating basic example..."
        create_basic_example
    fi
    
    # Run the script
    echo ""
    log_info "Starting script execution..."
    echo "----------------------------------------"
    
    local start_time=$(date +%s)
    
    if run_script "$script_path" "$chrome_port"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo "----------------------------------------"
        log_success "Script completed successfully in ${duration}s"
    else
        echo "----------------------------------------"
        log_error "Script execution failed"
        exit 1
    fi
}

# Run main function
main "$@"
