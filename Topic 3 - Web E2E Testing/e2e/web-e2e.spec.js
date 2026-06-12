const { test, expect } = require('@playwright/test');

const dateCases = [
  {
    id: 'E2E01',
    name: 'Happy path flow',
    day: '15',
    month: '6',
    year: '2023',
    expectedResult: 'VALID',
    expectedValid: true,
    expectedModal: 'is correct date time!',
    meaning: 'Normal valid date should be accepted.',
  },
  {
    id: 'E2E02',
    name: 'Invalid non-leap February date',
    day: '29',
    month: '2',
    year: '2023',
    expectedResult: 'INVALID',
    expectedValid: false,
    expectedModal: 'is NOT correct date time!',
    meaning: 'February 29 is invalid when the year is not leap.',
  },
  {
    id: 'E2E03',
    name: 'Day out of range',
    day: '32',
    month: '1',
    year: '2023',
    expectedResult: 'ERROR',
    expectedValid: false,
    expectedModal: 'Day is out of range',
    meaning: 'Day must stay inside 1-31 before date calculation.',
  },
  {
    id: 'E2E04',
    name: 'Non-numeric day format',
    day: 'abc',
    month: '1',
    year: '2023',
    expectedResult: 'ERROR',
    expectedValid: false,
    expectedModal: 'Day is incorrect format',
    meaning: 'Day must be an integer, not text.',
  },
  {
    id: 'E2E06',
    name: 'Minimum valid boundary',
    day: '1',
    month: '1',
    year: '1000',
    expectedResult: 'VALID',
    expectedValid: true,
    expectedModal: 'is correct date time!',
    meaning: 'The minimum allowed date should be accepted.',
  },
  {
    id: 'E2E07',
    name: 'Maximum valid boundary',
    day: '31',
    month: '12',
    year: '3000',
    expectedResult: 'VALID',
    expectedValid: true,
    expectedModal: 'is correct date time!',
    meaning: 'The maximum allowed date should be accepted.',
  },
  {
    id: 'E2E08',
    name: 'Leap year divisible by 400',
    day: '29',
    month: '2',
    year: '2000',
    expectedResult: 'VALID',
    expectedValid: true,
    expectedModal: 'is correct date time!',
    meaning: 'Year 2000 is a leap year because it is divisible by 400.',
  },
  {
    id: 'E2E09',
    name: 'Century year not divisible by 400',
    day: '29',
    month: '2',
    year: '1900',
    expectedResult: 'INVALID',
    expectedValid: false,
    expectedModal: 'is NOT correct date time!',
    meaning: 'Year 1900 is not leap because century years must be divisible by 400.',
  },
];

async function runDateCase(page, tc) {
  console.log('');
  console.log(`[CASE START] ${tc.id} - ${tc.name}`);
  console.log(`[MEANING] ${tc.meaning}`);
  console.log(`[INPUT] Day='${tc.day}', Month='${tc.month}', Year='${tc.year}'`);
  console.log(`[EXPECTED] API result=${tc.expectedResult}, valid=${tc.expectedValid}, modal contains='${tc.expectedModal}'`);

  await expect(page).toHaveTitle(/Date Time Checker/i);
  await expect(page.getByRole('heading', { name: 'Date Time Checker' })).toBeVisible();

  const dayInput = page.getByLabel('Day');
  const monthInput = page.getByLabel('Month');
  const yearInput = page.getByLabel('Year');
  const checkBtn = page.getByRole('button', { name: 'Check', exact: true });

  console.log(`[ACTION] ${tc.id} locate Day, Month, Year inputs and Check button.`);
  await expect(dayInput).toBeVisible();
  await expect(monthInput).toBeVisible();
  await expect(yearInput).toBeVisible();
  await expect(checkBtn).toBeVisible();

  console.log(`[ACTION] ${tc.id} fill Day='${tc.day}'.`);
  await dayInput.fill(tc.day);
  console.log(`[ACTION] ${tc.id} fill Month='${tc.month}'.`);
  await monthInput.fill(tc.month);
  console.log(`[ACTION] ${tc.id} fill Year='${tc.year}'.`);
  await yearInput.fill(tc.year);

  const responsePromise = page.waitForResponse(
    response => response.url().includes('/api/') && response.status() === 200
  );

  console.log(`[ACTION] ${tc.id} click Check and wait for HTTP response.`);
  await checkBtn.click();

  const response = await responsePromise;
  const json = await response.json();

  await expect(page.locator('#winformsMessageBox')).toBeVisible({ timeout: 1000 });
  const resultTitle = (await page.locator('#resultTitle').textContent()) || '';
  const modalTitle = (await page.locator('#wfMbTitle').textContent()) || '';
  const modalMessage = (await page.locator('#wfMbMessage').textContent()) || '';

  console.log(`[ACTUAL] ${tc.id} HTTP=${response.status()}, API result=${json.result}, valid=${json.valid}`);
  console.log(`[ACTUAL] ${tc.id} UI result title='${resultTitle.trim()}'`);
  console.log(`[ACTUAL] ${tc.id} Modal title='${modalTitle.trim()}', message='${modalMessage.trim()}'`);

  expect(json.result).toBe(tc.expectedResult);
  expect(json.valid).toBe(tc.expectedValid);
  await expect(page.locator('#wfMbMessage')).toContainText(tc.expectedModal);

  console.log(`[RESULT] ${tc.id} PASS - expected result matched actual API and visible modal.`);
  console.log(`[ACTION] ${tc.id} click OK to close result modal and prepare next case.`);
  await page.locator('#wfMbOkBtn').click();
}

test.describe('Web E2E Testing @e2e', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:4173');
  });

  for (const tc of dateCases.slice(0, 4)) {
    test(`${tc.id}: input day=${tc.day}, month=${tc.month}, year=${tc.year} -> ${tc.expectedResult} (${tc.name}) @e2e`, async ({ page }) => {
      await runDateCase(page, tc);
    });
  }

  test('E2E05: click Close App -> No keeps app open, Yes closes app @e2e', async ({ page }) => {
    console.log('');
    console.log('[CASE START] E2E05 - Close/Exit modal behavior');
    console.log('[MEANING] Verify the app asks for confirmation before closing.');
    console.log('[INPUT] Action sequence: click Close App, click No, click Close App again, click Yes.');
    console.log('[EXPECTED] No keeps the form visible; Yes replaces the app with a closed state.');

    const closeBtn = page.getByRole('button', { name: 'Close App' });
    const closeModal = page.locator('#closeModal');
    const noBtn = page.locator('#confirmCloseNo');
    const yesBtn = page.locator('#confirmCloseYes');

    console.log('[ACTION] E2E05 click Close App button.');
    await closeBtn.click();
    await expect(closeModal).toBeVisible();
    console.log('[ACTUAL] E2E05 close confirmation modal is visible.');

    console.log('[ACTION] E2E05 click No.');
    await noBtn.click();
    await expect(closeModal).toBeHidden();
    await expect(page.getByLabel('Day')).toBeVisible();
    console.log('[ACTUAL] E2E05 modal closed and main form is still visible.');

    console.log('[ACTION] E2E05 click Close App again, then click Yes.');
    await closeBtn.click();
    await expect(closeModal).toBeVisible();
    await yesBtn.click();

    await expect(page.locator('#checkerForm')).toHaveCount(0);
    const closedTitle = (await page.locator('.app-shell h2').textContent()) || '';
    console.log(`[ACTUAL] E2E05 app closed title='${closedTitle.trim()}'.`);
    console.log('[RESULT] E2E05 PASS - close confirmation behavior works.');
  });

  for (const tc of dateCases.slice(4)) {
    test(`${tc.id}: input day=${tc.day}, month=${tc.month}, year=${tc.year} -> ${tc.expectedResult} (${tc.name}) @e2e`, async ({ page }) => {
      await runDateCase(page, tc);
    });
  }
});
