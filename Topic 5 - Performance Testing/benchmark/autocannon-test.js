const autocannon = require('autocannon');
const fs = require('fs');
const path = require('path');

function runScenario(name, options) {
  return new Promise((resolve, reject) => {
    console.log(`============================================================`);
    console.log(` RUNNING SCENARIO: ${name}`);
    console.log(`============================================================`);
    console.log(`Connections: ${options.connections} | Duration: ${options.duration}s`);
    
    autocannon(options, (err, result) => {
      if (err) {
        return reject(err);
      }
      resolve(result);
    });
  });
}

async function start() {
  const targetUrl = process.env.DATETIMECHECKER_URL || 'http://localhost:4173';
  const apiPath = '/api/check-date';
  
  console.log('Starting DateTimeChecker API Performance Test (Autocannon)...');
  console.log(`Target: ${targetUrl}${apiPath}\n`);

  const results = [];
  
  // SCENARIO 1 — Smoke Test (verify the server works at all):
  // connections: 1, duration: 5 seconds
  // Target: all requests succeed (no errors)
  try {
    const s1Result = await runScenario('Scenario 1 (Smoke)', {
      url: targetUrl,
      connections: 1,
      duration: 5,
      requests: [
        {
          method: 'POST',
          path: apiPath,
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ day: '15', month: '6', year: '2023' })
        }
      ]
    });
    const s1Errors = s1Result.errors + (s1Result.non2xx || 0);
    const s1Passed = s1Errors === 0;
    results.push({
      name: 'Scenario 1 (Smoke)',
      passed: s1Passed,
      requests: s1Result.requests.sent,
      errors: s1Errors,
      p99: s1Result.latency.p99
    });
    console.log(`Result: ${s1Passed ? 'PASS' : 'FAIL'} | Requests: ${s1Result.requests.sent} | Errors: ${s1Errors} | p99: ${s1Result.latency.p99}ms\n`);
  } catch (err) {
    console.error('Smoke test scenario failed with error:', err);
    results.push({ name: 'Scenario 1 (Smoke)', passed: false, requests: 0, errors: 1, p99: 0 });
  }

  // SCENARIO 2 — Load Test (normal expected usage):
  // connections: 10, duration: 15 seconds
  // Target: p99 latency < 500ms, error rate < 1%
  try {
    const s2Result = await runScenario('Scenario 2 (Load)', {
      url: targetUrl,
      connections: 10,
      duration: 15,
      requests: [
        {
          method: 'POST',
          path: apiPath,
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ day: '15', month: '6', year: '2023' })
        }
      ]
    });
    const s2Errors = s2Result.errors + (s2Result.non2xx || 0);
    const s2Total = s2Result.requests.sent;
    const s2ErrorRate = s2Total > 0 ? (s2Errors / s2Total) * 100 : 0;
    const s2Passed = s2Result.latency.p99 < 500 && s2ErrorRate < 1.0;
    results.push({
      name: 'Scenario 2 (Load)',
      passed: s2Passed,
      requests: s2Total,
      errors: s2Errors,
      p99: s2Result.latency.p99
    });
    console.log(`Result: ${s2Passed ? 'PASS' : 'FAIL'} | Requests: ${s2Total} | Errors: ${s2Errors} | p99: ${s2Result.latency.p99}ms\n`);
  } catch (err) {
    console.error('Load test scenario failed with error:', err);
    results.push({ name: 'Scenario 2 (Load)', passed: false, requests: 0, errors: 1, p99: 0 });
  }

  // SCENARIO 3 — Stress Test (find the breaking point):
  // connections: 50, duration: 10 seconds
  // Target: p99 latency < 2000ms, error rate < 5%
  try {
    const s3Result = await runScenario('Scenario 3 (Stress)', {
      url: targetUrl,
      connections: 50,
      duration: 10,
      requests: [
        {
          method: 'POST',
          path: apiPath,
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ day: '15', month: '6', year: '2023' })
        }
      ]
    });
    const s3Errors = s3Result.errors + (s3Result.non2xx || 0);
    const s3Total = s3Result.requests.sent;
    const s3ErrorRate = s3Total > 0 ? (s3Errors / s3Total) * 100 : 0;
    const s3Passed = s3Result.latency.p99 < 2000 && s3ErrorRate < 5.0;
    results.push({
      name: 'Scenario 3 (Stress)',
      passed: s3Passed,
      requests: s3Total,
      errors: s3Errors,
      p99: s3Result.latency.p99
    });
    console.log(`Result: ${s3Passed ? 'PASS' : 'FAIL'} | Requests: ${s3Total} | Errors: ${s3Errors} | p99: ${s3Result.latency.p99}ms\n`);
  } catch (err) {
    console.error('Stress test scenario failed with error:', err);
    results.push({ name: 'Scenario 3 (Stress)', passed: false, requests: 0, errors: 1, p99: 0 });
  }

  // Write Summary Report to reports/performance-report.txt
  const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
  const passedCount = results.filter(r => r.passed).length;
  
  const reportLines = [
    '===========================================',
    `PERFORMANCE TEST REPORT — ${timestamp}`,
    '===========================================',
    `Scenario 1 (Smoke):    ${results[0].passed ? 'PASS' : 'FAIL'} | Requests: ${results[0].requests} | Errors: ${results[0].errors} | p99: ${results[0].p99}ms`,
    `Scenario 2 (Load):     ${results[1].passed ? 'PASS' : 'FAIL'} | Requests: ${results[1].requests} | Errors: ${results[1].errors} | p99: ${results[1].p99}ms`,
    `Scenario 3 (Stress):   ${results[2].passed ? 'PASS' : 'FAIL'} | Requests: ${results[2].requests} | Errors: ${results[2].errors} | p99: ${results[2].p99}ms`,
    '===========================================',
    `OVERALL: ${passedCount}/3 scenarios passed`
  ];
  
  const reportContent = reportLines.join('\n');
  
  console.log('Writing performance report...');
  const reportsDir = path.join(__dirname, '..', '..', 'reports');
  if (!fs.existsSync(reportsDir)) {
    fs.mkdirSync(reportsDir, { recursive: true });
  }
  const reportPath = path.join(reportsDir, 'performance-report.txt');
  fs.writeFileSync(reportPath, reportContent, 'utf8');
  console.log(`Report saved to ${reportPath}\n`);
  
  console.log(reportContent);

  // Exit code is based on whether all scenarios passed
  const allPassed = passedCount === 3;
  process.exit(allPassed ? 0 : 1);
}

start();
