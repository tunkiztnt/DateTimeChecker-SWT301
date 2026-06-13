const fs = require('fs');
const path = require('path');
const { test, expect } = require('@playwright/test');

const reportPath = process.env.AI_TEST_REPORT_PATH
  ? path.resolve(process.env.AI_TEST_REPORT_PATH)
  : path.resolve(__dirname, '..', '..', 'reports', 'ai-generated-e2e-report.csv');
const stepDelayMs = Number(process.env.AI_E2E_STEP_DELAY_MS || '0');

function loadTestcases() {
  const fallbackPath = path.resolve(__dirname, '..', '..', 'reports', 'ai-generated-testcases.json');
  const testcasePath = process.env.AI_TESTCASE_FILE
    ? path.resolve(process.env.AI_TESTCASE_FILE)
    : fallbackPath;

  if (!fs.existsSync(testcasePath)) {
    throw new Error(
      `AI testcase file not found: ${testcasePath}. Generate it first with scripts/generate-ai-testcases.ps1.`,
    );
  }

  const raw = fs.readFileSync(testcasePath, 'utf8');
  const parsed = JSON.parse(raw);
  if (!Array.isArray(parsed) || parsed.length === 0) {
    throw new Error(`AI testcase file is empty or invalid: ${testcasePath}`);
  }
  return { testcasePath, parsed };
}

function isNumericText(value) {
  return /^\d+$/.test(String(value ?? '').trim());
}

function deriveExpectedModal(testCase) {
  const day = String(testCase.day ?? '').trim();
  const month = String(testCase.month ?? '').trim();
  const year = String(testCase.year ?? '').trim();

  if (!isNumericText(day)) {
    return 'Day is incorrect format!';
  }
  if (!isNumericText(month)) {
    return 'Month is incorrect format!';
  }
  if (!isNumericText(year)) {
    return 'Year is incorrect format!';
  }

  const dayNumber = Number(day);
  const monthNumber = Number(month);
  const yearNumber = Number(year);

  if (dayNumber < 1 || dayNumber > 31) {
    return 'Day is out of range!';
  }
  if (monthNumber < 1 || monthNumber > 12) {
    return 'Month is out of range!';
  }
  if (yearNumber < 1000 || yearNumber > 3000) {
    return 'Year is out of range!';
  }

  if (String(testCase.expectedResult).toUpperCase() === 'VALID') {
    return 'is correct date time!';
  }

  if (String(testCase.expectedResult).toUpperCase() === 'INVALID') {
    return 'is NOT correct date time!';
  }

  return null;
}

const { testcasePath, parsed: aiCases } = loadTestcases();

function ensureReportFile() {
  const reportDir = path.dirname(reportPath);
  fs.mkdirSync(reportDir, { recursive: true });
  if (!fs.existsSync(reportPath) || fs.statSync(reportPath).size === 0) {
    fs.writeFileSync(
      reportPath,
      'timestamp,id,name,testType,day,month,year,expectedResult,actualResult,expectedValid,actualValid,status,note\n',
      'utf8',
    );
  }
}

function escapeCsv(value) {
  const text = String(value ?? '').replace(/\r?\n/g, ' ');
  if (text.includes('"') || text.includes(',') || text.includes('\n')) {
    return `"${text.replace(/"/g, '""')}"`;
  }
  return text;
}

function appendReportRow(row) {
  const ordered = [
    row.timestamp,
    row.id,
    row.name,
    row.testType,
    row.day,
    row.month,
    row.year,
    row.expectedResult,
    row.actualResult,
    row.expectedValid,
    row.actualValid,
    row.status,
    row.note,
  ];
  const sanitized = ordered.map(escapeCsv);
  fs.appendFileSync(reportPath, `${sanitized.join(',')}\n`, 'utf8');
}

async function pause(page) {
  if (stepDelayMs > 0) {
    await page.waitForTimeout(stepDelayMs);
  }
}

test.describe('AI Generated Web E2E Testing @ai-generated-e2e', () => {
  test.beforeAll(() => {
    console.log(`[AI TESTCASES] Loaded ${aiCases.length} UI cases from ${testcasePath}`);
    ensureReportFile();
    console.log(`[AI TESTCASES] Result report: ${reportPath}`);
  });

  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'Date Time Checker' })).toBeVisible();
  });

  for (const testCase of aiCases) {
    test(`${testCase.id}: ${testCase.name} @ai-generated-e2e`, async ({ page }) => {
      let actualJson = null;
      let status = 'PASS';
      let note = 'Execution completed successfully.';

      const dayInput = page.getByLabel('Day');
      const monthInput = page.getByLabel('Month');
      const yearInput = page.getByLabel('Year');
      const checkButton = page.getByRole('button', { name: 'Check', exact: true });

      try {
        await dayInput.fill(String(testCase.day ?? ''));
        await pause(page);
        await monthInput.fill(String(testCase.month ?? ''));
        await pause(page);
        await yearInput.fill(String(testCase.year ?? ''));
        await pause(page);

        const responsePromise = page.waitForResponse(
          response => response.url().includes('/api/') && response.status() === 200,
        );

        await checkButton.click();
        await pause(page);

        const response = await responsePromise;
        const json = await response.json();
        actualJson = json;

        expect(response.status()).toBe(200);

        if (typeof testCase.expectedValid === 'boolean') {
          expect(json.valid).toBe(testCase.expectedValid);
        }

        if (testCase.expectedResult) {
          expect(String(json.result).toUpperCase()).toBe(String(testCase.expectedResult).toUpperCase());
        }

        if (testCase.expectedDisplay && json.details) {
          expect(json.details.display).toBe(testCase.expectedDisplay);
        }

        await expect(page.locator('#winformsMessageBox')).toBeVisible({ timeout: 1500 });

        const expectedModal = deriveExpectedModal(testCase);
        if (expectedModal) {
          await expect(page.locator('#wfMbMessage')).toContainText(expectedModal);
        }
        await pause(page);

        await page.locator('#wfMbOkBtn').click();
        await expect(page.locator('#winformsMessageBox')).toBeHidden();
        await pause(page);
      } catch (error) {
        status = 'FAIL';
        note = error.message;
        throw error;
      } finally {
        appendReportRow({
          timestamp: new Date().toISOString(),
          id: testCase.id,
          name: testCase.name,
          testType: testCase.testType,
          day: testCase.day,
          month: testCase.month,
          year: testCase.year,
          expectedResult: testCase.expectedResult,
          actualResult: actualJson ? actualJson.result : '',
          expectedValid: testCase.expectedValid,
          actualValid: actualJson ? actualJson.valid : '',
          status,
          note,
        });
      }
    });
  }
});
