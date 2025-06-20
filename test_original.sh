#!/bin/bash
# Test Original Configuration: 1920x1024x24

echo "=== Testing Original Configuration (1920x1024x24) ==="

# Cleanup
pkill -f "Xvfb :99" || true
pkill -f "remote-debugging-port=9222" || true
sleep 2

# Start Xvfb with original resolution
echo "Starting Xvfb with 1920x1024x24..."
Xvfb :99 -screen 0 1920x1024x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99
sleep 3

# Start Chrome with minimal flags (original style)
echo "Starting Chrome with original configuration..."
/home/kawhomsudarat/.cache/ms-playwright/chromium-1179/chrome-linux/chrome \
    --headless=new \
    --remote-debugging-port=9222 \
    --remote-debugging-address=0.0.0.0 \
    --disable-gpu \
    --no-sandbox \
    --window-size=1920,1024 \
    --user-data-dir=/tmp/chrome-original-test &

CHROME_PID=$!
echo "Chrome PID: $CHROME_PID"
sleep 5

# Test if Chrome is accessible
if curl -s http://localhost:9222/json/version > /dev/null; then
    echo "✓ Chrome is accessible"
    
    # Measure CPU usage before test
    echo "Measuring baseline CPU usage..."
    ps -o pid,ppid,cmd,%cpu,%mem --sort=-%cpu -C chrome > original_baseline.log
    
    # Run Deno test
    echo "Running Deno test..."
    timeout 30s deno run --allow-net --allow-read --allow-write --allow-env deno_script.ts > original_test.log 2>&1 &
    DENO_PID=$!
    
    # Monitor CPU usage during test
    echo "Monitoring CPU usage for 15 seconds..."
    for i in {1..15}; do
        ps -o pid,ppid,cmd,%cpu,%mem --sort=-%cpu -C chrome >> original_cpu_monitor.log
        echo "--- Sample $i ---" >> original_cpu_monitor.log
        sleep 1
    done
    
    # Wait for Deno to finish
    wait $DENO_PID
    
    # Final CPU measurement
    ps -o pid,ppid,cmd,%cpu,%mem --sort=-%cpu -C chrome > original_final.log
    
    echo "✓ Original configuration test completed"
    echo "Results saved to: original_*.log"
    
else
    echo "✗ Chrome failed to start"
fi

# Cleanup
kill $CHROME_PID 2>/dev/null || true
pkill -f "Xvfb :99" || true
