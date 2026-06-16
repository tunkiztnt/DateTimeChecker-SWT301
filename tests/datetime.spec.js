const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

// Local cache of healed locators to prevent visual spam per test case execution
let healedLocatorsCache = {};

async function getLocator(page, selector, labelText, tcId) {
  if (process.env.SELF_HEALING === 'false') {
    return page.locator(selector);
  }
  
  if (healedLocatorsCache[selector]) {
    return healedLocatorsCache[selector];
  }
  
  try {
    const originalLocator = page.locator(selector);
    if (await originalLocator.count() > 0) {
      return originalLocator.first();
    }
  } catch (e) {}

  console.log(`\n\x1b[33m[AI SELF-HEALING] Locator "${selector}" failed to resolve!`);
  console.log(`[AI SELF-HEALING] Searching DOM for element associated with "${labelText}"... \x1b[0m`);
  
  // Inject a warning banner on browser page for the demo
  await page.evaluate(({ selector, labelText }) => {
    const banner = document.createElement('div');
    banner.id = 'ai-self-healing-banner';
    banner.style.position = 'fixed';
    banner.style.top = '20px';
    banner.style.left = '50%';
    banner.style.transform = 'translateX(-50%)';
    banner.style.backgroundColor = '#d84315';
    banner.style.color = '#ffffff';
    banner.style.padding = '14px 28px';
    banner.style.borderRadius = '8px';
    banner.style.boxShadow = '0 6px 20px rgba(0,0,0,0.3)';
    banner.style.zIndex = '999999';
    banner.style.fontFamily = 'Segoe UI, Arial, sans-serif';
    banner.style.fontSize = '14px';
    banner.style.fontWeight = 'bold';
    banner.style.border = '2px solid #ffab91';
    banner.style.textAlign = 'center';
    banner.style.transition = 'all 0.5s ease';
    banner.innerHTML = `⚠️ [AI Self-Healing] Broken locator "${selector}"!<br><span style="font-weight:normal;font-size:12px;">Searching DOM for element associated with "${labelText}"...</span>`;
    document.body.appendChild(banner);
  }, { selector, labelText });

  let healedElement = null;
  let healedPath = "";

  // 1. If it's an input field, look up label with text
  const labelLocator = page.locator(`label:has-text("${labelText}")`);
  if (await labelLocator.count() > 0) {
    const forAttr = await labelLocator.first().getAttribute('for');
    if (forAttr) {
      const inputById = page.locator(`#${forAttr}`);
      if (await inputById.count() > 0) {
        healedElement = inputById.first();
        healedPath = `input (associated with label "${labelText}")`;
      }
    }
    if (!healedElement) {
      const parent = labelLocator.first().locator('..');
      const inputInParent = parent.locator('input');
      if (await inputInParent.count() > 0) {
        healedElement = inputInParent.first();
        healedPath = `input (child of label's parent for "${labelText}")`;
      }
    }
  }

  // 2. If it's a button, look up by text content
  if (!healedElement) {
    const btnLocator = page.locator(`button:has-text("${labelText}"), input[type="submit"]:has-text("${labelText}")`);
    if (await btnLocator.count() > 0) {
      healedElement = btnLocator.first();
      healedPath = `button:has-text("${labelText}")`;
    }
  }

  if (healedElement) {
    console.log(`\x1b[32m[AI SELF-HEALING SUCCESS] Found alternative element!`);
    console.log(`[AI SELF-HEALING SUCCESS] Resolving locator path to: "${healedPath}" \x1b[0m\n`);
    
    // Highlight element visually
    await healedElement.evaluate(el => {
      el.style.outline = '4px dashed #e65100';
      el.style.outlineOffset = '6px';
      el.style.boxShadow = '0 0 15px #ffab91';
      el.style.backgroundColor = '#ffe0b2';
    });
    
    await page.waitForTimeout(400);
    
    // Update banner
    await page.evaluate(({ labelText }) => {
      const banner = document.getElementById('ai-self-healing-banner');
      if (banner) {
        banner.style.backgroundColor = '#2e7d32';
        banner.style.borderColor = '#a5d6a7';
        banner.innerHTML = `✅ [AI Self-Healing Success] Recovered!<br><span style="font-weight:normal;font-size:12px;">Using element associated with "${labelText}"</span>`;
      }
    }, { labelText });
    
    await page.waitForTimeout(300);
    
    // Reset styles
    await healedElement.evaluate(el => {
      el.style.outline = '';
      el.style.outlineOffset = '';
      el.style.boxShadow = '';
      el.style.backgroundColor = '';
    });
    
    await page.evaluate(() => {
      const banner = document.getElementById('ai-self-healing-banner');
      if (banner) banner.remove();
    });
    
    // Log to file
    try {
      const logPath = path.join(__dirname, 'healed-log.json');
      let logs = [];
      if (fs.existsSync(logPath)) {
        logs = JSON.parse(fs.readFileSync(logPath, 'utf8'));
      }
      logs.push({ id: tcId || 'unknown', selector, healedTo: healedPath });
      fs.writeFileSync(logPath, JSON.stringify(logs, null, 2));
    } catch (e) {}

    healedLocatorsCache[selector] = healedElement;
    return healedElement;
  } else {
    console.log(`\x1b[31m[AI SELF-HEALING FAILED] Could not resolve alternative for "${selector}".\x1b[0m\n`);
    await page.evaluate(() => {
      const banner = document.getElementById('ai-self-healing-banner');
      if (banner) banner.remove();
    });
    throw new Error(`Locator "${selector}" failed to resolve and AI could not heal it.`);
  }
}

// Load dynamically generated test cases from JSON file
const testCasesPath = path.join(__dirname, 'generated_tests.json');
let testCases = [];

if (fs.existsSync(testCasesPath)) {
  try {
    testCases = JSON.parse(fs.readFileSync(testCasesPath, 'utf8'));
  } catch (e) {
    console.error("Failed to parse generated_tests.json", e);
  }
}

// Fallback test cases if no generated file exists
if (testCases.length === 0) {
  testCases = [
    { id: "TC01", name: "Valid Date (Leap Year)", day: "29", month: "2", year: "2024", expected: "valid", message: "29/02/2024 is correct date time!" },
    { id: "TC02", name: "Invalid Date (Non-Leap Year)", day: "29", month: "2", year: "2023", expected: "invalid", message: "29/02/2023 is NOT correct date time!" },
    { id: "TC03", name: "Day Decimal Error", day: "1.5", month: "2", year: "2020", expected: "error", message: "Input data for Day is incorrect format!" },
    { id: "TC04", name: "Day Out of Range", day: "32", month: "2", year: "2020", expected: "error", message: "Input data for Day is out of range!" },
    { id: "TC05", name: "Clear Button Functionality", day: "15", month: "6", year: "2026", expected: "clear", message: "" },
    { id: "TC06", name: "Close Confirm and Cancel", day: "", month: "", year: "", expected: "close", message: "" },
    { id: "TC07", name: "E2E Verification with Self-Healing Locator", day: "15", month: "6", year: "2026", expected: "valid", message: "15/06/2026 is correct date time!" }
  ];
}

test.describe('Date Time Checker E2E Test Suite', () => {
  test.beforeEach(async ({ page }) => {
    healedLocatorsCache = {};
    await page.goto('/');
  });

  for (let i = 0; i < testCases.length; i++) {
    const tc = testCases[i];
    test(`${tc.id}: ${tc.name}`, async ({ page }) => {
      if (tc.expected === 'clear') {
        if (tc.day) {
          const loc = await getLocator(page, '#day', 'Day', tc.id);
          await loc.fill(tc.day);
        }
        if (tc.month) {
          const loc = await getLocator(page, '#month', 'Month', tc.id);
          await loc.fill(tc.month);
        }
        if (tc.year) {
          const loc = await getLocator(page, '#year', 'Year', tc.id);
          await loc.fill(tc.year);
        }
        const clearBtn = await getLocator(page, '#clearButton', 'Clear', tc.id);
        await clearBtn.click();
        
        const dayLoc = await getLocator(page, '#day', 'Day', tc.id);
        await expect(dayLoc).toHaveValue('');
        const monthLoc = await getLocator(page, '#month', 'Month', tc.id);
        await expect(monthLoc).toHaveValue('');
        const yearLoc = await getLocator(page, '#year', 'Year', tc.id);
        await expect(yearLoc).toHaveValue('');
      } else if (tc.expected === 'close') {
        const closeBtn = await getLocator(page, '#closeButton', 'Close', tc.id);
        await closeBtn.click();
        const confirmModal = page.locator('#closeModal');
        await expect(confirmModal).toBeVisible();
        await page.click('#confirmCloseNo');
        await expect(confirmModal).not.toBeVisible();
      } else {
        if (tc.day) {
          const loc = await getLocator(page, '#day', 'Day', tc.id);
          await loc.fill(tc.day);
        }
        if (tc.month) {
          const loc = await getLocator(page, '#month', 'Month', tc.id);
          await loc.fill(tc.month);
        }
        if (tc.year) {
          const loc = await getLocator(page, '#year', 'Year', tc.id);
          await loc.fill(tc.year);
        }

        const checkBtn = await getLocator(page, 'button[type="submit"]', 'Check', tc.id);
        await checkBtn.click();

        const messageText = page.locator('#wfMbMessage');
        await expect(messageText).toHaveText(tc.message);
        await page.click('#wfMbOkBtn');
      }
    });
  }
});
