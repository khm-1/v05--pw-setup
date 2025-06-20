import puppeteer from 'https://deno.land/x/puppeteer@16.2.0/mod.ts';

// Configuration
const CONFIG = {
  browserURL: 'http://127.0.0.1:9222',
  targetUrl: 'https://www.google.com',
  screenshotPath: 'screenshot.png',
  logFilePath: 'page_info.log',
  timeout: 30000, // 30 seconds
  retryAttempts: 3,
  retryDelay: 2000, // 2 seconds
};

// Utility function to wait/sleep
const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// Function to check if Chrome is accessible
async function checkChromeConnection(): Promise<boolean> {
  try {
    const response = await fetch(`${CONFIG.browserURL}/json/version`);
    return response.ok;
  } catch {
    return false;
  }
}

// Function to wait for Chrome to be ready
async function waitForChrome(): Promise<void> {
  console.log('Checking Chrome connection...');
  
  for (let attempt = 1; attempt <= CONFIG.retryAttempts; attempt++) {
    if (await checkChromeConnection()) {
      console.log('✓ Chrome is accessible');
      return;
    }
    
    if (attempt < CONFIG.retryAttempts) {
      console.log(`✗ Chrome not ready, retrying in ${CONFIG.retryDelay/1000}s... (${attempt}/${CONFIG.retryAttempts})`);
      await sleep(CONFIG.retryDelay);
    }
  }
  
  throw new Error('Chrome is not accessible. Make sure Chrome is running with remote debugging enabled.');
}

// Function to get browser info
async function getBrowserInfo(browser: any): Promise<void> {
  try {
    const version = await browser.version();
    console.log(`Browser: ${version}`);
  } catch (error) {
    console.log('Could not get browser version:', error.message);
  }
}

// Main function
async function run() {
  let browser;
  let page;
  
  try {
    // Wait for Chrome to be ready
    await waitForChrome();
    
    // Connect to Chrome
    console.log('Connecting to Chrome...');
    browser = await puppeteer.connect({
      browserURL: CONFIG.browserURL,
      defaultViewport: null,
    });
    
    console.log('✓ Connected to Chrome successfully');
    
    // Get browser info
    await getBrowserInfo(browser);
    
    // Create new page
    console.log('Creating new page...');
    page = await browser.newPage();
    
    // Set viewport for consistent screenshots
    await page.setViewport({ width: 1920, height: 1024 });
    
    // Navigate to target URL
    console.log(`Navigating to: ${CONFIG.targetUrl}`);
    await page.goto(CONFIG.targetUrl, { 
      waitUntil: 'networkidle2',
      timeout: CONFIG.timeout 
    });
    
    // Get page information
    const title = await page.title();
    const url = page.url();
    
    console.log(`✓ Page loaded successfully`);
    console.log(`  Title: ${title}`);
    console.log(`  URL: ${url}`);
    
    // Take screenshot
    console.log('Taking screenshot...');
    await page.screenshot({ 
      path: CONFIG.screenshotPath,
      fullPage: false,
      type: 'png'
    });
    console.log(`✓ Screenshot saved to ${CONFIG.screenshotPath}`);
    
    // Log page information
    const logContent = [
      `Timestamp: ${new Date().toISOString()}`,
      `URL: ${url}`,
      `Title: ${title}`,
      `Screenshot: ${CONFIG.screenshotPath}`,
      `User Agent: ${await page.evaluate(() => navigator.userAgent)}`,
      ''
    ].join('\n');
    
    await Deno.writeTextFile(CONFIG.logFilePath, logContent);
    console.log(`✓ Page info logged to ${CONFIG.logFilePath}`);
    
    // Optional: Get page metrics
    try {
      const metrics = await page.metrics();
      console.log('Page Metrics:');
      console.log(`  DOM Nodes: ${metrics.Nodes}`);
      console.log(`  JS Event Listeners: ${metrics.JSEventListeners}`);
      console.log(`  Layout Duration: ${metrics.LayoutDuration}ms`);
    } catch (error) {
      console.log('Could not get page metrics:', error.message);
    }
    
    console.log('\n✓ All tasks completed successfully!');
    
  } catch (error) {
    console.error('\n✗ Error occurred:');
    console.error(`  ${error.message}`);
    
    if (error.message.includes('Navigation timeout')) {
      console.error('  Suggestion: The page took too long to load. Try increasing the timeout or check your internet connection.');
    } else if (error.message.includes('Chrome is not accessible')) {
      console.error('  Suggestion: Run "./run_chrome_remote.sh start" first to start Chrome with remote debugging.');
    }
    
    Deno.exit(1);
    
  } finally {
    // Cleanup
    try {
      if (page) {
        await page.close();
        console.log('Page closed');
      }
    } catch (error) {
      console.log('Error closing page:', error.message);
    }
    
    try {
      if (browser) {
        // Disconnect from browser (don't close it since it was launched externally)
        await browser.disconnect();
        console.log('Disconnected from browser');
      }
    } catch (error) {
      console.log('Error disconnecting from browser:', error.message);
    }
  }
}

// Handle Ctrl+C gracefully
Deno.addSignalListener("SIGINT", () => {
  console.log('\nReceived SIGINT, exiting gracefully...');
  Deno.exit(0);
});

// Run the main function
if (import.meta.main) {
  run();
}
