#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Update package list and install necessary dependencies
echo "Updating package list and installing dependencies..."
sudo apt update
sudo apt install -y curl gnupg wget software-properties-common apt-transport-https ca-certificates

# Install Node.js and npm
echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Install Google Chrome (stable version)
echo "Installing Google Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install -y google-chrome-stable

# Install Playwright and its browsers (including Chromium as fallback)
echo "Installing Playwright and browsers..."
npm init -y
npm install playwright
npx playwright install chromium

# Install Xvfb and other display utilities for virtual display
echo "Installing Xvfb and other display utilities..."
sudo apt install -y xvfb x11-utils

# Install Deno if not already present
echo "Installing Deno..."
if ! command -v deno &> /dev/null; then
    curl -fsSL https://deno.land/install.sh | sh -s -- -y
    export PATH="$HOME/.deno/bin:$PATH"
    echo 'export PATH="$HOME/.deno/bin:$PATH"' >> ~/.bashrc
    echo "Deno installed successfully"
else
    echo "Deno is already installed"
fi

echo "Setup complete! Use './run_chrome_remote.sh' to start Chrome with remote debugging."
echo "Then run 'deno run --allow-net --allow-read --allow-write --allow-env deno_script.ts' to interact with Chrome."


