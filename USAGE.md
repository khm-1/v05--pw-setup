# Updated Playwright + Deno Setup Usage Guide

## What's New

### Backup Created
- `setup_playwright.sh.backup` - Your original setup script is safely backed up

### Enhanced Setup Script
- `setup_playwright.sh` - Now installs Google Chrome directly instead of relying only on Playwright's Chromium
- Automatically installs Deno if not present
- Separated setup from Chrome launching for better control

### New Chrome Remote Script
- `run_chrome_remote.sh` - Dedicated script for managing Chrome with remote debugging
- Supports start/stop/status/restart commands
- Better error handling and process management
- Automatic cleanup of existing processes

### Enhanced Deno Script
- `deno_script_enhanced.ts` - Improved version with better error handling, retries, and logging

## Quick Start

### 1. Initial Setup (Run Once)
```bash
# Make setup script executable
chmod +x setup_playwright.sh

# Run the setup (installs everything)
./setup_playwright.sh
```

### 2. Start Chrome for Remote Debugging
```bash
# Start Chrome with remote debugging
./run_chrome_remote.sh start

# Check if Chrome is running properly
./run_chrome_remote.sh status
```

### 3. Run Deno Script
```bash
# Use the original script
deno run --allow-net --allow-read --allow-write --allow-env deno_script.ts

# Or use the enhanced version (recommended)
deno run --allow-net --allow-read --allow-write --allow-env deno_script_enhanced.ts
```

### 4. Stop Chrome When Done
```bash
./run_chrome_remote.sh stop
```

## Chrome Remote Script Commands

```bash
./run_chrome_remote.sh start    # Start Xvfb and Chrome
./run_chrome_remote.sh stop     # Stop Chrome and Xvfb
./run_chrome_remote.sh status   # Show current status
./run_chrome_remote.sh restart  # Stop and start services
```

## Key Improvements

1. **Google Chrome Installation**: Now installs the full Google Chrome browser for better compatibility
2. **Better Process Management**: Proper cleanup of existing processes before starting new ones
3. **Enhanced Error Handling**: More informative error messages and troubleshooting hints
4. **Flexible Chrome Detection**: Automatically finds Chrome/Chromium in multiple locations
5. **Status Monitoring**: Easy way to check if services are running properly
6. **Graceful Shutdown**: Proper cleanup when stopping services

## Troubleshooting

### Chrome Not Starting
```bash
# Check status
./run_chrome_remote.sh status

# View Chrome logs
cat chrome_remote.log

# Restart services
./run_chrome_remote.sh restart
```

### Deno Script Connection Issues
```bash
# Ensure Chrome is running
./run_chrome_remote.sh status

# Check if port 9222 is accessible
curl http://localhost:9222/json/version
```

### Clean Restart Everything
```bash
# Stop all services
./run_chrome_remote.sh stop

# Wait a moment
sleep 3

# Start fresh
./run_chrome_remote.sh start
```

## Files Overview

- `setup_playwright.sh` - Main setup script (updated)
- `setup_playwright.sh.backup` - Original setup script backup
- `run_chrome_remote.sh` - Chrome remote debugging manager (new)
- `deno_script.ts` - Original Deno script
- `deno_script_enhanced.ts` - Enhanced Deno script with better error handling (new)
- `chrome_remote.log` - Chrome output log (created by remote script)
- `chrome_remote.pid` - Chrome process ID file (created by remote script)
