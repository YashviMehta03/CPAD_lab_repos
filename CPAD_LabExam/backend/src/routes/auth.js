import { Router } from 'express';
import { z } from 'zod';
import { query, tx } from '../db.js';
import { HttpError, badRequest, conflict, parse } from '../lib/http.js';
import { authAdmin, authClient, deleteAuthUser, sbPassword } from '../lib/supabase.js';
import { authenticate, signToken } from '../middleware/auth.js';

export const router = Router();

/** The user plus their role-specific profile. */
export async function getProfile(userId) {
  const { rows: [u] } = await query('SELECT id, email, name, role, phone FROM users WHERE id = $1', [userId]);
  if (!u) return null;
  if (u.role === 'student') {
    const { rows: [s] } = await query(
      `SELECT st.roll_no, st.section_id, sec.name AS section_name, b.id AS branch_id, b.code AS branch_code,
              b.name AS branch_name, y.id AS year_id, y.code AS year_code, y.name AS year_name
         FROM students st JOIN sections sec ON sec.id = st.section_id
         JOIN branches b ON b.id = sec.branch_id JOIN years y ON y.id = sec.year_id
        WHERE st.user_id = $1`, [userId]);
    u.student = s ?? null;
  } else if (u.role === 'professor') {
    const { rows: [p] } = await query(
      `SELECT p.code, p.cabin, p.manual_status, p.status_note, b.code AS department
         FROM professors p LEFT JOIN branches b ON b.id = p.department_id WHERE p.user_id = $1`, [userId]);
    u.professor = p ?? null;
  } else if (u.role === 'admin') {
    const { rows: [a] } = await query('SELECT title, level FROM admins WHERE user_id = $1', [userId]);
    const { rows: cats } = await query(
      `SELECT c.id, c.code, c.name FROM admin_categories ac JOIN ticket_categories c ON c.id = ac.category_id
        WHERE ac.admin_id = $1 ORDER BY c.name`, [userId]);
    u.admin = a ? { ...a, categories: cats } : null;
  }
  return u;
}

/** Branches, years and sections for the sign-up form (public: the user is not logged in yet). */
router.get('/options', async (_req, res) => {
  const [branches, years, sections] = await Promise.all([
    query('SELECT id, code, name FROM branches ORDER BY code'),
    query('SELECT id, code, name, ord FROM years ORDER BY ord'),
    query(`SELECT s.id, s.name, s.branch_id, s.year_id, b.code AS branch_code, y.code AS year_code
             FROM sections s JOIN branches b ON b.id = s.branch_id JOIN years y ON y.id = s.year_id
            ORDER BY b.code, y.ord, s.name`),
  ]);
  res.json({ branches: branches.rows, years: years.rows, sections: sections.rows });
});

const optStr = z.string().trim().optional().nullable().transform((v) => v || null);
const optInt = z.preprocess((v) => (v === '' || v == null ? null : Number(v)), z.number().int().nullable());

// Only students and professors can register themselves. Admin accounts are created by an admin.
const SignupBody = z.object({
  role: z.enum(['student', 'professor']),
  name: z.string().trim().min(2, 'Enter your full name'),
  email: z.string().trim().toLowerCase().email('Enter a valid email'),
  password: z.string().min(6, 'Password needs at least 6 characters'),
  phone: optStr,
  section_id: optInt, roll_no: optStr,
  code: optStr, department_id: optInt, cabin: optStr,
});

/** Checks the profile part before an auth account is created, so bad input never leaves an orphan. */
async function checkSignup(b) {
  const { rows: [taken] } = await query('SELECT 1 FROM users WHERE lower(email) = $1', [b.email]);
  if (taken) throw conflict('An account with this email already exists. Log in instead.');
  if (b.role === 'student') {
    if (!b.section_id || !b.roll_no) throw badRequest('Pick your section and enter your roll number');
    const { rows: [sec] } = await query('SELECT 1 FROM sections WHERE id = $1', [b.section_id]);
    if (!sec) throw badRequest('That section does not exist');
    const { rows: [dup] } = await query('SELECT 1 FROM students WHERE upper(roll_no) = upper($1)', [b.roll_no]);
    if (dup) throw conflict('That roll number is already registered');
  } else {
    if (!b.code) throw badRequest('Enter your faculty short code (e.g. PV)');
    const { rows: [dup] } = await query('SELECT 1 FROM professors WHERE upper(code) = upper($1)', [b.code]);
    if (dup) throw conflict('That faculty code is already registered');
    if (b.department_id) {
      const { rows: [d] } = await query('SELECT 1 FROM branches WHERE id = $1', [b.department_id]);
      if (!d) throw badRequest('That department does not exist');
    }
  }
}

/** Sign up: Supabase Auth creates the account, we store the profile and log the user straight in. */
router.post('/signup', async (req, res) => {
  const b = parse(SignupBody, req.body);
  await checkSignup(b);

  // The admin API creates an already-confirmed account: no confirmation email, and no
  // Supabase check that the address is a "real" mailbox, so test addresses like a@campus.test work.
  const { data, error } = await authAdmin().createUser({
    email: b.email, password: b.password, email_confirm: true, user_metadata: { name: b.name, role: b.role },
  });
  if (error) {
    if (error.code === 'email_exists') throw conflict('An account with this email already exists. Log in instead.');
    throw new HttpError(error.status && error.status < 500 ? 400 : 502, error.message);
  }

  let created;
  try {
    created = await tx(async (db) => {
      const { rows: [u] } = await db.query(
        'INSERT INTO users (email, auth_id, name, role, phone) VALUES ($1, $2, $3, $4, $5) RETURNING id, role',
        [b.email, data.user.id, b.name, b.role, b.phone]);
      if (b.role === 'student') {
        await db.query('INSERT INTO students (user_id, section_id, roll_no) VALUES ($1, $2, $3)',
          [u.id, b.section_id, b.roll_no.toUpperCase()]);
      } else {
        await db.query('INSERT INTO professors (user_id, code, department_id, cabin) VALUES ($1, $2, $3, $4)',
          [u.id, b.code.toUpperCase(), b.department_id, b.cabin]);
      }
      return u;
    });
  } catch (err) {
    await deleteAuthUser(data.user.id);  // keep Supabase Auth and our users table in step
    throw err;
  }

  res.status(201).json({ token: signToken(created), user: await getProfile(created.id) });
});

/** Log in: Supabase Auth checks the password, then we hand out the app token for the linked profile. */
router.post('/login', async (req, res) => {
  const { email, password } = parse(
    z.object({ email: z.string().trim().toLowerCase().min(1), password: z.string().min(1) }),
    req.body,
  );
  const { data, error } = await authClient().auth.signInWithPassword({ email, password: sbPassword(password) });
  if (error) {
    if (error.code === 'email_not_confirmed') throw new HttpError(403, 'Confirm your email first: open the link we sent you');
    if (error.code === 'invalid_credentials' || error.status === 400) throw new HttpError(401, 'Wrong email or password');
    throw new HttpError(502, `Sign-in service error: ${error.message}`);
  }
  const { rows: [u] } = await query('SELECT id, role FROM users WHERE auth_id = $1', [data.user.id]);
  if (!u) throw new HttpError(403, 'This login has no CampusSphere profile. Ask an admin to add you.');
  res.json({ token: signToken(u), user: await getProfile(u.id) });
});

router.get('/me', authenticate, async (req, res) => {
  res.json({ user: await getProfile(req.user.id) });
});
