# DateTimeChecker — SWT301 SQA Demo Project

> Nhóm quay video demo: xem `HUONG-DAN-QUAY-VIDEO-8-TOPIC.md`. Mỗi script của Topic 1-8 hiện in trực tiếp mục tiêu, quy trình, dữ liệu kiểm thử và kết quả trong CMD.

## What This Project Demonstrates
This university demo project demonstrates 8 key SQA topics including Unit, API, Web E2E, Mobile, Performance, Visual Regression, AI-Assisted, and CI/CD testing using Jest, Playwright, Selenium, Flutter, Maestro, and Autocannon.

## Prerequisites
- Java JDK 17 or 21 (Eclipse Adoptium recommended)
- Node.js 18+
- npm (comes with Node.js)
- Flutter SDK (for Topic 4 mobile testing — optional, mock mode available)

## Quick Start (Run Everything)
```bash
npm install
run-all-topics.bat
```

## Running Individual Topics
| Topic | Command | Tool Used |
|-------|---------|-----------|
| 1 - Unit Testing | npm run test:unit | Jest + JUnit 5 |
| 2 - API Testing | npx playwright test --grep="@api" | Playwright + PowerShell |
| 3 - Web E2E Testing | npm run test:e2e | Playwright + Selenium |
| 4 - Mobile Testing | powershell -File "Topic 4 - Mobile Testing/run-mobile-testing.ps1" | Flutter + Maestro |
| 5 - Performance Testing | powershell -File "Topic 5 - Performance Testing/run-performance-tests.ps1" | Autocannon |
| 6 - Visual Regression | npx playwright test --grep="@visual" | Playwright |
| 7 - AI-Assisted Testing | powershell -File "scripts/ai-self-healing-demo.ps1" -OfflineSample -AutoApprove | AI Simulation |
| 8 - CI/CD & Reporting | "Topic 8 - CI CD and Reporting\run-ci-simulation.bat" | Local Batch Simulator |

## Project Structure
```text
├── Topic 1 - Unit Testing/       # Unit tests (Jest for UI, JUnit 5 for Java)
├── Topic 2 - API Testing/        # API tests (Playwright Request Client)
├── Topic 3 - Web E2E Testing/    # Web E2E browser tests (Playwright)
├── Topic 4 - Mobile Testing/     # Flutter unit tests & Maestro flows
├── Topic 5 - Performance Testing/# Sequential Smoke, Load, & Stress tests
├── Topic 6 - Visual Regression/  # Pixel-perfect UI checks
├── Topic 7 - AI-Assisted Testing/# AI generation & self-healing simulation
└── Topic 8 - CI CD and Reporting/# Local 8-stage CI pipeline simulator
```

## Known Issues & Solutions
- **BindException (Port 4173 in use)**: Solved via automated `start-server.ps1` which checks and kills any active process on port 4173 before launching.
- **No emulator for mobile**: Flutter tests will auto-run widget checks and fallback to an offline Maestro simulation if no active emulator is detected.

## Test Results
All reports (API TSV, Performance logs, Mobile check files, Coverage reports) are generated and saved in the root [reports/](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker/reports) folder.
