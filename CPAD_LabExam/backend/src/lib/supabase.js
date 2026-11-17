// Supabase Auth owns sign up / sign in. The backend talks to it with the service role key and then
// issues its own app token (see middleware/auth.js), so the rest of the API is unchanged.
import { createClient } from '@supabase/supabase-js';
import { config } from '../config.js';

const opts = { auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } };

/** A fresh client each time, so a signed-in user's session never sticks to a shared client. */
export const authClient = () => createClient(config.supabaseUrl, config.supabaseKey, opts);

let admin;
/** Supabase Auth admin API (create / update / delete auth users). */
export const authAdmin = () => (admin ??= authClient()).auth.admin;

/** Deletes a Supabase Auth user, ignoring "already gone". */
export async function deleteAuthUser(authId) {
  if (!authId) return;
  const { error } = await authAdmin().deleteUser(authId);
  if (error && error.status !== 404) console.warn(`Could not delete auth user ${authId}: ${error.message}`);
}

/**
 * Supabase needs 6+ characters. Professor demo logins use `<code>123`, which is only 5 for two-letter
 * codes like PV, so short passwords are padded the same way on create and on login.
 * (Sign-up still requires 6+, so this never weakens a real account.)
 */
export const sbPassword = (p) => p.padEnd(6, '_');
