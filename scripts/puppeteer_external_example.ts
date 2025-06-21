// Puppeteer Deno external connection example
import puppeteer from 'https://deno.land/x/puppeteer@16.2.0/mod.ts';

async function connectToExternalChrome() {
  try {
    // ✅ Correct: Use port 9223 for external access
    const browser = await puppeteer.connect({ 
      browserURL: 'http://35.197.149.222:9223' 
    });
    
    console.log('✅ Connected to external Chrome successfully!');
    
    const page = await browser.newPage();
    await page.goto('https://example.com');
    
    const title = await page.title();
    console.log('Page title:', title);
    
    await page.screenshot({ path: 'external_screenshot.png' });
    console.log('Screenshot saved: external_screenshot.png');
    
    await browser.disconnect();
    
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    console.log('');
    console.log('💡 Make sure you are using the correct port:');
    console.log('   ✅ Correct: http://35.197.149.222:9223');
    console.log('   ❌ Wrong:   http://35.197.149.222:9222');
  }
}

connectToExternalChrome();
