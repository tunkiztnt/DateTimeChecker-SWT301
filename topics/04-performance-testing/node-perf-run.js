/**
 * Zero-dependency Node.js Performance and Load Testing Tool
 * Designed as a built-in replacement/demo when external tool 'k6' is not installed.
 */

const fs = require('fs');
const http = require('http');

const TARGET_URL = process.env.PERF_TARGET_URL || 'http://localhost:4173/api/datetime/check';
const CONCURRENCY = Number(process.env.PERF_CONCURRENCY || 10);
const DURATION_MS = Number(process.env.PERF_DURATION_MS || 5000);
const LIVE_INTERVAL_MS = Number(process.env.PERF_LIVE_INTERVAL_MS || 1000);
const REPORT_PATH = process.env.PERF_REPORT_PATH || '';

function computeStats(latencyValues, totalRequests, successfulRequests, failedRequests, startTimeMs) {
  const sortedLatencies = [...latencyValues].sort((a, b) => a - b);
  const actualDurationS = Math.max((Date.now() - startTimeMs) / 1000, 0.001);
  const avgLatency = sortedLatencies.reduce((a, b) => a + b, 0) / (sortedLatencies.length || 1);
  const p95Index = Math.floor(sortedLatencies.length * 0.95);
  const p95Latency = sortedLatencies[p95Index] || 0;
  const maxLatency = sortedLatencies[sortedLatencies.length - 1] || 0;
  const minLatency = sortedLatencies[0] || 0;
  const rps = totalRequests / actualDurationS;
  const successRate = totalRequests === 0 ? 0 : (successfulRequests / totalRequests) * 100;

  return {
    actualDurationS,
    avgLatency,
    p95Latency,
    maxLatency,
    minLatency,
    rps,
    successRate
  };
}

function formatIsoTime(timestampMs) {
  if (!timestampMs) {
    return 'N/A';
  }

  return new Date(timestampMs).toISOString();
}

function createMetricLine(label, value, meaning) {
  return `- ${label.padEnd(17)}: ${String(value).padEnd(16)} | ${meaning}`;
}

function buildLiveSnapshot(secondIndex, stats, totalRequests, newRequestsThisTick, inFlightRequests, successfulRequests, failedRequests, latestLatency, latestRequestStartTime) {
  return [
    `================ LIVE SECOND ${secondIndex} ================`,
    createMetricLine('Started', totalRequests, 'Tong so request da duoc bat dau'),
    createMetricLine('New This Second', newRequestsThisTick, 'So request moi phat sinh trong 1 giay vua qua'),
    createMetricLine('In Flight', inFlightRequests, 'So request van dang cho response'),
    createMetricLine('Success', successfulRequests, 'So request thanh cong (HTTP 200)'),
    createMetricLine('Fail', failedRequests, 'So request loi hoac non-200'),
    createMetricLine('Avg Latency', `${stats.avgLatency.toFixed(1)}ms`, 'Thoi gian phan hoi trung binh'),
    createMetricLine('P95 Latency', `${stats.p95Latency}ms`, '95% request co latency nho hon muc nay'),
    createMetricLine('Throughput', `${stats.rps.toFixed(2)} rps`, 'So request xu ly moi giay'),
    createMetricLine('Success Rate', `${stats.successRate.toFixed(2)}%`, 'Ti le request thanh cong'),
    createMetricLine('Latest Latency', `${latestLatency}ms`, 'Latency cua request vua hoan thanh gan nhat'),
    createMetricLine('Last Start Time', formatIsoTime(latestRequestStartTime), 'Thoi diem request moi nhat bat dau')
  ];
}

function buildSummaryLines(stats, totalRequests, successfulRequests, failedRequests, latestLatency, latestRequestStartTime) {
  return [
    '================ FINAL SUMMARY ================',
    createMetricLine('Total Started', totalRequests, 'Tong request da gui trong ca bai test'),
    createMetricLine('Success', successfulRequests, 'Tong request thanh cong'),
    createMetricLine('Fail', failedRequests, 'Tong request loi'),
    createMetricLine('Success Rate', `${stats.successRate.toFixed(2)}%`, 'Ti le request thanh cong'),
    createMetricLine('Throughput', `${stats.rps.toFixed(2)} rps`, 'Toc do xu ly request moi giay'),
    createMetricLine('Min Latency', `${stats.minLatency}ms`, 'Latency nho nhat'),
    createMetricLine('Max Latency', `${stats.maxLatency}ms`, 'Latency lon nhat'),
    createMetricLine('Avg Latency', `${stats.avgLatency.toFixed(1)}ms`, 'Latency trung binh'),
    createMetricLine('P95 Latency', `${stats.p95Latency}ms`, '95% request nam duoi moc nay'),
    createMetricLine('Latest Latency', `${latestLatency}ms`, 'Latency cua request hoan thanh gan nhat'),
    createMetricLine('Last Start Time', formatIsoTime(latestRequestStartTime), 'Thoi diem request moi nhat bat dau'),
    '================================================'
  ];
}

async function runTest() {
  console.log(`\x1b[36m============================================================`);
  console.log(`      NODEJS BUILT-IN PERFORMANCE AND STRESS TESTER`);
  console.log(`============================================================\x1b[0m`);
  console.log(`Target:       ${TARGET_URL}`);
  console.log(`Concurrency:  ${CONCURRENCY} active workers`);
  console.log(`Duration:     ${DURATION_MS / 1000} seconds`);
  console.log(`Live Update:  every ${LIVE_INTERVAL_MS / 1000} second(s)`);
  console.log(`------------------------------------------------------------`);
  console.log(`Measurement Method:`);
  console.log(`- requestStartTime = Date.now() truoc khi gui request`);
  console.log(`- latency = Date.now() - requestStartTime khi nhan response`);
  console.log(`- success/fail duoc dem ngay khi request hoan thanh`);
  console.log(`- p95 duoc tinh tu toan bo mau latency da thu thap`);
  console.log(`------------------------------------------------------------`);

  let totalRequests = 0;
  let successfulRequests = 0;
  let failedRequests = 0;
  let latestRequestStartTime = 0;
  let latestLatency = 0;
  const latencies = [];
  const liveHistory = [];

  const startTime = Date.now();
  let keepRunning = true;
  let previousTotalRequests = 0;
  let liveSecondIndex = 0;

  const liveTicker = setInterval(() => {
    liveSecondIndex += 1;
    const inFlightRequests = totalRequests - successfulRequests - failedRequests;
    const currentStats = computeStats(latencies, totalRequests, successfulRequests, failedRequests, startTime);
    const newRequestsThisTick = totalRequests - previousTotalRequests;
    previousTotalRequests = totalRequests;

    const snapshotLines = buildLiveSnapshot(
      liveSecondIndex,
      currentStats,
      totalRequests,
      newRequestsThisTick,
      inFlightRequests,
      successfulRequests,
      failedRequests,
      latestLatency,
      latestRequestStartTime
    );

    liveHistory.push(...snapshotLines, '');
    snapshotLines.forEach((line) => console.log(line));
    console.log('');
  }, LIVE_INTERVAL_MS);

  async function worker() {
    while (keepRunning) {
      const payload = JSON.stringify({
        day: String(Math.floor(Math.random() * 31) + 1),
        month: String(Math.floor(Math.random() * 12) + 1),
        year: String(Math.floor(Math.random() * 2001) + 1000)
      });

      const requestStartTime = Date.now();
      latestRequestStartTime = requestStartTime;
      totalRequests++;

      try {
        await new Promise((resolve, reject) => {
          const req = http.request(TARGET_URL, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Content-Length': Buffer.byteLength(payload)
            }
          }, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
              if (res.statusCode === 200) {
                resolve(body);
              } else {
                reject(new Error(`Status ${res.statusCode}`));
              }
            });
          });

          req.on('error', (err) => reject(err));
          req.write(payload);
          req.end();
        });

        const latency = Date.now() - requestStartTime;
        latestLatency = latency;
        latencies.push(latency);
        successfulRequests++;
      } catch (err) {
        latestLatency = Date.now() - requestStartTime;
        failedRequests++;
      }
    }
  }

  const workers = Array(CONCURRENCY).fill(null).map(() => worker());

  await new Promise((resolve) => setTimeout(resolve, DURATION_MS));
  keepRunning = false;

  await Promise.all(workers);
  clearInterval(liveTicker);

  const finalStats = computeStats(latencies, totalRequests, successfulRequests, failedRequests, startTime);
  const summaryLines = buildSummaryLines(
    finalStats,
    totalRequests,
    successfulRequests,
    failedRequests,
    latestLatency,
    latestRequestStartTime
  );

  console.log(`\n\x1b[32m${summaryLines[0]}\x1b[0m`);
  summaryLines.slice(1).forEach((line) => console.log(line));

  const passed = finalStats.p95Latency < 1000 && finalStats.successRate > 99;
  const resultLine = passed
    ? '[PASS] Performance criteria met! (p95 < 1000ms, Success > 99%)'
    : '[FAIL] Performance criteria failed! (p95 >= 1000ms or Success <= 99%)';

  if (REPORT_PATH) {
    const report = [
      'Performance Testing Report',
      '==========================',
      `Generated: ${new Date().toISOString()}`,
      `Target: ${TARGET_URL}`,
      `Concurrency: ${CONCURRENCY}`,
      `DurationSeconds: ${DURATION_MS / 1000}`,
      `LiveIntervalSeconds: ${LIVE_INTERVAL_MS / 1000}`,
      '',
      'Measurement Method:',
      '- requestStartTime = Date.now() truoc khi gui request',
      '- latency = Date.now() - requestStartTime khi nhan response',
      '- success/fail duoc dem ngay khi request hoan thanh',
      '- p95 duoc tinh tu toan bo mau latency da thu thap',
      '',
      'Meaning Of Metrics:',
      '- Started / Total Started: tong so request da duoc gui',
      '- New This Second: so request moi trong 1 giay',
      '- In Flight: request dang xu ly, chua co response',
      '- Success / Fail: ket qua request sau khi hoan thanh',
      '- Avg Latency: thoi gian phan hoi trung binh',
      '- P95 Latency: 95% request co latency <= muc nay',
      '- Throughput: so request xu ly duoc moi giay',
      '- Success Rate: ty le request thanh cong',
      '',
      ...liveHistory,
      ...summaryLines,
      resultLine
    ].join('\n');

    fs.writeFileSync(REPORT_PATH, report, 'utf8');
  }

  if (passed) {
    console.log(`\x1b[32m${resultLine}\x1b[0m\n`);
    process.exit(0);
  }

  console.log(`\x1b[31m${resultLine}\x1b[0m\n`);
  process.exit(1);
}

runTest();
