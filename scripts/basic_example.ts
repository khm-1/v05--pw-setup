import puppeteer from 'https://deno.land/x/puppeteer@16.2.0/mod.ts';

const browserURL = 'http://127.0.0.1:9222';

async function run() {
  let browser;
  try {
    browser = await puppeteer.connect({
      browserURL,
      defaultViewport: null, // Use the browser's default viewport
    });

    const page = await browser.newPage();

    const targetUrl = 'https://www.google.com'; // You can change this URL
    await page.goto(targetUrl, { waitUntil: 'networkidle2' });

    const title = await page.title();
    console.log(`Page Title: ${title}`);

    const screenshotPath = 'screenshot.png';
    await page.screenshot({ path: screenshotPath });
    console.log(`Screenshot saved to ${screenshotPath}`);

    const logFilePath = 'page_info.log';
    await Deno.writeTextFile(logFilePath, `URL: ${targetUrl}\nTitle: ${title}\n`);
    console.log(`Page info logged to ${logFilePath}`);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    if (browser) {
      // Disconnect from the browser, but don't close it since it was launched externally
      await browser.disconnect();
    }
  }
}

run();


