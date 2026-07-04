# Topic 3: Mobile E2E Testing

## Purpose

This topic demonstrates the Flutter mobile version of `DateTimeChecker` on Android and separates:

- manual demo of the installed mobile UI
- fast automated Mobile E2E testing with Maestro
- HTML/JSON report output similar to the PC E2E topic

## Main Files

- Flutter app: `topics/03-mobile-testing/flutter_app/`
- Start emulator and prepare demo: `topics/03-mobile-testing/start-emulator.bat`
- Automated mobile test runner: `topics/03-mobile-testing/run-tests.bat`
- Maestro E2E flows: `topics/03-mobile-testing/maestro/e2e/`
- HTML report output: `topics/03-mobile-testing/reports/mobile-e2e-report/index.html`
- JSON report output: `topics/03-mobile-testing/reports/mobile-e2e-report/results.json`
- CSV report output: `topics/03-mobile-testing/reports/mobile-e2e-report/results.csv`

## Recommended Usage

### 1. Prepare the emulator and manual demo

```powershell
.\topics\03-mobile-testing\start-emulator.bat
```

This flow:

- starts the emulator
- keeps the app installed on the device for faster repeat demos
- installs the app only when missing
- returns the emulator to the Home screen
- lets you open the app manually
- asks for confirmation before running automated tests
- runs Mobile E2E immediately on the installed app when you confirm automation
- skips Flutter build/reinstall/environment scan during the test step
- skips Maestro driver reinstall and debug artifact capture for faster demo tapping

If you want to force reinstall the latest app:

```powershell
.\topics\03-mobile-testing\start-emulator.bat --refresh
```

### Performance Notes

The emulator is tuned for demo speed:

- 720x1280 screen instead of a heavy full Pixel 5 resolution
- host GPU acceleration
- 4 CPU cores and 3GB RAM
- Android animations disabled
- Flutter release APK for faster app startup

If the emulator is already open and still feels laggy, close the Android Emulator window completely, then run:

```powershell
.\topics\03-mobile-testing\start-emulator.bat --refresh
```

The `--refresh` run installs the optimized release APK once. Later runs can skip reinstall for faster startup.

### 2. Run only automated Mobile E2E

```powershell
.\topics\03-mobile-testing\run-tests.bat
```

The report opens automatically after the run and is saved at:

```text
topics/03-mobile-testing/reports/mobile-e2e-report/index.html
```

If you need Maestro screenshots/debug files for troubleshooting, run:

```powershell
.\topics\03-mobile-testing\run-mobile-testing.ps1 -DebugArtifacts -OpenReport
```

## Demo Message

“Topic 3 starts like a real phone demo: the emulator opens, the app is already installed, and we manually open it first. When we confirm automated testing, the script runs Android E2E flows directly on the installed app and exports an HTML report similar to the PC E2E report.”
