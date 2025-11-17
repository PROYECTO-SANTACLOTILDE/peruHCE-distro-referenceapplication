import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30 * 1000,
  expect: {
    timeout: 5 * 1000,
  },
  use: {
    // Base URL de tu instancia local
    baseURL: 'http://localhost/openmrs',
    headless: true,
  },
});
