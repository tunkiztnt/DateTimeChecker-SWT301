const { formatDisplay, isValidRange } = require('./date-helpers');

describe('JavaScript UI Date Helpers Unit Tests', () => {
  test('should format single-digit day and month with leading zeros', () => {
    const parts = { day: 5, month: 9, year: 2026 };
    expect(formatDisplay(parts)).toBe('05/09/2026');
  });

  test('should format double-digit day and month correctly', () => {
    const parts = { day: 25, month: 12, year: 2026 };
    expect(formatDisplay(parts)).toBe('25/12/2026');
  });

  test('should validate correct ranges according to URD (1000-3000)', () => {
    expect(isValidRange('15', '6', '2026')).toBe(true);
    expect(isValidRange('1', '1', '1000')).toBe(true);
    expect(isValidRange('31', '12', '3000')).toBe(true);
  });

  test('should reject values out of range', () => {
    expect(isValidRange('0', '6', '2026')).toBe(false);
    expect(isValidRange('32', '6', '2026')).toBe(false);
    expect(isValidRange('15', '0', '2026')).toBe(false);
    expect(isValidRange('15', '13', '2026')).toBe(false);
    expect(isValidRange('15', '6', '999')).toBe(false);
    expect(isValidRange('15', '6', '3001')).toBe(false);
  });

  test('should reject non-integer values', () => {
    expect(isValidRange('abc', '6', '2026')).toBe(false);
    expect(isValidRange('15.5', '6', '2026')).toBe(false);
  });
});
