#!/bin/bash
# Comprehensive CPU Performance Test

echo "🧪 COMPREHENSIVE CPU OPTIMIZATION TESTING"
echo "=========================================="

# Function to run a configuration test
run_test() {
    local config_name=$1
    local resolution=$2
    local chrome_flags=$3
    local test_duration=20
    
    echo ""
    echo "🔬 Testing: $config_name"
    echo "Resolution: $resolution"
    echo "Chrome flags: $chrome_flags"
    echo "----------------------------------------"
    
    # Cleanup
    pkill -f "Xvfb :99" || true
    pkill -f "remote-debugging-port=9222" || true
    sleep 3
    
    # Start Xvfb
    echo "Starting Xvfb with $resolution..."
    Xvfb :99 -screen 0 $resolution -ac +extension GLX +render -noreset &
    export DISPLAY=:99
    sleep 3
    
    # Start Chrome
    echo "Starting Chrome..."
    /home/kawhomsudarat/.cache/ms-playwright/chromium-1179/chrome-linux/chrome \
        --headless=new \
        --remote-debugging-port=9222 \
        --remote-debugging-address=0.0.0.0 \
        --disable-gpu \
        --no-sandbox \
        --user-data-dir=/tmp/chrome-test-$config_name \
        $chrome_flags &
    
    local chrome_pid=$!
    echo "Chrome PID: $chrome_pid"
    sleep 5
    
    # Check if Chrome started
    if ! curl -s http://localhost:9222/json/version > /dev/null; then
        echo "❌ Chrome failed to start"
        return 1
    fi
    
    echo "✅ Chrome started successfully"
    
    # Baseline measurement
    echo "📊 Measuring baseline CPU/Memory..."
    ps -o pid,ppid,%cpu,%mem,cmd -C chrome | head -10 > ${config_name}_baseline.log
    
    # Start monitoring
    echo "📈 Starting CPU monitoring for $test_duration seconds..."
    (
        for i in $(seq 1 $test_duration); do
            ps -o pid,%cpu,%mem -C chrome --no-headers >> ${config_name}_monitor.log
            sleep 1
        done
    ) &
    local monitor_pid=$!
    
    # Run multiple Deno tests to stress test
    echo "🚀 Running stress test (3 consecutive Deno runs)..."
    for run in {1..3}; do
        echo "  Run $run/3..."
        timeout 15s deno run --allow-net --allow-read --allow-write --allow-env deno_script.ts > ${config_name}_run${run}.log 2>&1
        sleep 2
    done
    
    # Wait for monitoring to complete
    wait $monitor_pid
    
    # Calculate averages
    local avg_cpu=$(awk '{sum+=$2; count++} END {if(count>0) printf "%.2f", sum/count}' ${config_name}_monitor.log)
    local avg_mem=$(awk '{sum+=$3; count++} END {if(count>0) printf "%.2f", sum/count}' ${config_name}_monitor.log)
    local max_cpu=$(awk 'BEGIN{max=0} {if($2>max) max=$2} END {printf "%.2f", max}' ${config_name}_monitor.log)
    local max_mem=$(awk 'BEGIN{max=0} {if($3>max) max=$3} END {printf "%.2f", max}' ${config_name}_monitor.log)
    
    # Save results
    echo "📋 RESULTS for $config_name:" | tee ${config_name}_results.txt
    echo "  Average CPU: ${avg_cpu}%" | tee -a ${config_name}_results.txt
    echo "  Maximum CPU: ${max_cpu}%" | tee -a ${config_name}_results.txt
    echo "  Average Memory: ${avg_mem}%" | tee -a ${config_name}_results.txt
    echo "  Maximum Memory: ${max_mem}%" | tee -a ${config_name}_results.txt
    echo "  Resolution: $resolution" | tee -a ${config_name}_results.txt
    echo "  Chrome Flags: $chrome_flags" | tee -a ${config_name}_results.txt
    
    # Check screenshot
    if [ -f screenshot.png ]; then
        local screenshot_size=$(stat -c%s screenshot.png)
        echo "  Screenshot Size: ${screenshot_size} bytes" | tee -a ${config_name}_results.txt
        mv screenshot.png ${config_name}_screenshot.png
    fi
    
    # Cleanup
    kill $chrome_pid 2>/dev/null || true
    pkill -f "Xvfb :99" || true
    sleep 2
    
    echo "✅ $config_name test completed"
}

# Test 1: Original Configuration
run_test "original" "1920x1024x24" "--window-size=1920,1024"

# Test 2: Reduced Color Depth
run_test "reduced_color" "1920x1024x16" "--window-size=1920,1024"

# Test 3: Reduced Resolution
run_test "reduced_resolution" "1280x720x16" "--window-size=1280,720"

# Test 4: Basic Optimization
run_test "basic_optimized" "1280x720x16" "--window-size=1280,720 --disable-extensions --disable-plugins --max_old_space_size=512"

# Test 5: Aggressive Optimization
run_test "aggressive" "1280x720x16" "--window-size=1280,720 --disable-extensions --disable-plugins --disable-images --disable-background-networking --max_old_space_size=512 --single-process"

# Test 6: Ultra Low (smallest resolution)
run_test "ultra_low" "800x600x16" "--window-size=800,600 --disable-extensions --disable-plugins --disable-images --disable-background-networking --max_old_space_size=256 --single-process"

echo ""
echo "🎯 COMPREHENSIVE TEST COMPLETED!"
echo "================================="
echo ""
echo "📊 SUMMARY RESULTS:"
echo "==================="

for config in original reduced_color reduced_resolution basic_optimized aggressive ultra_low; do
    if [ -f ${config}_results.txt ]; then
        echo ""
        cat ${config}_results.txt
    fi
done

echo ""
echo "📁 Generated files:"
ls -la *_results.txt *_screenshot.png 2>/dev/null || echo "No result files found"
