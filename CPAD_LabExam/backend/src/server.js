import { assertConfig, config } from './config.js';
import { createApp } from './app.js';
import { startEscalationJob } from './lib/escalation.js';
import { storageMode } from './lib/storage.js';
import { nowIST } from './lib/time.js';

assertConfig();
const app = createApp();
app.listen(config.port, '0.0.0.0', () => {
  const now = nowIST();
  console.log(`CampusSphere API on http://localhost:${config.port}/api`);
  console.log(`Photo storage: ${storageMode}. Campus clock: ${now.date} ${String(Math.floor(now.minutes / 60)).padStart(2, '0')}:${String(now.minutes % 60).padStart(2, '0')} IST${config.demoNow ? ' (DEMO_NOW)' : ''}`);
});
startEscalationJob();
