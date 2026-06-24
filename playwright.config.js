const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './topics',
  timeout: 25000,
  expect: {
    timeout: 3000,
    toHaveScreenshot: {
      pathTemplate: '{testDir}/{testFileDir}/baseline-images/{arg}-{platform}{ext}'
    }
  },
  fullyParallel: false,
  retries: 0,
  workers: 1,
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['list'],
    ['json', { outputFile: 'playwright-report/results.json' }],
    ['allure-playwright', { detail: true, outputFolder: 'allure-results' }]
  ],
  use: {
    baseURL: 'http://localhost:4173',
    actionTimeout: 2000, // Limit action wait to 2s instead of full test timeout
    headless: process.env.HEADLESS === 'true' ? true : false, // Defaults to false so browser opens on screen, but can be overridden via env var
    viewport: { width: 1280, height: 720 },
    launchOptions: {
      slowMo: 400, // Slow down execution by 400ms per action for easier tracking
    },
  },
});
