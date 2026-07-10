const { test, expect } = require('@playwright/test');

test.describe('Topic 2: Web E2E Verification - Standard Selectors', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('E2E - Validate a valid date input and verify popup content', async ({ page }) => {
    await page.fill('#day', '15');
    await page.fill('#month', '6');
    await page.fill('#year', '2026');
    await page.click('button[type="submit"]');

    // WinForms message box popup verification
    const msgBox = page.locator('#winformsMessageBox');
    await expect(msgBox).toBeVisible();
    await expect(page.locator('#wfMbMessage')).toHaveText('15/06/2026 is correct date time!');
    
    // Close message box
    await page.click('#wfMbOkBtn');
    await expect(msgBox).not.toBeVisible();
  });

  test('E2E - Validate an invalid date and verify error popup content', async ({ page }) => {
    await page.fill('#day', '31');
    await page.fill('#month', '4'); // April has only 30 days
    await page.fill('#year', '2026');
    await page.click('button[type="submit"]');

    const msgBox = page.locator('#winformsMessageBox');
    await expect(msgBox).toBeVisible();
    await expect(page.locator('#wfMbMessage')).toHaveText('31/04/2026 is NOT correct date time!');
    
    await page.click('#wfMbOkBtn');
  });

  test('E2E - Clear button resets all input fields and results', async ({ page }) => {
    await page.fill('#day', '25');
    await page.fill('#month', '12');
    await page.fill('#year', '2025');

    await page.click('#clearButton');

    await expect(page.locator('#day')).toHaveValue('');
    await expect(page.locator('#month')).toHaveValue('');
    await expect(page.locator('#year')).toHaveValue('');
  });

  test('E2E - Use Today button populates current date', async ({ page }) => {
    await page.click('#nowButton');

    const today = new Date();
    await expect(page.locator('#day')).toHaveValue(today.getDate().toString());
    await expect(page.locator('#month')).toHaveValue((today.getMonth() + 1).toString());
    await expect(page.locator('#year')).toHaveValue(today.getFullYear().toString());
  });

  test('E2E - Close confirmation modal exits application state', async ({ page }) => {
    await page.click('#closeButton');
    
    // Check confirmation modal visibility
    const modal = page.locator('#closeModal');
    await expect(modal).toBeVisible();

    // Click No should close modal
    await page.click('#confirmCloseNo');
    await expect(modal).not.toBeVisible();

    // Click Yes should exit application UI
    await page.click('#closeButton');
    await page.click('#confirmCloseYes');
    await expect(page.locator('text=Application closed')).toBeVisible();
  });
});
