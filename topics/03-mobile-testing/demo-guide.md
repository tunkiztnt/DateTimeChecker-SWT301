# Demo Guide - Mobile Testing

## Goal

Show the updated Flutter mobile UI first, then run automated testing only when needed.

## Recommended Demo Flow

1. Start the emulator, keep the app installed on the device, and prepare manual demo:

```powershell
.\topics\03-mobile-testing\start-emulator.bat
```

Use this if you want to force rebuild and reinstall the latest app:

```powershell
.\topics\03-mobile-testing\start-emulator.bat --refresh
```

2. On the emulator home screen, tap `Date Time Checker` manually.

3. Show that the mobile screen now follows the PC layout:
   - header with FPT branding
   - centered `Date Time Checker` title
   - `Day`, `Month`, `Year` inputs
   - `Clear`, `Use Today`, `Check`
   - result panel below the form

4. Manually interact with the app on the emulator:
   - try one valid date
   - try one invalid date
   - toggle theme if needed

5. When you finish the manual demo, return to the command window and confirm whether you want to run automated testing.
   - choose `Y` to run automation on the already installed app
   - it skips redundant rebuild/reinstall steps for faster repeat demos

6. Open the generated report if automated testing runs:

```text
reports\mobile-testing-report.txt
```

## Talk Track

> We first show the installed mobile app directly on the emulator, just like a real user would use it. After the manual demo, we can optionally confirm and run automated testing to prove the same Android flow is testable end-to-end.
