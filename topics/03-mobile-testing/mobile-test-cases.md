# Mobile E2E Test Cases - Flutter Android App

Tool selected: Maestro.

Reason:

- Free and open-source.
- Works well with Android emulator/device and Flutter UI.
- Test flow is short YAML, easy to demo.
- The runner now exports HTML/JSON reports instead of only a plain text log.

## Scope

App under test:

```text
topics/03-mobile-testing/flutter_app
```

Android package:

```text
com.datetimechecker.date_time_checker
```

## Test Cases

| ID | Scenario | Steps | Expected result |
|---|---|---|---|
| M-E2E-01 | Valid date validation | Enter day `30`, month `5`, year `2026`, tap Check | Result shows valid date and display `30/05/2026` |
| M-E2E-02 | Invalid non-leap date | Enter day `29`, month `2`, year `2025`, tap Check | Result shows invalid date and error `Month 2 of year 2025 has only 28 days.` |
| M-E2E-03 | Leap year date | Enter day `29`, month `2`, year `2024`, tap Check | Result shows valid date and display `29/02/2024` |
| M-E2E-04 | Clear form reset | Enter a valid date, tap Clear | Result panel returns to `Waiting for validation` |

## Files

- Maestro E2E flows: `topics/03-mobile-testing/maestro/e2e/`
- Runner script: `topics/03-mobile-testing/run-mobile-testing.ps1`
- Demo launcher: `topics/03-mobile-testing/start-emulator.bat`
- Test launcher: `topics/03-mobile-testing/run-tests.bat`
- HTML report: `topics/03-mobile-testing/reports/mobile-e2e-report/index.html`
- JSON report: `topics/03-mobile-testing/reports/mobile-e2e-report/results.json`
- CSV report: `topics/03-mobile-testing/reports/mobile-e2e-report/results.csv`
