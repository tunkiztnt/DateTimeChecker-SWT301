# Demo Guide - Mobile E2E Testing

## Goal

Show the installed Flutter mobile UI first, then run automated Mobile E2E testing only when needed.

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

3. Show that the mobile screen follows the PC layout:
   - header with FPT branding
   - centered `Date Time Checker` title
   - `Day`, `Month`, `Year` inputs
   - `Clear`, `Use Today`, `Check`
   - result panel below the form

4. Manually interact with the app on the emulator:
   - try one valid date
   - try one invalid date
   - show that this is the installed Android app, not a browser simulation

5. Return to the command window and confirm automated testing:
   - choose `Y` to run automation on the already installed app
   - the runner skips rebuild/reinstall/environment checks
   - Maestro runs separate Mobile E2E cases immediately

6. Review the generated HTML report:

```text
topics\03-mobile-testing\reports\mobile-e2e-report\index.html
```

## Talk Track

> We first show the installed mobile app directly on the emulator, just like a real user would use it. After the manual demo, we confirm automated testing. The runner does not rebuild or reinstall; it runs Mobile E2E flows immediately and generates an HTML report with pass/fail status for each case.
