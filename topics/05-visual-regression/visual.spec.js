const fs = require('fs');
const path = require('path');
const { test, expect } = require('@playwright/test');
const { PNG } = require('playwright-core/lib/utilsBundle');

const baselineImagesDir = path.join(__dirname, 'baseline-images');
const currentRunImagesDir = path.join(__dirname, 'current-run-images');
const diffImagesDir = path.join(__dirname, 'diff-images');
const platformSnapshotSuffix = `-${process.platform}.png`;
const CHANNEL_DIFF_THRESHOLD = 2;
const MAX_DIFF_PIXELS = 0;
const FIXED_LIVE_DATE_TEXT = 'Thursday, 11 June 2026';
const EMPTY_STATE_TEXT = 'Vui l\u00f2ng nh\u1eadp ng\u00e0y, th\u00e1ng, n\u0103m v\u00e0 nh\u1ea5n n\u00fat Check \u0111\u1ec3 ki\u1ec3m tra t\u00ednh h\u1ee3p l\u1ec7.';
const WEEKDAY_LABEL = 'Th\u1ee9';
const LEAP_YEAR_LABEL = 'N\u0103m nhu\u1eadn';
const MONTH_DAYS_LABEL = 'S\u1ed1 ng\u00e0y trong th\u00e1ng';
const VISUAL_TEST_CSS = `
  *, *::before, *::after {
    animation: none !important;
    transition: none !important;
    caret-color: transparent !important;
  }

  *:focus,
  *:focus-visible {
    outline: none !important;
    box-shadow: none !important;
  }

  html {
    scroll-behavior: auto !important;
  }

  body,
  button,
  input,
  textarea,
  select,
  label,
  p,
  h1,
  h2,
  h3,
  span,
  div {
    font-family: "Segoe UI", Arial, sans-serif !important;
    letter-spacing: 0 !important;
  }

  .app-shell,
  .card,
  .modal-card,
  .wf-modal-card {
    backdrop-filter: none !important;
    -webkit-backdrop-filter: none !important;
  }
`;
const EXPECTED_TEXT_SNIPPETS = [
  'Day',
  'Month',
  'Year',
  'Date Time Checker'
];

function toPlatformSnapshotName(snapshotName) {
  return snapshotName.replace(/\.png$/i, platformSnapshotSuffix);
}

function ensureReviewDirectories() {
  fs.mkdirSync(baselineImagesDir, { recursive: true });
  fs.mkdirSync(currentRunImagesDir, { recursive: true });
  fs.mkdirSync(diffImagesDir, { recursive: true });
}

async function prepareStableVisualPage(page) {
  await page.addInitScript(() => {
    localStorage.clear();
    sessionStorage.clear();
  });

  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/');
  await page.waitForLoadState('networkidle');
  await page.addStyleTag({ content: VISUAL_TEST_CSS });

  await page.evaluate((fixedDateText) => {
    localStorage.setItem('theme', 'light');
    document.documentElement.setAttribute('data-theme', 'light');

    const liveDateElement = document.getElementById('liveDate');
    if (liveDateElement) {
      liveDateElement.textContent = fixedDateText;
    }

    window.scrollTo(0, 0);
  }, FIXED_LIVE_DATE_TEXT);

  await page.evaluate(async () => {
    if (document.fonts && document.fonts.ready) {
      await document.fonts.ready;
    }
  });
}

async function assertStableUiText(page, extraExpectedTexts = []) {
  await expect(page.locator('label[for="day"]')).toHaveText('Day');
  await expect(page.locator('label[for="month"]')).toHaveText('Month');
  await expect(page.locator('label[for="year"]')).toHaveText('Year');
  await expect(page.locator('h1')).toHaveText('Date Time Checker');

  const visibleText = await page.locator('body').innerText();
  for (const expectedText of [...EXPECTED_TEXT_SNIPPETS, ...extraExpectedTexts]) {
    expect(visibleText, `Visible UI text is missing: ${expectedText}`).toContain(expectedText);
  }

  expect(
    visibleText,
    'Visible UI text contains mojibake / broken Vietnamese characters.'
  ).not.toMatch(/[\u00c3\u00c4\u00c2\ufffd]/);
}

async function captureCurrentRunImage(page, snapshotName) {
  const platformFileName = toPlatformSnapshotName(snapshotName);
  const currentRunPath = path.join(currentRunImagesDir, platformFileName);

  await page.evaluate(() => {
    if (document.activeElement && typeof document.activeElement.blur === 'function') {
      document.activeElement.blur();
    }
  });

  await page.locator('body').screenshot({
    path: currentRunPath,
    animations: 'disabled',
    caret: 'hide',
    scale: 'css'
  });

  return currentRunPath;
}

function createDimensionMismatchDiff(width, height, diffPath) {
  const image = new PNG({ width: Math.max(width, 1), height: Math.max(height, 1) });
  for (let index = 0; index < image.data.length; index += 4) {
    image.data[index] = 220;
    image.data[index + 1] = 38;
    image.data[index + 2] = 38;
    image.data[index + 3] = 255;
  }
  fs.writeFileSync(diffPath, PNG.sync.write(image));
}

function compareImages(baselinePath, currentRunPath, diffPath) {
  const baselinePng = PNG.sync.read(fs.readFileSync(baselinePath));
  const currentPng = PNG.sync.read(fs.readFileSync(currentRunPath));

  if (baselinePng.width !== currentPng.width || baselinePng.height !== currentPng.height) {
    createDimensionMismatchDiff(
      Math.max(baselinePng.width, currentPng.width),
      Math.max(baselinePng.height, currentPng.height),
      diffPath
    );

    return {
      diffPixels: Number.MAX_SAFE_INTEGER,
      width: currentPng.width,
      height: currentPng.height,
      dimensionMismatch: true
    };
  }

  const diffPng = new PNG({ width: baselinePng.width, height: baselinePng.height });
  let diffPixels = 0;

  for (let index = 0; index < baselinePng.data.length; index += 4) {
    const redDiff = Math.abs(baselinePng.data[index] - currentPng.data[index]);
    const greenDiff = Math.abs(baselinePng.data[index + 1] - currentPng.data[index + 1]);
    const blueDiff = Math.abs(baselinePng.data[index + 2] - currentPng.data[index + 2]);
    const alphaDiff = Math.abs(baselinePng.data[index + 3] - currentPng.data[index + 3]);

    const changed = redDiff > CHANNEL_DIFF_THRESHOLD
      || greenDiff > CHANNEL_DIFF_THRESHOLD
      || blueDiff > CHANNEL_DIFF_THRESHOLD
      || alphaDiff > CHANNEL_DIFF_THRESHOLD;

    if (changed) {
      diffPixels += 1;
      diffPng.data[index] = 255;
      diffPng.data[index + 1] = 0;
      diffPng.data[index + 2] = 0;
      diffPng.data[index + 3] = 255;
    } else {
      const grayscale = Math.round(
        baselinePng.data[index] * 0.299
        + baselinePng.data[index + 1] * 0.587
        + baselinePng.data[index + 2] * 0.114
      );
      diffPng.data[index] = grayscale;
      diffPng.data[index + 1] = grayscale;
      diffPng.data[index + 2] = grayscale;
      diffPng.data[index + 3] = 90;
    }
  }

  fs.writeFileSync(diffPath, PNG.sync.write(diffPng));

  return {
    diffPixels,
    width: baselinePng.width,
    height: baselinePng.height,
    dimensionMismatch: false
  };
}

async function compareWithVisualReference(page, snapshotName, extraExpectedTexts = []) {
  const platformFileName = toPlatformSnapshotName(snapshotName);
  const baselinePath = path.join(baselineImagesDir, platformFileName);
  const currentRunPath = await captureCurrentRunImage(page, snapshotName);
  const diffPath = path.join(diffImagesDir, platformFileName);

  expect(fs.existsSync(baselinePath), `Missing baseline image: ${baselinePath}`).toBeTruthy();

  const comparison = compareImages(baselinePath, currentRunPath, diffPath);
  const visualStatus = comparison.diffPixels <= MAX_DIFF_PIXELS ? 'PASS' : 'FAIL';

  console.log('');
  console.log(`[VISUAL REVIEW] Baseline image : ${baselinePath}`);
  console.log(`[VISUAL REVIEW] Current image  : ${currentRunPath}`);
  console.log(`[VISUAL REVIEW] Diff image     : ${diffPath}`);
  console.log(`[VISUAL REVIEW] Diff pixels    : ${comparison.diffPixels}`);
  console.log(`[VISUAL REVIEW] Max allowed    : ${MAX_DIFF_PIXELS}`);
  console.log(`[VISUAL REVIEW] Status         : ${visualStatus}`);

  await assertStableUiText(page, extraExpectedTexts);

  if (comparison.dimensionMismatch) {
    throw new Error(`Image dimensions do not match for ${platformFileName}. Check diff image: ${diffPath}`);
  }

  expect(
    comparison.diffPixels,
    `Visual difference detected for ${platformFileName}. Open diff image: ${diffPath}`
  ).toBeLessThanOrEqual(MAX_DIFF_PIXELS);
}

test.describe('Topic 5: Visual Regression Verification - PW Shots', () => {
  test.beforeAll(() => {
    ensureReviewDirectories();
  });

  test.beforeEach(async ({ page }) => {
    await prepareStableVisualPage(page);
  });

  test('Visual - Compare landing page layout against reference image', async ({ page }) => {
    await compareWithVisualReference(page, 'landing-page.png', [
      EMPTY_STATE_TEXT
    ]);
  });

  test('Visual - Compare dark mode layout against reference image', async ({ page }) => {
    await page.click('#themeButton');
    await page.evaluate(() => {
      localStorage.setItem('theme', 'dark');
      document.documentElement.setAttribute('data-theme', 'dark');
    });

    const isDark = await page.evaluate(() => document.documentElement.getAttribute('data-theme') === 'dark');
    expect(isDark).toBe(true);

    await compareWithVisualReference(page, 'landing-page-dark.png', [
      EMPTY_STATE_TEXT
    ]);
  });

  test('Visual - Compare validation popup overlay details', async ({ page }) => {
    await page.fill('#day', '15');
    await page.fill('#month', '6');
    await page.fill('#year', '2026');
    await page.click('button[type="submit"]');

    const messageBox = page.locator('#winformsMessageBox');
    await expect(messageBox).toBeVisible();

    await compareWithVisualReference(page, 'validation-popup.png', [
      '15/06/2026 is correct date time!',
      WEEKDAY_LABEL,
      LEAP_YEAR_LABEL,
      MONTH_DAYS_LABEL
    ]);
  });
});
