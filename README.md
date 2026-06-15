# DateTimeChecker

DateTimeChecker is a small Java web application for checking whether a day, month, and year form a valid Gregorian calendar date.

## Requirements

- Java JDK 17 or newer
- Windows PowerShell

## Run The App

Double-click:

```bat
run.bat
```

Or run from PowerShell:

```powershell
.\scripts\run.ps1
```

The app compiles Java source files, starts the local server, and opens:

```text
http://localhost:4173
```

## Project Structure

```text
src/main/java                 Java backend source
src/main/resources/static     Web UI assets
scripts/build.ps1             Compile the app
scripts/run.ps1               Compile and run the app
scripts/start-server.ps1      Start server for local use
scripts/stop-server.ps1       Stop server on port 4173
run.bat                       Windows launcher
```

## Notes

- The server uses port `4173`.
- Build output is written to `out/classes`.
- All previous SWT301 testing topic folders and demo tooling have been removed, leaving only the application.
