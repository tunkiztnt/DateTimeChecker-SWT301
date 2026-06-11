# Implementation Plan - Restructuring & Fixing Testing Topics (Local Execution)

This plan details the restructuring and clean up of the `DateTimeChecker-AI-Assistant` project. We will ensure that the application is built entirely cleanly from scratch, removing any clutter or external GitHub configurations, and making all testing topics run successfully locally on Windows.

---

## User Review Required

> [!IMPORTANT]
> **No GitHub Actions / Git Changes**: We will completely remove any mentions or configurations for GitHub Actions CI/CD workflows at the root level to avoid touching GitHub. Instead, Topic 8 will feature a **Local CI/CD Simulation Script** that replicates a complete automated pipeline locally on Windows.
>
> **Only Day, Month, Year (Ngày, Tháng, Năm)**: The application strictly accepts and validates only Day, Month, and Year inputs (in range Day: 1-31, Month: 1-12, Year: 1000-3000) matching the URD guidelines. No time fields (hours, minutes, seconds) are included or checked.
>
> **Java Web Architecture**: To support modern web testing tools from your diagram (**Jest**, **Playwright**, **k6**, **Visual screenshots**), the project is structured as a lightweight HTML/CSS/JS frontend served by a pure Java HTTP server (compiled via standard JDK `javac` without Maven/Gradle dependencies). The frontend user interface simulates a desktop application window, including the close exit confirmation modal as per the URD.

---

## Proposed Changes

We will restructure and optimize the files to support clean, local, one-click execution.

### Component 1: Global Setup & Root Files
Ensure a clean root directory, removing temporary scripts and adding a master runner.

#### [DELETE] [recover_git_blobs.py](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/scripts/recover_git_blobs.py)
Remove agent-specific git recovery script.

#### [DELETE] [preview_blobs.py](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/scripts/preview_blobs.py)
Remove agent-specific preview script.

#### [NEW] [run-all-topics.bat](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/run-all-topics.bat)
A master batch script at the root to compile the application and execute all 8 SQA testing topics sequentially.

---

### Component 2: Topic-Specific Batch Compilation Fixes
Ensure each testing topic compiles the Java source files before running tests.

#### [MODIFY] [Topic 2 - API Testing/run-tests.bat](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%202%20-%20API%20Testing/run-tests.bat)
Modify to compile the Java server codebase first using `scripts/build.ps1` before starting Playwright API tests.

#### [MODIFY] [Topic 3 - Web E2E Testing/run-tests.bat](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%203%20-%20Web%20E2E%20Testing/run-tests.bat)
Modify to compile the Java server codebase first before running Playwright E2E browser tests.

#### [MODIFY] [Topic 6 - Visual Regression/run-tests.bat](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%206%20-%20Visual%20Regression/run-tests.bat)
Modify to compile the Java server codebase first before running Playwright Visual screenshot regression tests.

---

### Component 3: Mobile Testing (Topic 4) Simulation Fallback
Create a robust fallback for environments without Android emulators.

#### [MODIFY] [Topic 4 - Mobile Testing/run-mobile-testing.ps1](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%204%20-%20Mobile%20Testing/run-mobile-testing.ps1)
Modify the PowerShell runner to check if Flutter SDK, ADB, and connected Android devices are present. 
- If present: Run the actual Flutter/Maestro test flow.
- If missing: Log user-friendly diagnostic steps and launch an **Offline Mock Demo Mode**.
- The Mock Demo Mode will simulate building the app and executing Maestro test cases (matching day/month/year inputs and validation assertions) to allow a seamless presentation without emulator dependencies.

---

### Component 4: CI/CD Simulation (Topic 8)
Fulfill the CI/CD pipeline requirement locally without using GitHub actions.

#### [NEW] [Topic 8 - CI CD and Reporting/run-ci-simulation.bat](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%208%20-%20CI%20CD%20and%20Reporting/run-ci-simulation.bat)
A batch script that simulates a CI/CD build pipeline locally:
1. **LINT/CHECK**: Scan syntax and code formatting.
2. **BUILD**: Compile Java server classes.
3. **UNIT TEST**: Execute Topic 1 Java & JavaScript unit tests.
4. **INTEGRATION/API TEST**: Execute Topic 2 API tests.
5. **E2E BROWSER TEST**: Execute Topic 3 E2E tests.
6. **PERFORMANCE TEST**: Run Topic 5 latency benchmark.
7. **VISUAL TEST**: Run Topic 6 screenshot checks.
8. **REPORT**: Compile all outputs and print a final success summary.

---

## Verification Plan

### Automated Tests
1. Run `run-all-topics.bat` from command line to verify all topics execute.
2. Double click the batch files in each topic folder (`Topic 1`, `Topic 2`, `Topic 3`, `Topic 4`, `Topic 5`, `Topic 6`, `Topic 7`, `Topic 8`) and confirm they run successfully, pause at the end, and do not crash.

### Manual Verification
- Verify that no `.github` folder exists in the repository.
- Verify that visual regression tests pass after the updates.
- Verify that Topic 4 mobile testing cleanly falls back to simulated output when no Android device is attached.
