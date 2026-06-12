const { test, expect } = require('@playwright/test');

test.describe('Web E2E Testing @e2e', () => {

  test.beforeEach(async ({ page }) => {
    // Navigate to the app home page and wait for it to load
    await page.goto('http://localhost:4173');
  });

  test('E2E01: Happy path flow @e2e', async ({ page }) => {
    // Page title or heading contains "DateTimeChecker" or "Date Time Checker"
    await expect(page).toHaveTitle(/Date Time Checker/i);
    await expect(page.getByRole('heading', { name: 'Date Time Checker' })).toBeVisible();

    // Three input fields are visible (Day, Month, Year)
    const dayInput = page.getByLabel('Day');
    const monthInput = page.getByLabel('Month');
    const yearInput = page.getByLabel('Year');
    await expect(dayInput).toBeVisible();
    await expect(monthInput).toBeVisible();
    await expect(yearInput).toBeVisible();

    // Check button is visible
    const checkBtn = page.getByRole('button', { name: 'Check', exact: true });
    await expect(checkBtn).toBeVisible();

    // Enter day="15", month="6", year="2023"
    await dayInput.fill('15');
    await monthInput.fill('6');
    await yearInput.fill('2023');

    // Click Check button
    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/') && response.status() === 200
    );
    await checkBtn.click();
    
    // Result appears within 1000ms (use expect with timeout on the response or element)
    const response = await responsePromise;
    const json = await response.json();
    
    // Result message contains "VALID"
    expect(json.result).toBe('VALID');

    // Verify dialog shows correct validation result
    const messageBoxText = page.getByText('is correct date time!');
    await expect(messageBoxText).toBeVisible({ timeout: 1000 });

    // Dismiss dialog to clean up state
    await page.getByRole('button', { name: 'OK', exact: true }).click();
  });

  test('E2E02: Invalid date flow @e2e', async ({ page }) => {
    await page.getByLabel('Day').fill('29');
    await page.getByLabel('Month').fill('2');
    await page.getByLabel('Year').fill('2023');

    const checkBtn = page.getByRole('button', { name: 'Check', exact: true });
    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/') && response.status() === 200
    );
    await checkBtn.click();
    
    const response = await responsePromise;
    const json = await response.json();
    
    // Result contains "INVALID"
    expect(json.result).toBe('INVALID');

    // Verify UI confirmation
    await expect(page.getByText('is NOT correct date time!')).toBeVisible({ timeout: 1000 });

    // Dismiss dialog
    await page.getByRole('button', { name: 'OK', exact: true }).click();
  });

  test('E2E03: Out-of-range validation @e2e', async ({ page }) => {
    await page.getByLabel('Day').fill('32');
    await page.getByLabel('Month').fill('1');
    await page.getByLabel('Year').fill('2023');

    const checkBtn = page.getByRole('button', { name: 'Check', exact: true });
    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/') && response.status() === 200
    );
    await checkBtn.click();
    
    const response = await responsePromise;
    const json = await response.json();
    
    expect(json.result).toBe('ERROR');

    // Error message appears (contains "range" or "invalid" or shows an error style)
    await expect(page.getByText('is out of range', { exact: false })).toBeVisible({ timeout: 1000 });
    await expect(page.getByText('Error', { exact: true })).toBeVisible();

    // Dismiss dialog
    await page.getByRole('button', { name: 'OK', exact: true }).click();
  });

  test('E2E04: Non-numeric validation @e2e', async ({ page }) => {
    await page.getByLabel('Day').fill('abc');
    await page.getByLabel('Month').fill('1');
    await page.getByLabel('Year').fill('2023');

    const checkBtn = page.getByRole('button', { name: 'Check', exact: true });
    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/') && response.status() === 200
    );
    await checkBtn.click();
    
    const response = await responsePromise;
    const json = await response.json();
    
    expect(json.result).toBe('ERROR');

    // Error message appears (contains "format" or "invalid" style)
    await expect(page.getByText('incorrect format', { exact: false })).toBeVisible({ timeout: 1000 });
    await expect(page.getByText('Error', { exact: true })).toBeVisible();

    // Dismiss dialog
    await page.getByRole('button', { name: 'OK', exact: true }).click();
  });

  test('E2E05: Close/Exit modal @e2e', async ({ page }) => {
    // Click the close button (X button, top-right)
    const closeBtn = page.getByRole('button', { name: 'Close App' });
    await closeBtn.click();

    // A confirmation dialog appears with "Yes" and "No" options
    const confirmationText = page.getByText('Bạn có chắc chắn muốn đóng ứng dụng DateTimeChecker?');
    await expect(confirmationText).toBeVisible();

    const noBtn = page.getByRole('button', { name: 'No', exact: true });
    const yesBtn = page.getByRole('button', { name: 'Yes', exact: true });
    await expect(noBtn).toBeVisible();
    await expect(yesBtn).toBeVisible();

    // Click "No" → dialog closes, application still visible
    await noBtn.click();
    await expect(confirmationText).toBeHidden();
    await expect(page.getByLabel('Day')).toBeVisible();

    // Click close button again
    await closeBtn.click();
    await expect(confirmationText).toBeVisible();

    // Click "Yes" → application closes (or redirects to a closed state)
    await yesBtn.click();
    await expect(page.getByText('Ứng dụng đã đóng')).toBeVisible();
  });

  test('E2E06: Boundary: minimum valid date @e2e', async ({ page }) => {
    await page.getByLabel('Day').fill('1');
    await page.getByLabel('Month').fill('1');
    await page.getByLabel('Year').fill('1000');

    const checkBtn = page.getByRole('button', { name: 'Check', exact: true });
    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/') && response.status() === 200
    );
    await checkBtn.click();
    
    const response = await responsePromise;
    const json = await response.json();
    
    expect(json.result).toBe('VALID');
    await expect(page.getByText('is correct date time!')).toBeVisible({ timeout: 1000 });

    // Dismiss dialog
    await page.getByRole('button', { name: 'OK', exact: true }).click();
  });

  test('E2E07: Boundary: maximum valid date @e2e', async ({ page }) => {
    await page.getByLabel('Day').fill('31');
    await page.getByLabel('Month').fill('12');
    await page.getByLabel('Year').fill('3000');

    const checkBtn = page.getByRole('button', { name: 'Check', exact: true });
    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/') && response.status() === 200
    );
    await checkBtn.click();
    
    const response = await responsePromise;
    const json = await response.json();
    
    expect(json.result).toBe('VALID');
    await expect(page.getByText('is correct date time!')).toBeVisible({ timeout: 1000 });

    // Dismiss dialog
    await page.getByRole('button', { name: 'OK', exact: true }).click();
  });

  test('E2E08: Leap year visual confirmation - 2000 @e2e', async ({ page }) => {
    await page.getByLabel('Day').fill('29');
    await page.getByLabel('Month').fill('2');
    await page.getByLabel('Year').fill('2000');

    const checkBtn = page.getByRole('button', { name: 'Check', exact: true });
    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/') && response.status() === 200
    );
    await checkBtn.click();
    
    const response = await responsePromise;
    const json = await response.json();
    
    expect(json.result).toBe('VALID');
    await expect(page.getByText('is correct date time!')).toBeVisible({ timeout: 1000 });

    // Dismiss dialog
    await page.getByRole('button', { name: 'OK', exact: true }).click();
  });

  test('E2E09: Leap year visual confirmation - 1900 @e2e', async ({ page }) => {
    await page.getByLabel('Day').fill('29');
    await page.getByLabel('Month').fill('2');
    await page.getByLabel('Year').fill('1900');

    const checkBtn = page.getByRole('button', { name: 'Check', exact: true });
    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/') && response.status() === 200
    );
    await checkBtn.click();
    
    const response = await responsePromise;
    const json = await response.json();
    
    expect(json.result).toBe('INVALID');
    await expect(page.getByText('is NOT correct date time!')).toBeVisible({ timeout: 1000 });

    // Dismiss dialog
    await page.getByRole('button', { name: 'OK', exact: true }).click();
  });

});
