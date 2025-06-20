# 🔧 Configuration Examples & Use Cases

## 🎯 **Quick Reference**

### **📋 Basic Usage:**
```bash
# Simple start (uses optimized defaults)
./start.sh

# Standard quality
./start.sh --standard

# CPU optimized
./start.sh --optimized

# Custom configuration file
./start.sh --config my-config.conf
```

### **⚙️ Custom Parameters:**
```bash
# Custom port
./start.sh --port 9223

# Custom display size
./start.sh --display-size 1920x1080x24

# Custom profile directory
./start.sh --user-data-dir /path/to/profile

# Custom debugging address (local only)
./start.sh --address 127.0.0.1

# Combined custom options
./start.sh --port 9223 --display-size 800x600x16 --user-data-dir /tmp/my-chrome
```

## 🏗️ **Real-World Use Cases**

### **🔬 Use Case 1: Multi-Instance Development**
```bash
# Scenario: Developer needs multiple Chrome instances for testing

# Instance 1: Main development (high quality)
./start.sh --port 9222 --display-size 1920x1080x24 --user-data-dir /tmp/dev-main
./run.sh scripts/main-app-test.ts 9222

# Instance 2: Mobile simulation (smaller screen)
./start.sh --port 9223 --display-size 375x667x16 --user-data-dir /tmp/dev-mobile
./run.sh scripts/mobile-test.ts 9223

# Instance 3: Performance testing (minimal resources)
./start.sh --port 9224 --display-size 800x600x16 --user-data-dir /tmp/dev-perf
./run.sh scripts/performance-test.ts 9224

# Check all instances
./status.sh --all-ports
```

### **🏢 Use Case 2: Production Environment**
```bash
# Scenario: Production server with security requirements

# Secure production setup
./start.sh \
  --address 127.0.0.1 \
  --port 9222 \
  --user-data-dir /var/lib/chrome-automation \
  --display-size 1280x720x16 \
  --config config/production.conf

# Run production automation
./run.sh scripts/production-scraper.ts

# Monitor performance
./status.sh --detailed --performance
```

### **🧪 Use Case 3: Automated Testing Pipeline**
```bash
# Scenario: CI/CD pipeline with parallel test execution

# Test Suite 1: UI Tests
./start.sh --port 9222 --display-size 1920x1080x16 --user-data-dir /tmp/ui-tests &

# Test Suite 2: API Tests with browser validation
./start.sh --port 9223 --display-size 1280x720x16 --user-data-dir /tmp/api-tests &

# Test Suite 3: Performance tests
./start.sh --port 9224 --display-size 800x600x16 --user-data-dir /tmp/perf-tests &

# Wait for all to start
sleep 10

# Run tests in parallel
./run.sh tests/ui-suite.ts 9222 &
./run.sh tests/api-suite.ts 9223 &
./run.sh tests/performance-suite.ts 9224 &

# Wait for completion and cleanup
wait
./stop.sh --all
```

### **📊 Use Case 4: Performance Comparison**
```bash
# Scenario: Compare different configurations for optimization

# High-quality baseline
./start.sh --port 9222 --display-size 1920x1080x24 --user-data-dir /tmp/hq-test
./run.sh scripts/benchmark.ts 9222 > results-hq.log &

# Medium quality
./start.sh --port 9223 --display-size 1280x720x16 --user-data-dir /tmp/med-test
./run.sh scripts/benchmark.ts 9223 > results-med.log &

# Low resource
./start.sh --port 9224 --display-size 800x600x16 --user-data-dir /tmp/low-test
./run.sh scripts/benchmark.ts 9224 > results-low.log &

# Compare results
wait
./tools/compare-performance.sh results-*.log
```

## 📁 **Configuration File Examples**

### **🎯 config/development.conf**
```bash
# Development configuration - High quality, debug-friendly
DISPLAY_SIZE="1920x1080x24"
CHROME_PORT="9999"
CHROME_ADDRESS="0.0.0.0"
USER_DATA_DIR="/tmp/chrome-development"
WINDOW_SIZE="1920,1080"
CHROME_FLAGS="--disable-web-security --allow-running-insecure-content --disable-features=VizDisplayCompositor"
```

### **🏭 config/production.conf**
```bash
# Production configuration - Optimized, secure
DISPLAY_SIZE="1280x720x16"
CHROME_PORT="9222"
CHROME_ADDRESS="127.0.0.1"
USER_DATA_DIR="/var/lib/chrome-automation"
WINDOW_SIZE="1280,720"
CHROME_FLAGS="--disable-extensions --disable-plugins --disable-background-networking --max_old_space_size=512"
```

### **🧪 config/testing.conf**
```bash
# Testing configuration - Fast, minimal resources
DISPLAY_SIZE="800x600x16"
CHROME_PORT="9223"
CHROME_ADDRESS="127.0.0.1"
USER_DATA_DIR="/tmp/chrome-testing"
WINDOW_SIZE="800,600"
CHROME_FLAGS="--disable-extensions --disable-plugins --disable-images --single-process --max_old_space_size=256"
```

### **📱 config/mobile-simulation.conf**
```bash
# Mobile simulation configuration
DISPLAY_SIZE="375x667x16"
CHROME_PORT="9224"
CHROME_ADDRESS="0.0.0.0"
USER_DATA_DIR="/tmp/chrome-mobile"
WINDOW_SIZE="375,667"
CHROME_FLAGS="--disable-extensions --user-agent='Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)'"
```

### **🔒 config/security.conf**
```bash
# High-security configuration
DISPLAY_SIZE="1280x720x16"
CHROME_PORT="9222"
CHROME_ADDRESS="127.0.0.1"
USER_DATA_DIR="/secure/chrome-profile"
WINDOW_SIZE="1280,720"
CHROME_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-extensions --disable-plugins --incognito"
```

## 🚀 **Advanced Usage Patterns**

### **🔄 Dynamic Port Assignment**
```bash
# Auto-find available port
./start.sh --auto-port --display-size 1280x720x16

# Start multiple instances with auto-port
for i in {1..5}; do
    ./start.sh --auto-port --user-data-dir /tmp/chrome-$i &
done
```

### **📊 Resource-Based Configuration**
```bash
# Check system resources and choose config
MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
CPU_CORES=$(nproc)

if [ $MEMORY_GB -gt 8 ] && [ $CPU_CORES -gt 4 ]; then
    ./start.sh --config config/high-performance.conf
elif [ $MEMORY_GB -gt 4 ]; then
    ./start.sh --config config/standard.conf
else
    ./start.sh --config config/low-resource.conf
fi
```

### **🔧 Environment-Based Configuration**
```bash
# Different configs for different environments
case "$ENVIRONMENT" in
    "development")
        ./start.sh --config config/development.conf
        ;;
    "staging")
        ./start.sh --config config/staging.conf
        ;;
    "production")
        ./start.sh --config config/production.conf
        ;;
    *)
        ./start.sh --optimized
        ;;
esac
```

## 📋 **Configuration Validation Examples**

### **✅ Pre-flight Checks**
```bash
# Validate configuration before starting
./start.sh --validate-only --config my-config.conf

# Check if port is available
./start.sh --check-port 9223

# Test display size compatibility
./start.sh --test-display 1920x1080x24

# Validate user data directory permissions
./start.sh --check-permissions /path/to/profile
```

### **🔍 Configuration Discovery**
```bash
# List all available configurations
./start.sh --list-configs

# Show configuration details
./start.sh --show-config config/production.conf

# Compare configurations
./start.sh --compare-configs config/standard.conf config/optimized.conf

# Generate configuration report
./start.sh --config-report > system-config-report.txt
```

## 🎯 **Best Practices**

### **📊 Performance Optimization**
```bash
# For CPU-constrained systems
./start.sh --display-size 800x600x16 --config config/low-cpu.conf

# For memory-constrained systems
./start.sh --config config/low-memory.conf --user-data-dir /tmp/chrome-minimal

# For high-throughput automation
./start.sh --config config/high-throughput.conf --port 9222
```

### **🔒 Security Best Practices**
```bash
# Local-only access
./start.sh --address 127.0.0.1 --port 9222

# Isolated profile directory
./start.sh --user-data-dir /isolated/chrome-profile --config config/security.conf

# Incognito mode for sensitive operations
./start.sh --config config/incognito.conf
```

### **🧪 Testing Best Practices**
```bash
# Separate profiles for different test suites
./start.sh --user-data-dir /tmp/unit-tests --port 9222 &
./start.sh --user-data-dir /tmp/integration-tests --port 9223 &
./start.sh --user-data-dir /tmp/e2e-tests --port 9224 &

# Consistent test environment
./start.sh --config config/testing.conf --display-size 1280x720x16
```

This comprehensive configuration system provides maximum flexibility while maintaining simplicity for basic use cases!
