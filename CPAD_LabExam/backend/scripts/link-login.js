// Gives an existing CampusSphere user (e.g. a seeded admin or professor) a Supabase Auth login.
// Usage: npm run link-login -- <current-email-in-db> <login-email> <password>
// The login email may be the same as the current one; the user's email is updated to it.
import { assertConfig } from '../src/config.js';
import { pool } from '../src/db.js';
import { authAdmin, deleteAuthUser } from '../src/lib/supabase.js';

assertConfig();
const [current, loginEmailArg, password] = process.argv.slice(2);
if (!current || !loginEmailArg || !password) {
  console.error('Usage: npm run link-login -- <current-email-in-db> <login-email> <password>');
  process.exit(1);
}
const loginEmail = loginEmailArg.trim().toLowerCase();
if (password.length < 6) {
  console.error('Password needs at least 6 characters');
  process.exit(1);
}

try {
  const { rows: [u] } = await pool.query('SELECT id, name, role, auth_id FROM users WHERE lower(email) = lower($1)', [current]);
  if (!u) throw new Error(`No user with email ${current}`);
  if (u.auth_id) throw new Error(`${current} already has a login. Change its password from the admin Master data screen.`);
  if (loginEmail !== current.toLowerCase()) {
    const { rows: [clash] } = await pool.query('SELECT 1 FROM users WHERE lower(email) = $1', [loginEmail]);
    if (clash) throw new Error(`${loginEmail} is already used by another user`);
  }
  const { data, error } = await authAdmin().createUser({
    email: loginEmail, password, email_confirm: true, user_metadata: { name: u.name, role: u.role },
  });
  if (error) throw new Error(`Supabase Auth: ${error.message}`);
  try {
    await pool.query('UPDATE users SET email = $1, auth_id = $2 WHERE id = $3', [loginEmail, data.user.id, u.id]);
  } catch (err) {
    await deleteAuthUser(data.user.id);
    throw err;
  }
  console.log(`${u.name} (${u.role}) can now log in as ${loginEmail}`);
} catch (err) {
  console.error(err.message);
  process.exitCode = 1;
} finally {
  await pool.end();
}
