// Master data management for admins: users, branches, years, sections, rooms, subjects,
// professor-subject assignments / backup tags, ticket categories and the timetable.
import { Router } from 'express';
import { z } from 'zod';
import { query, tx } from '../db.js';
import { HttpError, badRequest, conflict, notFound, parse } from '../lib/http.js';
import { authAdmin, deleteAuthUser } from '../lib/supabase.js';
import { getPeriods } from '../lib/time.js';

export const router = Router();

const str = z.string().trim().min(1);
const optStr = z.string().trim().optional().nullable().transform((v) => v || null);
const int = z.coerce.number().int();
const optInt = z.preprocess(
  (v) => (v === '' || v === null || v === undefined ? null : Number(v)),
  z.number().int().nullable(),
);
const bool = z.preprocess((v) => v === true || v === 'true' || v === 1, z.boolean());

const RESOURCES = {
  branches: {
    fields: { code: str, name: str },
    list: 'SELECT * FROM branches ORDER BY code',
  },
  years: {
    fields: { code: str, name: str, ord: int },
    list: 'SELECT * FROM years ORDER BY ord',
  },
  sections: {
    fields: { branch_id: int, year_id: int, name: str, strength: int },
    list: `SELECT s.*, b.code AS branch_code, y.code AS year_code,
                  (SELECT COUNT(*) FROM students st WHERE st.section_id = s.id) AS students
             FROM sections s JOIN branches b ON b.id = s.branch_id JOIN years y ON y.id = s.year_id
            ORDER BY b.code, y.ord, s.name`,
  },
  rooms: {
    fields: { name: str, type: z.enum(['classroom', 'lab']), capacity: int, building: optStr, bookable: bool },
    list: 'SELECT * FROM rooms ORDER BY type, name',
  },
  subjects: {
    fields: { code: str, name: str, branch_id: optInt },
    list: `SELECT s.*, b.code AS branch_code FROM subjects s LEFT JOIN branches b ON b.id = s.branch_id ORDER BY s.code`,
  },
  professor_subjects: {
    fields: { professor_id: int, subject_id: int, is_backup: bool, rank: int },
    list: `SELECT ps.*, u.name AS professor_name, p.code AS professor_code, s.code AS subject_code, s.name AS subject_name
             FROM professor_subjects ps JOIN professors p ON p.user_id = ps.professor_id
             JOIN users u ON u.id = ps.professor_id JOIN subjects s ON s.id = ps.subject_id
            ORDER BY s.code, ps.is_backup, ps.rank`,
  },
  ticket_categories: {
    fields: { code: str, name: str, sla_hours: int },
    list: 'SELECT * FROM ticket_categories ORDER BY name',
  },
  timetable_entries: {
    fields: {
      section_id: int, day: int, period_start: int, period_end: int, subject_id: int,
      professor_id: optInt, room_id: optInt, kind: z.enum(['theory', 'lab', 'project']),
      label: optStr, batch: optStr, parallel_group: optStr,
    },
    list: `SELECT e.*, s.code AS subject_code, r.name AS room_name, p.code AS professor_code,
                  b.code || ' ' || y.code || '-' || sec.name AS section_label
             FROM timetable_entries e JOIN subjects s ON s.id = e.subject_id
             JOIN sections sec ON sec.id = e.section_id JOIN branches b ON b.id = sec.branch_id JOIN years y ON y.id = sec.year_id
             LEFT JOIN rooms r ON r.id = e.room_id LEFT JOIN professors p ON p.user_id = e.professor_id
            ORDER BY section_label, e.day, e.period_start`,
    validate: validateTimetableEntry,
  },
};

/** No clashes in the weekly grid: same section (unless parallel), same professor or same room. */
async function validateTimetableEntry(db, row, id) {
  if (row.day < 1 || row.day > 5) throw badRequest('Day must be 1 (Monday) to 5 (Friday)');
  if (row.period_end < row.period_start) throw badRequest('End period must be after start period');
  const periods = await getPeriods(db);
  if (![row.period_start, row.period_end].every((p) => periods.some((x) => x.period === p))) throw badRequest('Unknown period');
  const { rows } = await db.query(
    `SELECT e.*, s.code AS subject_code FROM timetable_entries e JOIN subjects s ON s.id = e.subject_id
      WHERE e.day = $1 AND e.period_start <= $3 AND $2 <= e.period_end AND ($4::int IS NULL OR e.id <> $4)`,
    [row.day, row.period_start, row.period_end, id ?? null]);
  for (const o of rows) {
    const parallel = row.parallel_group && row.parallel_group === o.parallel_group;
    if (o.section_id === row.section_id && !parallel) throw conflict(`The section already has ${o.subject_code} then`);
    if (row.professor_id && o.professor_id === row.professor_id) throw conflict(`That professor already teaches ${o.subject_code} then`);
    if (row.room_id && o.room_id === row.room_id) throw conflict(`That room already has ${o.subject_code} then`);
  }
}

function resource(name) {
  const r = RESOURCES[name];
  if (!r) throw notFound('Unknown resource');
  return r;
}

router.get('/options', async (_req, res) => {
  const [branches, years, sections, rooms, subjects, professors, categories] = await Promise.all([
    query('SELECT id, code AS label FROM branches ORDER BY code'),
    query('SELECT id, code AS label FROM years ORDER BY ord'),
    query(`SELECT s.id, b.code || ' ' || y.code || '-' || s.name AS label FROM sections s
             JOIN branches b ON b.id = s.branch_id JOIN years y ON y.id = s.year_id ORDER BY label`),
    query('SELECT id, name AS label FROM rooms ORDER BY name'),
    query(`SELECT id, code || ' - ' || name AS label FROM subjects ORDER BY code`),
    query(`SELECT p.user_id AS id, u.name || ' (' || p.code || ')' AS label FROM professors p JOIN users u ON u.id = p.user_id ORDER BY u.name`),
    query('SELECT id, name AS label FROM ticket_categories ORDER BY name'),
  ]);
  const periods = (await getPeriods()).map((p) => ({ id: p.period, label: `P${p.period} ${p.start}` }));
  res.json({
    branch_id: branches.rows, year_id: years.rows, section_id: sections.rows, room_id: rooms.rows,
    subject_id: subjects.rows, professor_id: professors.rows, category_id: categories.rows,
    period_start: periods, period_end: periods,
    day: [1, 2, 3, 4, 5].map((d) => ({ id: d, label: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'][d - 1] })),
  });
});

// ------------------------------------------------------------------ users

const USER_SQL = `
  SELECT u.id, u.email, u.name, u.role, u.phone,
         st.roll_no, st.section_id, b.code || ' ' || y.code || '-' || sec.name AS section_label,
         p.code, p.cabin, p.department_id, a.title, a.level,
         (SELECT array_agg(category_id) FROM admin_categories ac WHERE ac.admin_id = u.id) AS category_ids
    FROM users u
    LEFT JOIN students st ON st.user_id = u.id LEFT JOIN sections sec ON sec.id = st.section_id
    LEFT JOIN branches b ON b.id = sec.branch_id LEFT JOIN years y ON y.id = sec.year_id
    LEFT JOIN professors p ON p.user_id = u.id LEFT JOIN admins a ON a.user_id = u.id`;

const UserBody = z.object({
  role: z.enum(['student', 'professor', 'admin']),
  name: str, email: z.string().trim().toLowerCase().email(), phone: optStr,
  password: z.string().min(6, 'Password needs at least 6 characters').optional(),
  section_id: optInt, roll_no: optStr,
  code: optStr, cabin: optStr, department_id: optInt,
  title: optStr, level: optInt, category_ids: z.array(int).optional().nullable(),
});

async function writeProfile(db, id, u) {
  if (u.role === 'student') {
    if (!u.section_id || !u.roll_no) throw badRequest('Students need a section and roll number');
    await db.query(`INSERT INTO students (user_id, section_id, roll_no) VALUES ($1, $2, $3)
                    ON CONFLICT (user_id) DO UPDATE SET section_id = $2, roll_no = $3`, [id, u.section_id, u.roll_no]);
  } else if (u.role === 'professor') {
    if (!u.code) throw badRequest('Professors need a short code (e.g. PV)');
    await db.query(`INSERT INTO professors (user_id, code, cabin, department_id) VALUES ($1, $2, $3, $4)
                    ON CONFLICT (user_id) DO UPDATE SET code = $2, cabin = $3, department_id = $4`,
    [id, u.code.toUpperCase(), u.cabin, u.department_id]);
  } else {
    if (!u.title || !u.level) throw badRequest('Admins need a title and level (1 handler, 2 HOD, 3 dean)');
    await db.query(`INSERT INTO admins (user_id, title, level) VALUES ($1, $2, $3)
                    ON CONFLICT (user_id) DO UPDATE SET title = $2, level = $3`, [id, u.title, u.level]);
    if (u.category_ids) {
      await db.query('DELETE FROM admin_categories WHERE admin_id = $1', [id]);
      for (const c of u.category_ids) await db.query('INSERT INTO admin_categories VALUES ($1, $2)', [id, c]);
    }
  }
}

router.get('/users', async (req, res) => {
  const role = ['student', 'professor', 'admin'].includes(req.query.role) ? req.query.role : null;
  const { rows } = await query(`${USER_SQL} WHERE ($1::text IS NULL OR u.role = $1) ORDER BY u.role, u.name`, [role]);
  res.json({ rows });
});

const authFail = (error) => new HttpError(error.status && error.status < 500 ? 400 : 502, `Supabase Auth: ${error.message}`);

/** Creates a confirmed Supabase Auth login for a user (admins set the password, no email is sent). */
async function createLogin(u) {
  const { data, error } = await authAdmin().createUser({
    email: u.email, password: u.password, email_confirm: true, user_metadata: { name: u.name, role: u.role },
  });
  if (error) throw authFail(error);
  return data.user.id;
}

router.post('/users', async (req, res) => {
  const u = parse(UserBody, req.body);
  if (!u.password) throw badRequest('Set an initial password');
  const { rows: [taken] } = await query('SELECT 1 FROM users WHERE lower(email) = $1', [u.email]);
  if (taken) throw conflict('A user with this email already exists');
  const authId = await createLogin(u);
  try {
    const row = await tx(async (db) => {
      const { rows: [created] } = await db.query(
        'INSERT INTO users (email, auth_id, name, role, phone) VALUES ($1, $2, $3, $4, $5) RETURNING id',
        [u.email, authId, u.name, u.role, u.phone]);
      await writeProfile(db, created.id, u);
      return created;
    });
    res.status(201).json({ row });
  } catch (err) {
    await deleteAuthUser(authId);
    throw err;
  }
});

router.put('/users/:id', async (req, res) => {
  const id = Number(req.params.id) || 0;
  const { rows: [existing] } = await query('SELECT role, email, auth_id FROM users WHERE id = $1', [id]);
  if (!existing) throw notFound('User not found');
  const u = parse(UserBody, { ...req.body, role: existing.role });  // role cannot change
  await tx(async (db) => {
    await db.query('UPDATE users SET name = $1, email = $2, phone = $3 WHERE id = $4', [u.name, u.email, u.phone, id]);
    await writeProfile(db, id, u);
    // Keep the Supabase Auth login in step. A user without one (e.g. seeded data) gets one once a password is set.
    if (existing.auth_id) {
      const changes = {};
      if (u.email !== existing.email) Object.assign(changes, { email: u.email, email_confirm: true });
      if (u.password) changes.password = u.password;
      if (Object.keys(changes).length) {
        const { error } = await authAdmin().updateUserById(existing.auth_id, changes);
        if (error) throw authFail(error);
      }
    } else if (u.password) {
      const authId = await createLogin(u);
      try {
        await db.query('UPDATE users SET auth_id = $1 WHERE id = $2', [authId, id]);
      } catch (err) {
        await deleteAuthUser(authId);
        throw err;
      }
    }
  });
  res.json({ ok: true });
});

router.delete('/users/:id', async (req, res) => {
  const id = Number(req.params.id) || 0;
  if (id === req.user.id) throw badRequest('You cannot delete your own account');
  const { rows: [gone] } = await query('DELETE FROM users WHERE id = $1 RETURNING auth_id', [id]);
  if (!gone) throw notFound('User not found');
  await deleteAuthUser(gone.auth_id);
  res.json({ ok: true });
});

// ------------------------------------------------------------------ generic resources

router.get('/:resource', async (req, res) => {
  const { rows } = await query(resource(req.params.resource).list);
  res.json({ rows });
});

router.post('/:resource', async (req, res) => {
  const name = req.params.resource;
  const r = resource(name);
  const row = parse(z.object(r.fields), req.body);
  const out = await tx(async (db) => {
    if (r.validate) await r.validate(db, row, null);
    const cols = Object.keys(row);
    const { rows: [x] } = await db.query(
      `INSERT INTO ${name} (${cols.join(', ')}) VALUES (${cols.map((_, i) => `$${i + 1}`).join(', ')}) RETURNING *`,
      cols.map((c) => row[c]));
    return x;
  });
  res.status(201).json({ row: out });
});

router.put('/:resource/:id', async (req, res) => {
  const name = req.params.resource;
  const r = resource(name);
  const id = Number(req.params.id) || 0;
  const { rows: [current] } = await query(`SELECT * FROM ${name} WHERE id = $1`, [id]);
  if (!current) throw notFound('Record not found');
  const merged = parse(z.object(r.fields), { ...current, ...req.body });
  const out = await tx(async (db) => {
    if (r.validate) await r.validate(db, merged, id);
    const cols = Object.keys(merged);
    const { rows: [x] } = await db.query(
      `UPDATE ${name} SET ${cols.map((c, i) => `${c} = $${i + 1}`).join(', ')} WHERE id = $${cols.length + 1} RETURNING *`,
      [...cols.map((c) => merged[c]), id]);
    return x;
  });
  res.json({ row: out });
});

router.delete('/:resource/:id', async (req, res) => {
  const name = req.params.resource;
  resource(name);
  const { rowCount } = await query(`DELETE FROM ${name} WHERE id = $1`, [Number(req.params.id) || 0]);
  if (!rowCount) throw notFound('Record not found');
  res.json({ ok: true });
});
