// Gives every professor without a login the account <code>@gmail.com / <code>123 (lowercase),
// e.g. pv@gmail.com / pv123. Safe to re-run: professors who already have a login are skipped.
// Called by `npm run seed`; also run on its own with `npm run prof-logins`.
import { assertConfig } from '../src/config.js';
import { pool } from '../src/db.js';
import { authAdmin, deleteAuthUser, sbPassword } from '../src/lib/supabase.js';

export async function createProfessorLogins() {
  const { rows } = await pool.query(
    `SELECT u.id, u.name, p.code FROM professors p JOIN users u ON u.id = p.user_id
      WHERE u.auth_id IS NULL ORDER BY p.code`);
  let made = 0;
  for (const p of rows) {
    const code = p.code.toLowerCase();
    const email = `${code}@gmail.com`;
    const { rows: [clash] } = await pool.query('SELECT 1 FROM users WHERE lower(email) = $1', [email]);
    if (clash) { console.warn(`skip ${p.code}: ${email} is already used`); continue; }
    const { data, error } = await authAdmin().createUser({
      email, password: sbPassword(`${code}123`), email_confirm: true, user_metadata: { name: p.name, role: 'professor' },
    });
    if (error) { console.warn(`skip ${p.code}: ${error.message}`); continue; }
    try {
      await pool.query('UPDATE users SET email = $1, auth_id = $2 WHERE id = $3', [email, data.user.id, p.id]);
      made++;
    } catch (err) {
      await deleteAuthUser(data.user.id);
      console.warn(`skip ${p.code}: ${err.message}`);
    }
  }
  console.log(`Professor logins created: ${made} (email <code>@gmail.com, password <code>123)`);
}

if (import.meta.url === new URL(process.argv[1], 'file://').href || process.argv[1]?.endsWith('prof-logins.js')) {
  assertConfig();
  try { await createProfessorLogins(); } finally { await pool.end(); }
}
