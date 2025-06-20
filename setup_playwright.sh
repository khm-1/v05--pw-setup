#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Update package list and install necessary dependencies
echo "Updating package list and installing dependencies..."
sudo apt update
sudo apt install -y curl gnupg

# Install Node.js and npm
echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Install Playwright and its browsers (including Chromium)
echo "Installing Playwright and browsers..."
npm init -y
npm install playwright
npx playwright install chromium

# Install Xvfb and other display utilities for virtual display
echo "Installing Xvfb and other display utilities..."
sudo apt install -y xvfb x11-utils

# Create a virtual display with 1920x1024 resolution
echo "Starting Xvfb virtual display..."
Xvfb :99 -screen 0 1920x1024x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99

# Start Chrome in headless mode with remote debugging enabled
echo "Starting Chrome in headless mode with remote debugging..."
# Ensure the Playwright-installed Chromium is used
CHROMIUM_PATH="/home/ubuntu/.cache/ms-playwright/chromium-1179/chrome-linux/chrome"

# Check if Chromium path is found
if [ -z "$CHROMIUM_PATH" ]; then
    echo "Error: Playwright Chromium executable not found."
    exit 1
fi

# Start Chrome with remote debugging on port 9222
# Use --disable-gpu and --no-sandbox for server environments
# --remote-debugging-address=0.0.0.0 allows external connections
"$CHROMIUM_PATH" --headless=new --remote-debugging-port=9222 --remote-debugging-address=0.0.0.0 --disable-gpu --no-sandbox --window-size=1920,1024 &> chrome_output.log &

echo "Playwright, Chrome, and Xvfb setup complete. Chrome is running with remote debugging on port 9222."
echo "You can check chrome_output.log for Chrome's output."


