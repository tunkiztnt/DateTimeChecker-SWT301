const { test, expect } = require('@playwright/test');

test.describe('Visual Regression Testing @visual', () => {

  test.beforeEach(async ({ page }) => {
    // Navigate to the app home page
    await page.goto('/');
    
    // Stabilize the clock to prevent screenshot mismatches due to live date changing
    await page.evaluate(() => {
      const liveDate = document.getElementById('liveDate');
      if (liveDate) {
        liveDate.innerText = 'Thursday, 11 June 2026';
      }
    });
  });

  test('State 1 @visual: empty-form', async ({ page }) => {
    // State 1: empty-form — page just loaded, all inputs empty
    await expect(page).toHaveScreenshot('empty-form.png', {
      maxDiffPixels: 100,        // allow minor rendering differences
      threshold: 0.1,            // 10% pixel tolerance
      animations: 'disabled'     // disable CSS animations for stable screenshots
    });
  });

  test('State 2 @visual: valid-input-entered', async ({ page }) => {
    // State 2: valid-input-entered — filled with 15/06/2023, before clicking Check
    await page.getByLabel('Day').fill('15');
    await page.getByLabel('Month').fill('6');
    await page.getByLabel('Year').fill('2023');

    await expect(page).toHaveScreenshot('valid-input-entered.png', {
      maxDiffPixels: 100,        // allow minor rendering differences
      threshold: 0.1,            // 10% pixel tolerance
      animations: 'disabled'     // disable CSS animations for stable screenshots
    });
  });

  test('State 3 @visual: valid-result', async ({ page }) => {
    // State 3: valid-result — after clicking Check with valid date, shows VALID
    await page.getByLabel('Day').fill('15');
    await page.getByLabel('Month').fill('6');
    await page.getByLabel('Year').fill('2023');

    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/') && response.status() === 200
    );
    await page.getByRole('button', { name: 'Check', exact: true }).click();
    await responsePromise;

    // Settle dynamic rendering of modal/UI
    await page.waitForTimeout(500);

    await expect(page).toHaveScreenshot('valid-result.png', {
      maxDiffPixels: 100,        // allow minor rendering differences
      threshold: 0.1,            // 10% pixel tolerance
      animations: 'disabled'     // disable CSS animations for stable screenshots
    });
  });

  test('State 4 @visual: invalid-result', async ({ page }) => {
    // State 4: invalid-result — after clicking Check with 29/02/2023, shows INVALID
    await page.getByLabel('Day').fill('29');
    await page.getByLabel('Month').fill('2');
    await page.getByLabel('Year').fill('2023');

    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/') && response.status() === 200
    );
    await page.getByRole('button', { name: 'Check', exact: true }).click();
    await responsePromise;

    // Settle dynamic rendering of modal/UI
    await page.waitForTimeout(500);

    await expect(page).toHaveScreenshot('invalid-result.png', {
      maxDiffPixels: 100,        // allow minor rendering differences
      threshold: 0.1,            // 10% pixel tolerance
      animations: 'disabled'     // disable CSS animations for stable screenshots
    });
  });

  test('State 5 @visual: error-state', async ({ page }) => {
    // State 5: error-state — after clicking Check with day="abc", shows error
    await page.getByLabel('Day').fill('abc');
    await page.getByLabel('Month').fill('1');
    await page.getByLabel('Year').fill('2023');

    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/') && response.status() === 200
    );
    await page.getByRole('button', { name: 'Check', exact: true }).click();
    await responsePromise;

    // Settle dynamic rendering of modal/UI
    await page.waitForTimeout(500);

    await expect(page).toHaveScreenshot('error-state.png', {
      maxDiffPixels: 100,        // allow minor rendering differences
      threshold: 0.1,            // 10% pixel tolerance
      animations: 'disabled'     // disable CSS animations for stable screenshots
    });
  });

});
