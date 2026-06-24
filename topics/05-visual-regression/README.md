# Topic 5: Visual Regression

## Purpose

Topic 5 verifies that important UI states still look correct by comparing fresh screenshots against approved baseline images in a deterministic render mode.

## Review Folders

- Baseline images: `topics/05-visual-regression/baseline-images`
- Current run images: `topics/05-visual-regression/current-run-images`
- Diff images: `topics/05-visual-regression/diff-images`

## Demo Flow

1. Run:

```powershell
.\topics\05-visual-regression\run.bat
```

The launcher forces `HEADLESS=true` and the test injects a deterministic render mode:
- local system fonts only
- fixed live date
- disabled animations / transitions / focus outlines
- exact pixel comparison (`0` changed pixels required)

2. Let the browser open and show the visual test steps.

3. After the run:
   - open `baseline-images` to show the approved old images
   - open `current-run-images` to show the fresh screenshots from this run
   - open `diff-images` to show highlighted changed pixels for every screen
   - explain that the test compares `current-run-images` directly against `baseline-images`

## Covered Screens

- Landing page
- Dark mode page
- Validation popup
