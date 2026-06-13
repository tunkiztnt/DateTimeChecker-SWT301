const fs = require('fs');
const path = require('path');
const { test, expect } = require('@playwright/test');

const strictMessageChecks = process.env.AI_STRICT_MESSAGE === '1';

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

const { testcasePath, parsed: aiCases } = loadTestcases();

test.describe('AI Generated API Testing @ai-generated', () => {
  test.beforeAll(() => {
    console.log(`[AI TESTCASES] Loaded ${aiCases.length} cases from ${testcasePath}`);
    if (!strictMessageChecks) {
      console.log('[AI TESTCASES] Free-form error message checks are skipped by default for demo stability.');
    }
  });

  for (const testCase of aiCases) {
    test(`${testCase.id}: ${testCase.name} @ai-generated`, async ({ request }) => {
      const response = await request.post('/api/check-date', {
        data: {
          day: String(testCase.day),
          month: String(testCase.month),
          year: String(testCase.year),
        },
      });

      expect(response.status()).toBe(200);
      const json = await response.json();

      if (typeof testCase.expectedValid === 'boolean') {
        expect(json.valid).toBe(testCase.expectedValid);
      }

      if (testCase.expectedResult) {
        expect(json.result).toBe(testCase.expectedResult);
      }

      if (testCase.expectedDisplay && json.details) {
        expect(json.details.display).toBe(testCase.expectedDisplay);
      }

      if (strictMessageChecks && testCase.expectedMessageIncludes) {
        const haystack = JSON.stringify(json).toLowerCase();
        expect(haystack).toContain(String(testCase.expectedMessageIncludes).toLowerCase());
      }
    });
  }
});
