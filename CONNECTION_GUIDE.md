# 🔌 Chrome Connection Guide

## ❌ **The Error You're Seeing**
```
Error: browserType.connectOverCDP: connect ECONNREFUSED 35.197.149.222:9222
```

## 🔍 **Why This Happens**
You're trying to connect to **port 9222** externally, but Chrome only binds to `localhost:9222` for security reasons.

## ✅ **SOLUTION: Use Port 9223**

### **🎯 Correct Connection URLs:**

| Connection Type | URL | Status |
|----------------|-----|---------|
| ❌ **Wrong** | `http://35.197.149.222:9222` | BLOCKED (Chrome security) |
| ✅ **Correct** | `http://35.197.149.222:9223` | WORKS (socat forwarding) |

### **🔧 Fix Your Code:**

#### **For Playwright:**
```javascript
// ❌ Wrong - will fail
const browser = await playwright.chromium.connectOverCDP('http://35.197.149.222:9222');

// ✅ Correct - will work
const browser = await playwright.chromium.connectOverCDP('http://35.197.149.222:9223');
```

#### **For Puppeteer:**
```javascript
// ❌ Wrong - will fail
const browser = await puppeteer.connect({ browserURL: 'http://35.197.149.222:9222' });

// ✅ Correct - will work
const browser = await puppeteer.connect({ browserURL: 'http://35.197.149.222:9223' });
```

#### **For Deno Scripts:**
```typescript
// ❌ Wrong
const browserURL = 'http://35.197.149.222:9222';

// ✅ Correct
const browserURL = 'http://35.197.149.222:9223';
```

## 🧪 **Test the Connection:**

```bash
# Test from external server
curl http://35.197.149.222:9223/json/version

# Should return Chrome version info
```
