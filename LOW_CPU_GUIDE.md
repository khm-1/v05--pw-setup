# Low CPU Usage Configuration Guide

## 🎯 CPU Optimization Strategies

### **1. Virtual Display Resolution Options**

| Resolution | Color Depth | CPU Impact | Use Case |
|------------|-------------|------------|----------|
| `1920x1024x24` | 24-bit | **High** | Full quality screenshots |
| `1280x720x16` | 16-bit | **Medium** | Good balance |
| `800x600x16` | 16-bit | **Low** | Basic automation |
| `640x480x8` | 8-bit | **Minimal** | Text-only tasks |

### **2. Chrome CPU Optimization Flags**

#### **High Impact Flags** (Major CPU reduction)
```bash
--disable-images              # Don't load images (50-70% CPU reduction)
--disable-javascript          # Disable JS if not needed (30-50% reduction)
--single-process             # Use single process mode (20-30% reduction)
--disable-gpu                # Disable GPU acceleration
--disable-extensions         # No extensions
--disable-plugins            # No plugins
```

#### **Medium Impact Flags** (Moderate CPU reduction)
```bash
--disable-background-networking
--disable-background-timer-throttling
--disable-renderer-backgrounding
--disable-backgrounding-occluded-windows
--memory-pressure-off
--max_old_space_size=512     # Limit memory to 512MB
```

#### **Low Impact Flags** (Minor CPU reduction)
```bash
--disable-web-security
--disable-features=TranslateUI
--disable-sync
--disable-default-apps
--no-first-run
```

### **3. Recommended Configurations**

#### **Ultra Low CPU** (For basic text scraping)
```bash
# Resolution: 640x480x8
# Chrome flags: --disable-images --disable-javascript --single-process
# Expected CPU usage: 5-15%
./run_chrome_remote_lowcpu.sh start
```

#### **Balanced** (For general automation)
```bash
# Resolution: 1280x720x16
# Chrome flags: --disable-images --disable-extensions
# Expected CPU usage: 15-30%
```

#### **Quality** (For screenshot-heavy tasks)
```bash
# Resolution: 1920x1024x16 (reduced from x24)
# Chrome flags: minimal optimization
# Expected CPU usage: 30-50%
```

### **4. System-Level Optimizations**

#### **CPU Governor Settings**
```bash
# Set CPU to powersave mode
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Or use performance mode for consistent low usage
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

#### **Process Priority**
```bash
# Run Chrome with lower priority
nice -n 10 /path/to/chrome [args...]

# Or use ionice for I/O priority
ionice -c 3 /path/to/chrome [args...]
```

#### **Memory Optimization**
```bash
# Limit Chrome memory usage
ulimit -v 1048576  # Limit virtual memory to 1GB
```

### **5. Monitoring CPU Usage**

#### **Real-time Monitoring**
```bash
# Monitor Chrome processes
watch -n 1 'ps aux | grep chrome | grep -v grep'

# Monitor system resources
htop

# Monitor specific process
top -p $(cat chrome_lowcpu.pid)
```

#### **CPU Usage Benchmarks**
```bash
# Test different configurations
./run_chrome_remote_lowcpu.sh start
# Run your automation task
# Monitor: htop or top
./run_chrome_remote_lowcpu.sh stop
```

### **6. Configuration Examples**

#### **Text-Only Scraping** (Minimal CPU)
```bash
# Xvfb resolution
SCREEN_RESOLUTION="640x480x8"

# Chrome args
--headless=new
--disable-gpu
--no-sandbox
--disable-images
--disable-javascript
--disable-css
--single-process
--memory-pressure-off
--max_old_space_size=256
```

#### **Screenshot Tasks** (Balanced)
```bash
# Xvfb resolution
SCREEN_RESOLUTION="1280x720x16"

# Chrome args
--headless=new
--disable-gpu
--no-sandbox
--disable-extensions
--disable-plugins
--disable-background-networking
--max_old_space_size=512
```

### **7. Performance Comparison**

| Configuration | CPU Usage | Memory Usage | Screenshot Quality |
|---------------|-----------|--------------|-------------------|
| **Ultra Low** | 5-15% | 100-200MB | Basic |
| **Balanced** | 15-30% | 200-400MB | Good |
| **Quality** | 30-50% | 400-800MB | High |
| **Original** | 50-80% | 800MB+ | Highest |

### **8. Quick Commands**

```bash
# Start low CPU Chrome
./run_chrome_remote_lowcpu.sh start

# Check CPU usage
ps aux | grep chrome | grep -v grep

# Monitor in real-time
watch -n 1 'ps -o pid,ppid,cmd,%mem,%cpu --sort=-%cpu -C chrome'

# Stop low CPU Chrome
./run_chrome_remote_lowcpu.sh stop
```

### **9. Troubleshooting Low CPU Mode**

#### **If pages don't load properly:**
- Remove `--disable-javascript` if JS is needed
- Remove `--disable-images` if images are required
- Increase memory limit: `--max_old_space_size=1024`

#### **If screenshots are poor quality:**
- Increase resolution: `1280x720x16` → `1920x1024x16`
- Remove `--disable-images`
- Use 16-bit instead of 8-bit color depth

#### **If automation fails:**
- Remove `--single-process` flag
- Add `--disable-web-security` if needed
- Increase timeout values in your scripts

## 🎯 **Recommendation for 1920x1024x24**

For your current resolution, I recommend:

1. **Change to `1920x1024x16`** - Reduces color processing by ~30%
2. **Add `--disable-images`** - Reduces CPU by 50-70% if images aren't needed
3. **Use `--single-process`** - Reduces CPU by 20-30%
4. **Set `--max_old_space_size=512`** - Limits memory usage

**Expected CPU reduction: 60-80% with minimal impact on functionality**
