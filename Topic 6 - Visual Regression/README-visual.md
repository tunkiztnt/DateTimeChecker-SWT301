# Visual Regression Testing Guide

Visual regression testing checks that the user interface continues to render exactly as intended. By comparing active page screenshots against verified baseline images, we can catch unintended layout shifts, font failures, color issues, and broken alignment before code reaches production.

---

## 1. How Baselines are Stored
Baseline screenshots are stored in the spec file's snapshot directory:
- **Location**: `Topic 6 - Visual Regression/visual/visual.spec.js-snapshots/` (or structured inside `__snapshots__/` relative to the spec file).
- These baseline snapshots represent the source-of-truth visual design and should be committed to Git.
- We capture 5 distinct application states for testing:
  1. `empty-form.png` (form loaded, all inputs blank)
  2. `valid-input-entered.png` (input values set but form not submitted)
  3. `valid-result.png` (validation card and WinForms message box showing a correct date)
  4. `invalid-result.png` (validation failure showing an invalid date warning)
  5. `error-state.png` (parsing format error showing dynamic validation alerts)

---

## 2. How to Update Baselines (Intentional UI Changes)
When you intentionally modify the UI design (e.g. updating colors, fonts, margins, or logos), the tests will fail because they no longer match the old baseline screenshots. 

To update the baseline snapshots with the new layout, run the following command from the root directory:
```bash
npx playwright test --config=playwright.config.js --grep="@visual" --update-snapshots
```
This updates the baseline images in the snapshot directory to match the current look of the application.

---

## 3. How to View Diff Reports on Test Failures
When a visual regression test fails, Playwright generates a side-by-side comparison report showing the baseline, the actual screenshot, and the pixel diff.

To view this interactive report:
1. Open the file `playwright-report/index.html` in your browser.
2. Under the failed test case, click on the **Screenshots** tab.
3. Use the slider or image comparison tool to inspect the highlighted red pixels showing exactly what visual changes caused the mismatch.

---

## 4. Video Demo Checklist

1. Run `.\Topic 6 - Visual Regression\run-tests.bat`.
2. Show the CMD log naming each UI state and baseline image.
3. Explain that Playwright captures the current UI and compares pixels with the committed baseline.
4. If demonstrating a failure, open the Playwright report and show expected, actual, and diff images.

---

## 5. Parameter Explanations

Each screenshot comparison utilizes the following options for visual stability and flexibility:

*   **`maxDiffPixels: 100`**:
    *   Allows a maximum of 100 pixels of total deviation across the entire screen.
    *   This accommodates minor, sub-pixel anti-aliasing variations caused by different local operating system font engines or browser GPU differences.
*   **`threshold: 0.1`**:
    *   Specifies a pixel color tolerance of 10% (using the YUV color space).
    *   A pixel is only considered "different" if its color difference from the baseline exceeds this threshold, preventing failure on tiny rendering gradients.
*   **`animations: 'disabled'`**:
    *   Disables all CSS transitions, animations, and SVG loops during screenshot capturing.
    *   This freezes the page at a static, stable frame, ensuring animations do not cause random screenshot discrepancies.
