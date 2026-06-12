const { test, expect } = require('@playwright/test');

test.describe('API Testing @api', () => {
  test.beforeEach(async ({}, testInfo) => {
    console.log(`\n[PLAYWRIGHT API] Running: ${testInfo.title}`);
    console.log('[FLOW] Build request -> POST API -> read JSON -> assert expected result');
  });
  
  test('API01: Valid normal date (30/05/2026) @api', async ({ request }) => {
    const startTime = Date.now();
    const response = await request.post('/api/check-date', {
      data: { day: '30', month: '5', year: '2026' }
    });
    const duration = Date.now() - startTime;

    expect(response.status()).toBe(200);
    const json = await response.json();
    console.log(`[ACTUAL] HTTP=${response.status()} valid=${json.valid} result=${json.result} time=${duration}ms`);
    expect(json.valid).toBe(true);
    expect(json.result).toBe('VALID');
    expect(json.errors).toEqual([]);
    expect(json.parts).toEqual({ day: 30, month: 5, year: 2026 });
    expect(json.details.display).toBe('30/05/2026');
    expect(json.details.leapYear).toBe('Không');
    expect(duration).toBeLessThan(1000); // Max 1 second requirement
  });

  test('API02: Invalid day in month (31/04/2026) @api', async ({ request }) => {
    const response = await request.post('/api/check-date', {
      data: { day: '31', month: '4', year: '2026' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    console.log(`[ACTUAL] HTTP=${response.status()} valid=${json.valid} errors=${json.errors.join(' | ')}`);
    expect(json.valid).toBe(false);
    expect(json.result).toBe('INVALID');
    expect(json.errors.some(err => err.includes('chỉ có 30 ngày'))).toBe(true);
  });

  test('API03: Leap year valid (29/02/2024) @api', async ({ request }) => {
    const response = await request.post('/api/check-date', {
      data: { day: '29', month: '2', year: '2024' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    console.log(`[ACTUAL] HTTP=${response.status()} valid=${json.valid} leapYear=${json.details.leapYear}`);
    expect(json.valid).toBe(true);
    expect(json.result).toBe('VALID');
    expect(json.details.leapYear).toBe('Có');
  });

  test('API04: Non-leap year invalid (29/02/2025) @api', async ({ request }) => {
    const response = await request.post('/api/check-date', {
      data: { day: '29', month: '2', year: '2025' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    console.log(`[ACTUAL] HTTP=${response.status()} valid=${json.valid} result=${json.result}`);
    expect(json.valid).toBe(false);
    expect(json.result).toBe('INVALID');
  });

  test('API05: Out of range day (0/05/2026) @api', async ({ request }) => {
    const response = await request.post('/api/check-date', {
      data: { day: '0', month: '5', year: '2026' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    console.log(`[ACTUAL] HTTP=${response.status()} valid=${json.valid} result=${json.result}`);
    expect(json.valid).toBe(false);
    expect(json.result).toBe('ERROR');
  });

  test('API06: Out of range month (30/13/2026) @api', async ({ request }) => {
    const response = await request.post('/api/check-date', {
      data: { day: '30', month: '13', year: '2026' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    console.log(`[ACTUAL] HTTP=${response.status()} valid=${json.valid} result=${json.result}`);
    expect(json.valid).toBe(false);
    expect(json.result).toBe('ERROR');
  });

  test('API07: Empty parameter validation @api', async ({ request }) => {
    const response = await request.post('/api/check-date', {
      data: { day: '', month: '5', year: '2026' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    console.log(`[ACTUAL] HTTP=${response.status()} valid=${json.valid} result=${json.result}`);
    expect(json.valid).toBe(false);
    expect(json.result).toBe('ERROR');
  });

  test('API08: Response time must be under 1000ms @api', async ({ request }) => {
    const startTime = Date.now();
    const response = await request.post('/api/check-date', {
      data: { day: '15', month: '6', year: '2023' }
    });
    const endTime = Date.now();
    const responseTime = endTime - startTime;
    console.log(`[ACTUAL] HTTP=${response.status()} responseTime=${responseTime}ms, threshold<1000ms`);

    expect(response.status()).toBe(200);
    expect(responseTime).toBeLessThan(1000);
  });

  test('API09: All 4 error message types are present in responses @api', async ({ request }) => {
    // 1. Format/type error (non-numeric)
    const r1 = await request.post('/api/check-date', {
      data: { day: 'abc', month: '5', year: '2026' }
    });
    const j1 = await r1.json();
    expect(j1.result).toBe('ERROR');
    expect(j1.message.toLowerCase()).toContain('số nguyên');

    // 2. Out of range error
    const r2 = await request.post('/api/check-date', {
      data: { day: '99', month: '5', year: '2026' }
    });
    const j2 = await r2.json();
    expect(j2.result).toBe('ERROR');
    expect(j2.message.toLowerCase()).toContain('khoảng');

    // 3. Valid date
    const r3 = await request.post('/api/check-date', {
      data: { day: '15', month: '6', year: '2023' }
    });
    const j3 = await r3.json();
    expect(j3.result).toBe('VALID');

    // 4. Invalid date (Feb 30)
    const r4 = await request.post('/api/check-date', {
      data: { day: '30', month: '2', year: '2024' }
    });
    const j4 = await r4.json();
    console.log(`[ACTUAL] format=${j1.result}, range=${j2.result}, valid=${j3.result}, invalidDate=${j4.result}`);
    expect(j4.result).toBe('INVALID');
  });

  test('API10: Concurrent requests (5 simultaneous) @api', async ({ request }) => {
    const requests = Array.from({ length: 5 }, () => 
      request.post('/api/check-date', {
        data: { day: '15', month: '6', year: '2023' }
      })
    );

    const startTime = Date.now();
    const responses = await Promise.all(requests);
    const duration = Date.now() - startTime;
    console.log(`[ACTUAL] concurrentRequests=${responses.length}, totalTime=${duration}ms`);

    for (const res of responses) {
      expect(res.status()).toBe(200);
      const json = await res.json();
      expect(json.result).toBe('VALID');
    }
    expect(duration).toBeLessThan(2000); // Concurrency limits
  });

});
