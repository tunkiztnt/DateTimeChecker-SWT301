const autocannon = require('autocannon');

async function runBenchmark() {
  const targetUrl = process.env.DATETIMECHECKER_URL || 'http://localhost:4173';
  console.log('Starting DateTimeChecker API Performance Test (Autocannon)...');
  console.log(`Sending requests to: ${targetUrl}/api/datetime/check`);
  console.log('Running for 10 seconds with 50 concurrent connections...\n');

  const instance = autocannon({
    url: targetUrl,
    connections: 50,
    duration: 10,
    requests: [
      {
        method: 'POST',
        path: '/api/datetime/check',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          day: '30',
          month: '5',
          year: '2026'
        })
      }
    ]
  }, (err, result) => {
    if (err) {
      console.error('Benchmark failed:', err);
      process.exit(1);
    }
    
    console.log('============================================================');
    console.log(' PERFORMANCE BENCHMARK RESULT');
    console.log('============================================================');
    console.log(`Total Requests:      ${result.requests.sent}`);
    console.log(`Average Requests/sec: ${result.requests.average}`);
    console.log(`Average Latency:      ${result.latency.average} ms`);
    console.log(`Max Latency:          ${result.latency.max} ms`);
    console.log(`Errors:               ${result.errors}`);
    console.log(`2xx/3xx Responses:    ${result['2xx'] + result['3xx']}`);
    console.log('============================================================');
    
    // Performance requirement: average latency must be < 1000ms
    if (result.latency.average < 1000) {
      console.log('Result: PASS (Average latency is well below 1 second requirement)');
      process.exit(0);
    } else {
      console.log('Result: FAIL (Average latency exceeded 1 second requirement)');
      process.exit(1);
    }
  });

  // Track progress
  autocannon.track(instance, { render: true });
}

runBenchmark();
