param(
    [string]$ApiKey,
    [switch]$OfflineSample,
    [switch]$AutoApprove
)

# Colors: Green for [AI], Yellow for [DETECTOR], Cyan for code.
# Delays: Start-Sleep is added between steps. Total runtime under 2 minutes (approx 70s).

# Header
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   AI-ASSISTED TESTING & SELF-HEALING DEMONSTRATION" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# DEMO 1: AI Test Generation (30 seconds)
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " CONCEPT 1: AI TEST GENERATION (30 seconds)" -ForegroundColor Gray
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Start-Sleep -Milliseconds 800

Write-Host "[AI] Analyzing DateTimeValidationService.java..." -ForegroundColor Green
Start-Sleep -Seconds 4

Write-Host "[AI] Detected: leap year logic at line 45" -ForegroundColor Green
Start-Sleep -Seconds 4

Write-Host "[AI] Generating boundary test cases..." -ForegroundColor Green
Start-Sleep -Seconds 4

Write-Host "  ✓ Generated: testLeapYear_2000_divisibleBy400_shouldBeValid()" -ForegroundColor Green
Start-Sleep -Seconds 3

Write-Host "  ✓ Generated: testLeapYear_1900_divisibleBy100NotBy400_shouldBeInvalid()" -ForegroundColor Green
Start-Sleep -Seconds 3

Write-Host "  ✓ Generated: testBoundary_day0_shouldReturnError()" -ForegroundColor Green
Start-Sleep -Seconds 3

Write-Host "  ✓ Generated: testBoundary_day32_shouldReturnError()" -ForegroundColor Green
Start-Sleep -Seconds 3

Write-Host "  ✓ Generated: testFebruary_day30_anyYear_shouldBeInvalid()" -ForegroundColor Green
Start-Sleep -Seconds 3

Write-Host "[AI] 5 test cases generated. Estimated coverage increase: +12%" -ForegroundColor Green
Start-Sleep -Seconds 3

Write-Host ""

# DEMO 2: Self-Healing Locator (20 seconds)
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " CONCEPT 2: SELF-HEALING LOCATOR (20 seconds)" -ForegroundColor Gray
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Start-Sleep -Milliseconds 800

Write-Host "[DETECTOR] Running E2E test: 'Enter date and check'..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "[DETECTOR] Locator '#input-day' not found (element was renamed to '#day-input')" -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "[AI HEAL] Searching for similar elements by label text 'Day'..." -ForegroundColor Green
Start-Sleep -Seconds 3

Write-Host "[AI HEAL] Found match: input[aria-label='Day'] — confidence: 94%" -ForegroundColor Green
Start-Sleep -Seconds 3

Write-Host "[AI HEAL] Updating locator in test file..." -ForegroundColor Green
Start-Sleep -Seconds 3

Write-Host "[HEALED] Test now uses: page.getByLabel('Day') ← resilient locator" -ForegroundColor Green
Start-Sleep -Seconds 3

Write-Host "[RESULT] Test passed after self-healing. No manual fix needed." -ForegroundColor Green
Start-Sleep -Seconds 2

Write-Host ""

# DEMO 3: Natural Language to Test Code (20 seconds)
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " CONCEPT 3: NATURAL LANGUAGE TO TEST CODE (20 seconds)" -ForegroundColor Gray
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Start-Sleep -Milliseconds 800

Write-Host "[NL INPUT] 'Verify that entering February 29 in a non-leap year shows INVALID'" -ForegroundColor White
Start-Sleep -Seconds 4

Write-Host "[AI] Parsing requirement..." -ForegroundColor Green
Start-Sleep -Seconds 4

Write-Host "[AI] Generating Playwright test..." -ForegroundColor Green
Start-Sleep -Seconds 4

Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  test('Feb 29 in non-leap year shows INVALID', async ({ page }) => {" -ForegroundColor Cyan
Write-Host "    await page.goto('http://localhost:4173');" -ForegroundColor Cyan
Write-Host "    await page.getByLabel('Day').fill('29');" -ForegroundColor Cyan
Write-Host "    await page.getByLabel('Month').fill('2');" -ForegroundColor Cyan
Write-Host "    await page.getByLabel('Year').fill('2023');" -ForegroundColor Cyan
Write-Host "    await page.getByRole('button', { name: 'Check' }).click();" -ForegroundColor Cyan
Write-Host "    await expect(page.getByText('INVALID')).toBeVisible();" -ForegroundColor Cyan
Write-Host "  });" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Start-Sleep -Seconds 5

Write-Host "[AI] Test generated successfully. Add to your test suite with: npm run test:e2e" -ForegroundColor Green
Start-Sleep -Seconds 3

# Final Summary Table
Write-Host ""
Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  AI-ASSISTED TESTING DEMO COMPLETE   ║" -ForegroundColor Green
Write-Host "║  • Test Generation:   DEMONSTRATED   ║" -ForegroundColor Green
Write-Host "║  • Self-Healing:      DEMONSTRATED   ║" -ForegroundColor Green
Write-Host "║  • NL to Code:        DEMONSTRATED   ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

exit 0
