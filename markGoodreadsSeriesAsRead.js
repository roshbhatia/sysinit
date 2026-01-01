const { chromium } = require('playwright');

async function markSeriesAsRead(seriesUrl) {
  const browser = await chromium.launch({ headless: true }); // Set to true for headless
  const page = await browser.newPage();
  
  try {
    console.log(`Navigating to ${seriesUrl}`);
    await page.goto(seriesUrl);
    await page.waitForLoadState('networkidle');
    
    // Wait for books to load
    await page.waitForSelector('.book');
    
    let booksProcessed = 0;
    const maxBooks = 50; // Safety limit to avoid infinite loops
    
    while (booksProcessed < maxBooks) {
      // Find the next "Want to Read" button
      const wantToReadButton = await page.locator('button:has-text("Want to Read")').first();
      if (!await wantToReadButton.isVisible()) {
        console.log('No more "Want to Read" buttons found.');
        break;
      }
      
      // Click the "Want to Read" button to open the menu (it's actually the shelving trigger)
      await wantToReadButton.click();
      await page.waitForTimeout(500); // Brief wait for menu to open
      
      // Click the "Read" option in the menu
      const readOption = await page.locator('button:has-text("Read")').first();
      if (await readOption.isVisible()) {
        await readOption.click();
        console.log(`Marked book ${booksProcessed + 1} as Read`);
      } else {
        console.log(`Could not find Read option for book ${booksProcessed + 1}`);
      }
      
      // Wait before next action
      await page.waitForTimeout(1000);
      booksProcessed++;
    }
    
    console.log(`Finished processing ${booksProcessed} books.`);
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await browser.close();
  }
}

// Usage: node markGoodreadsSeriesAsRead.js
const seriesUrl = process.argv[2] || 'https://www.goodreads.com/series/69255-vagabond'; // Pass URL as argument
markSeriesAsRead(seriesUrl);