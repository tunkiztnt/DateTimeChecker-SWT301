const { test, expect } = require('@playwright/test');

test.describe('API Testing @api', () => {
  
  test('API01: Valid normal date (30/05/2026)', async ({ request }) => {
    const startTime = Date.now();
    const response = await request.post('/api/datetime/check', {
      data: { day: '30', month: '5', year: '2026' }
    });
    const duration = Date.now() - startTime;

    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.valid).toBe(true);
    expect(json.errors).toEqual([]);
    expect(json.parts).toEqual({ day: 30, month: 5, year: 2026 });
    expect(json.details.display).toBe('30/05/2026');
    expect(json.details.leapYear).toBe('Không');
    expect(duration).toBeLessThan(1000); // Max 1 second requirement
  });

  test('API02: Invalid day in month (31/04/2026)', async ({ request }) => {
    const response = await request.post('/api/datetime/check', {
      data: { day: '31', month: '4', year: '2026' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.valid).toBe(false);
    expect(json.errors.some(err => err.includes('chỉ có 30 ngày'))).toBe(true);
  });

  test('API03: Leap year valid (29/02/2024)', async ({ request }) => {
    const response = await request.post('/api/datetime/check', {
      data: { day: '29', month: '2', year: '2024' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.valid).toBe(true);
    expect(json.details.leapYear).toBe('Có');
  });

  test('API04: Non-leap year invalid (29/02/2025)', async ({ request }) => {
    const response = await request.post('/api/datetime/check', {
      data: { day: '29', month: '2', year: '2025' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.valid).toBe(false);
  });

  test('API05: Out of range day (0/05/2026)', async ({ request }) => {
    const response = await request.post('/api/datetime/check', {
      data: { day: '0', month: '5', year: '2026' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.valid).toBe(false);
  });

  test('API06: Out of range month (30/13/2026)', async ({ request }) => {
    const response = await request.post('/api/datetime/check', {
      data: { day: '30', month: '13', year: '2026' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.valid).toBe(false);
  });

  test('API07: Empty parameter validation', async ({ request }) => {
    const response = await request.post('/api/datetime/check', {
      data: { day: '', month: '5', year: '2026' }
    });
    
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.valid).toBe(false);
  });
});
