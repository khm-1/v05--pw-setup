const puppeteer = require('playwright');

async function testConnection() {
    console.log('Testing Node.js connection to Chrome on port 9222...');
    
    try {
        // Connect to Chrome using CDP
        const browser = await puppeteer.chromium.connectOverCDP('http://localhost:9222');
        console.log('✓ Successfully connected to Chrome!');
        
        // Get browser version
        const version = await browser.version();
        console.log(`Browser version: ${version}`);
        
        // Create a new page
        const page = await browser.newPage();
        console.log('✓ Created new page');
        
        // Navigate to a test URL
        await page.goto('https://www.google.com', { waitUntil: 'networkidle' });
        console.log('✓ Successfully navigated to Google');
        
        // Get page title
        const title = await page.title();
        console.log(`Page title: ${title}`);
        
        // Take a screenshot
        await page.screenshot({ path: 'nodejs_test_screenshot.png' });
        console.log('✓ Screenshot saved as nodejs_test_screenshot.png');
        
        // Close page and disconnect
        await page.close();
        await browser.close();
        
        console.log('\n🎉 All tests passed! Node.js can successfully connect to Chrome on port 9222');
        
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

testConnection();
