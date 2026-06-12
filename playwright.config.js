const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
  testDir: '.',
  testMatch: [
    '**/Topic 2 - API Testing/**/*.spec.js',
    '**/Topic 3 - Web E2E Testing/**/*.spec.js',
    '**/Topic 6 - Visual Regression/**/*.spec.js'
  ],
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1, // Single-worker to prevent conflicts when starting local servers
  reporter: 'list', // Concise list reporting
  use: {
    baseURL: process.env.DATETIMECHECKER_URL || 'http://localhost:4173',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    }
  ],
  webServer: {
    command: 'powershell -NoProfile -ExecutionPolicy Bypass -Command ". ./scripts/common.ps1; Stop-RunningServer; java -cp out/classes com.datetimechecker.App"',
    url: 'http://localhost:4173',
    reuseExistingServer: !process.env.CI,
    stdout: 'ignore',
    stderr: 'pipe',
  },
});
