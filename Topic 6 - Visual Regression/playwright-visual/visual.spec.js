const { test, expect } = require('@playwright/test');

test.describe('Visual Regression Testing @visual', () => {

  test('VIS01: Homepage visual screenshot in light theme', async ({ page }) => {
    await page.goto('/');
    // Hide the live clock/date as it changes every second, which would cause screenshot mismatch!
    await page.evaluate(() => {
      const liveDate = document.getElementById('liveDate');
      if (liveDate) liveDate.innerText = 'Thursday, 11 June 2026';
    });
    
    // Compare homepage screenshot
    await expect(page).toHaveScreenshot('homepage-light.png', {
      maxDiffPixelRatio: 0.02, // Allow minor rendering differences
    });
  });

  test('VIS02: Homepage visual screenshot in dark theme', async ({ page }) => {
    await page.goto('/');
    // Change theme to dark
    await page.click('#themeButton');
    
    // Hide live clock/date
    await page.evaluate(() => {
      const liveDate = document.getElementById('liveDate');
      if (liveDate) liveDate.innerText = 'Thursday, 11 June 2026';
    });
    
    // Compare dark homepage screenshot
    await expect(page).toHaveScreenshot('homepage-dark.png', {
      maxDiffPixelRatio: 0.02,
    });
  });
});
