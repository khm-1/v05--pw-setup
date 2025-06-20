#!/bin/bash
# Test Balanced Configuration: 1280x720x16

echo "=== Testing Balanced Configuration (1280x720x16) ==="

# Cleanup
pkill -f "Xvfb :99" || true
pkill -f "remote-debugging-port=9222" || true
sleep 2

# Start Xvfb with balanced resolution
echo "Starting Xvfb with 1280x720x16..."
Xvfb :99 -screen 0 1280x720x16 -ac +extension GLX +render -noreset &
export DISPLAY=:99
sleep 3

# Start Chrome with some optimization flags
echo "Starting Chrome with balanced configuration..."
/home/kawhomsudarat/.cache/ms-playwright/chromium-1179/chrome-linux/chrome \
    --headless=new \
    --remote-debugging-port=9222 \
    --remote-debugging-address=0.0.0.0 \
    --disable-gpu \
    --no-sandbox \
    --disable-extensions \
    --disable-plugins \
    --max_old_space_size=512 \
    --window-size=1280,720 \
    --user-data-dir=/tmp/chrome-balanced-test &

CHROME_PID=$!
echo "Chrome PID: $CHROME_PID"
sleep 5

# Test if Chrome is accessible
if curl -s http://localhost:9222/json/version > /dev/null; then
    echo "✓ Chrome is accessible"
    
    # Measure CPU usage before test
    echo "Measuring baseline CPU usage..."
    ps -o pid,ppid,cmd,%cpu,%mem --sort=-%cpu -C chrome > balanced_baseline.log
    
    # Run Deno test
    echo "Running Deno test..."
    timeout 30s deno run --allow-net --allow-read --allow-write --allow-env deno_script.ts > balanced_test.log 2>&1 &
    DENO_PID=$!
    
    # Monitor CPU usage during test
    echo "Monitoring CPU usage for 15 seconds..."
    for i in {1..15}; do
        ps -o pid,ppid,cmd,%cpu,%mem --sort=-%cpu -C chrome >> balanced_cpu_monitor.log
        echo "--- Sample $i ---" >> balanced_cpu_monitor.log
        sleep 1
    done
    
    # Wait for Deno to finish
    wait $DENO_PID
    
    # Final CPU measurement
    ps -o pid,ppid,cmd,%cpu,%mem --sort=-%cpu -C chrome > balanced_final.log
    
    echo "✓ Balanced configuration test completed"
    echo "Results saved to: balanced_*.log"
    
else
    echo "✗ Chrome failed to start"
fi

# Cleanup
kill $CHROME_PID 2>/dev/null || true
pkill -f "Xvfb :99" || true
