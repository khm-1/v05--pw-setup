# 🚀 Quick Start Guide

Get up and running with Chrome headless automation in under 5 minutes!

## 📋 **Prerequisites**

- Ubuntu 20.04+ server
- Internet connection
- Basic terminal access

## ⚡ **5-Minute Setup**

### **Step 1: Clone Repository**
```bash
git clone https://github.com/khm-1/v05--pw-setup.git
cd v05--pw-setup
```

### **Step 2: One-Command Setup**
```bash
./setup.sh
```
This installs:
- Google Chrome
- Node.js and npm
- Deno runtime
- Xvfb virtual display
- All dependencies

### **Step 3: Start Chrome**
```bash
./start.sh
```
Chrome starts with optimized settings (1280x720x16, low CPU usage)

### **Step 4: Run Your First Automation**
```bash
./run.sh basic_example.ts
```
This will:
- Take a screenshot of Google homepage
- Save it as `screenshot.png`
- Create a log file with page information

### **Step 5: Check Results**
```bash
ls -la screenshot.png page_info.log
./status.sh
```

### **Step 6: Stop When Done**
```bash
./stop.sh
```

## 🎯 **That's It!**

You now have a working Chrome automation environment. The basic example demonstrates:
- Connecting to Chrome
- Navigating to a webpage
- Taking screenshots
- Logging page information

## 🔧 **Next Steps**

### **Try Different Configurations**
```bash
# High quality screenshots
./start.sh --standard

# Development setup with debugging
./start.sh --development

# Production setup (secure)
./start.sh --production
```

### **Create Your Own Scripts**
```bash
# Copy the example
cp scripts/basic_example.ts scripts/my_script.ts

# Edit with your automation logic
nano scripts/my_script.ts

# Run your script
./run.sh my_script.ts
```

### **Monitor Performance**
```bash
# Check system status
./status.sh --detailed

# Monitor performance
./status.sh --performance

# View all running instances
./status.sh --all-ports
```

## 🎨 **Common Use Cases**

### **Web Scraping**
```typescript
// Extract data from websites
const data = await page.evaluate(() => {
  return document.querySelector('h1').textContent;
});
```

### **Automated Testing**
```typescript
// Test form submission
await page.fill('#username', 'testuser');
await page.fill('#password', 'testpass');
await page.click('#login-button');
```

### **Screenshot Generation**
```typescript
// Full page screenshot
await page.screenshot({ 
  path: 'fullpage.png', 
  fullPage: true 
});
```

## 🚨 **Troubleshooting**

### **If Chrome Won't Start**
```bash
# Check system status
./status.sh

# Repair installation
./setup.sh --repair

# Force cleanup and restart
./stop.sh --force
./start.sh
```

### **If Port is in Use**
```bash
# Use different port
./start.sh --port 9223

# Or auto-find available port
./start.sh --auto-port
```

### **If Script Fails**
```bash
# Check Chrome is running
./status.sh

# Check script exists
./run.sh --list

# Run with specific port
./run.sh my_script.ts --port 9223
```

## 📚 **Learn More**

- **Full Documentation**: See `README.md`
- **Configuration Options**: Check `config/` directory
- **Advanced Usage**: See `CONFIGURATION_EXAMPLES.md`
- **Performance Tuning**: See `OPTIMIZATION_GUIDE.md`

## 🎉 **Success!**

You're now ready to build powerful web automation with Chrome headless. The setup provides:

- ✅ Production-ready Chrome environment
- ✅ CPU-optimized configurations
- ✅ Multi-instance support
- ✅ Comprehensive monitoring
- ✅ Easy script management

Happy automating! 🤖
