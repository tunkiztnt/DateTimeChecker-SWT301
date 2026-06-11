import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '5s', target: 20 }, // Ramp-up to 20 users
    { duration: '10s', target: 20 }, // Stay at 20 users
    { duration: '5s', target: 0 },  // Ramp-down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'], // 95% of requests must complete below 200ms
  },
};

export default function () {
  const url = 'http://localhost:4173/api/datetime/check';
  const payload = JSON.stringify({
    day: '30',
    month: '5',
    year: '2026',
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const res = http.post(url, payload, params);
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'is valid date': (r) => {
      try {
        return JSON.parse(r.body).valid === true;
      } catch (e) {
        return false;
      }
    },
  });

  sleep(0.1); // Sleep 100ms between requests for each virtual user
}
