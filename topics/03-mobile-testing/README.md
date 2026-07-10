# Topic 3: Mobile Testing

## Purpose

This topic demonstrates the Flutter mobile version of `DateTimeChecker` on Android and separates:

- manual demo of the updated mobile UI
- optional automated testing with Maestro

## Main Files

- Flutter app: `topics/03-mobile-testing/flutter_app/`
- Start emulator and prepare demo: `topics/03-mobile-testing/start-emulator.bat`
- Automated mobile test runner: `topics/03-mobile-testing/run-tests.bat`
- Maestro flow: `topics/03-mobile-testing/maestro/date_time_checker_flow.yaml`
- Report output: `reports/mobile-testing-report.txt`

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
- reuses the installed app when you confirm automation, instead of rebuilding immediately again

If you want to force reinstall the latest build:

```powershell
.\topics\03-mobile-testing\start-emulator.bat --refresh
```

### 2. Optional automation

The launcher already asks whether you want to run automation after the manual demo.

## Demo Message

“Topic 3 now starts like a real phone demo: the emulator opens, the app is already installed, and we manually open it first. Only after that do we confirm whether we want to run automated mobile testing.”
