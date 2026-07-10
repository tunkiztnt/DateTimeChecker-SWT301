# Topic 4: Performance Testing

## Purpose

Topic 4 demonstrates that the `DateTimeChecker` backend can continue to serve requests quickly and reliably under concurrent load.

## Main Files

- Runner launcher: `topics/04-performance-testing/run.bat`
- PowerShell runner: `topics/04-performance-testing/run.ps1`
- Built-in Node load test: `topics/04-performance-testing/node-perf-run.js`
- Output report: `topics/reports/performance-testing-report.txt`

## Recommended Demo Flow

1. Run:

```powershell
.\topics\04-performance-testing\run.bat
```

2. Explain that the script will:
   - compile the Java backend
   - start the server on `http://localhost:4173`
   - generate concurrent requests to `/api/datetime/check`
   - print live metrics every second, including request timestamp, success/fail, `avg` latency, and `p95`
   - measure throughput, latency, and success rate
   - stop the server automatically and save a report

3. Highlight the pass criteria from the output:
   - `P95 < 1000ms`
   - `Success Rate > 99%`

4. During the live run, point to:
   - `lastRequestStart` to show when each newest request started
   - `success` and `fail` counters to show completion tracking
   - `avg` and `p95` to show how latency is being measured in real time

## Demo Talk Track

> Topic 4 verifies non-functional quality. We simulate concurrent users calling the date-checking API, then measure response time and stability. If the P95 latency stays under one second and the success rate remains above 99%, the backend is considered performant for this demo scope.
