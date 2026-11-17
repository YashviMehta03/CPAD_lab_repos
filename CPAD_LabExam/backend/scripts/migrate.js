// Applies migrations/*.sql in order, each once, inside a transaction.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { assertConfig } from '../src/config.js';
import { pool } from '../src/db.js';

assertConfig();
const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'migrations');

const client = await pool.connect();
try {
  await client.query(`CREATE TABLE IF NOT EXISTS schema_migrations (
    name TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now())`);
  const { rows } = await client.query('SELECT name FROM schema_migrations');
  const done = new Set(rows.map((r) => r.name));
  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
  let applied = 0;
  for (const f of files) {
    if (done.has(f)) continue;
    const sql = fs.readFileSync(path.join(dir, f), 'utf8');
    await client.query('BEGIN');
    try {
      await client.query(sql);
      await client.query('INSERT INTO schema_migrations(name) VALUES ($1)', [f]);
      await client.query('COMMIT');
      console.log(`applied ${f}`);
      applied++;
    } catch (err) {
      await client.query('ROLLBACK');
      console.error(`failed ${f}: ${err.message}`);
      process.exitCode = 1;
      break;
    }
  }
  if (!applied && !process.exitCode) console.log('database is up to date');
} finally {
  client.release();
  await pool.end();
}
