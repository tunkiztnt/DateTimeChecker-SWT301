const { test, expect } = require('@playwright/test');

test.describe('Web E2E Testing @e2e', () => {

  test.beforeEach(async ({ page }) => {
    // Navigate to the app home page
    await page.goto('/');
  });

  test('E2E01: Successfully validates a correct date and shows details', async ({ page }) => {
    // Fill the form
    await page.fill('#day', '30');
    await page.fill('#month', '5');
    await page.fill('#year', '2026');

    // Click Check
    await page.click('button[type="submit"]');

    // Verify result card and title
    const resultTitle = page.locator('#resultTitle');
    await expect(resultTitle).toBeVisible();
    await expect(resultTitle).toHaveText('Ngày hợp lệ');

    // Verify display message
    const resultMessage = page.locator('#resultMessage');
    await expect(resultMessage).toContainText('30/05/2026 là một ngày hợp lệ');

    // Verify detail grid
    const detailGrid = page.locator('#detailGrid');
    await expect(detailGrid).toContainText('Thứ bảy'); // 30 May 2026 is Saturday (Thứ bảy)
    await expect(detailGrid).toContainText('Năm nhuậnKhông');
    await expect(detailGrid).toContainText('Số ngày trong tháng31');
  });

  test('E2E02: Fails validation on invalid day and displays error message', async ({ page }) => {
    await page.fill('#day', '31');
    await page.fill('#month', '4');
    await page.fill('#year', '2026');
    await page.click('button[type="submit"]');

    const resultTitle = page.locator('#resultTitle');
    await expect(resultTitle).toHaveText('Ngày không hợp lệ');

    const errorList = page.locator('#errorList');
    await expect(errorList).toBeVisible();
    await expect(errorList).toContainText('Tháng 4 năm 2026 chỉ có 30 ngày');
  });

  test('E2E03: "Clear" button resets the form and hides results', async ({ page }) => {
    await page.fill('#day', '30');
    await page.fill('#month', '5');
    await page.fill('#year', '2026');
    await page.click('button[type="submit"]');

    // Ensure results are visible
    await expect(page.locator('#resultContent')).toBeVisible();

    // Click Clear
    await page.click('#clearButton');

    // Verify inputs are empty
    await expect(page.locator('#day')).toHaveValue('');
    await expect(page.locator('#month')).toHaveValue('');
    await expect(page.locator('#year')).toHaveValue('');

    // Verify results card shows empty state again
    await expect(page.locator('#emptyState')).toBeVisible();
    await expect(page.locator('#resultContent')).toBeHidden();
  });

  test('E2E04: "Use Today" button inputs current date and validates', async ({ page }) => {
    await page.click('#nowButton');

    const resultTitle = page.locator('#resultTitle');
    await expect(resultTitle).toHaveText('Ngày hợp lệ');

    // Verify inputs are not empty
    const dayVal = await page.inputValue('#day');
    const monthVal = await page.inputValue('#month');
    const yearVal = await page.inputValue('#year');

    expect(dayVal).not.toBe('');
    expect(monthVal).not.toBe('');
    expect(yearVal).not.toBe('');
  });

  test('E2E05: Theme toggler switches dark/light mode', async ({ page }) => {
    // Check default theme is light
    const html = page.locator('html');
    await expect(html).toHaveAttribute('data-theme', 'light');

    // Click theme button
    await page.click('#themeButton');
    await expect(html).toHaveAttribute('data-theme', 'dark');

    // Click theme button again
    await page.click('#themeButton');
    await expect(html).toHaveAttribute('data-theme', 'light');
  });
});
