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
topics/                       SWT301 demo topics and test suites
scripts/ai-testing-tool.js    AI-Assisted Testing Interactive Dashboard
AI_Testing_Report.md          Detailed report of AI testing design and results
```

## AI-Assisted Testing (Interactive Demo)

Double-click:

```bat
run-ai-test.bat
```

Or run from the command line:

```bash
npm run ai-test
```

For more details on the testing design, equivalence partitions, boundary values, and self-healing mechanics, please see `AI_Testing_Report.md`.

## Notes

- The server uses port `4173`.
- Build output is written to `out/classes`.
- Topic launchers and reports now live under `topics/`.
