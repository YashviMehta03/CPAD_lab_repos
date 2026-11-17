// Targeted broadcasts from professors to a branch, year, section or chosen students.
import { Router } from 'express';
import { z } from 'zod';
import { query, tx } from '../db.js';
import { badRequest, parse } from '../lib/http.js';
import { notifyUsers } from '../lib/notify.js';
import { requireRole } from '../middleware/auth.js';

export const router = Router();

const Target = z.object({
  branch_id: z.coerce.number().int().optional().nullable(),
  year_id: z.coerce.number().int().optional().nullable(),
  section_id: z.coerce.number().int().optional().nullable(),
  student_ids: z.array(z.coerce.number().int()).optional().nullable(),
});

async function resolveRecipients(db, t) {
  if (t.student_ids?.length) {
    const { rows } = await db.query('SELECT user_id FROM students WHERE user_id = ANY($1)', [t.student_ids]);
    return rows.map((r) => r.user_id);
  }
  if (!t.branch_id && !t.year_id && !t.section_id) throw badRequest('Choose a branch, year, section or students');
  const { rows } = await db.query(
    `SELECT st.user_id FROM students st JOIN sections sec ON sec.id = st.section_id
      WHERE ($1::int IS NULL OR sec.branch_id = $1) AND ($2::int IS NULL OR sec.year_id = $2)
        AND ($3::int IS NULL OR sec.id = $3)`,
    [t.branch_id || null, t.year_id || null, t.section_id || null]);
  return rows.map((r) => r.user_id);
}

async function describe(db, t) {
  if (t.student_ids?.length) return `${t.student_ids.length} selected student(s)`;
  const parts = [];
  if (t.section_id) {
    const { rows: [s] } = await db.query(
      `SELECT b.code || ' ' || y.code || '-' || s.name AS n FROM sections s JOIN branches b ON b.id = s.branch_id
         JOIN years y ON y.id = s.year_id WHERE s.id = $1`, [t.section_id]);
    return s ? `Section ${s.n}` : 'Section';
  }
  if (t.branch_id) parts.push((await db.query('SELECT code FROM branches WHERE id = $1', [t.branch_id])).rows[0]?.code);
  if (t.year_id) parts.push((await db.query('SELECT code FROM years WHERE id = $1', [t.year_id])).rows[0]?.code);
  return parts.filter(Boolean).join(' ');
}

/** Preview how many students a target reaches before sending. */
router.post('/preview', requireRole('professor'), async (req, res) => {
  const t = parse(Target, req.body);
  const ids = await resolveRecipients({ query }, t);
  res.json({ recipients: ids.length, label: await describe({ query }, t) });
});

router.post('/', requireRole('professor'), async (req, res) => {
  const b = parse(Target.extend({
    title: z.string().trim().min(3).max(100),
    body: z.string().trim().min(3).max(2000),
  }), req.body);
  const { title, body, ...target } = b;
  const result = await tx(async (db) => {
    const ids = await resolveRecipients(db, target);
    if (!ids.length) throw badRequest('No students match that target');
    const label = await describe(db, target);
    const { rows: [bc] } = await db.query(
      'INSERT INTO broadcasts (sender_id, title, body, target, recipients) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [req.user.id, title, body, JSON.stringify({ ...target, label }), ids.length]);
    await notifyUsers(db, ids, {
      type: 'broadcast', title, body, data: { broadcast_id: bc.id, from: req.user.name, to: label },
    });
    return bc;
  });
  res.status(201).json({ broadcast: result });
});

router.get('/sent', requireRole('professor'), async (req, res) => {
  const { rows } = await query(
    'SELECT * FROM broadcasts WHERE sender_id = $1 ORDER BY created_at DESC LIMIT 50', [req.user.id]);
  res.json({ broadcasts: rows });
});

/** Students the professor can pick individually. */
router.get('/students', requireRole('professor'), async (req, res) => {
  const sectionId = Number(req.query.section_id) || null;
  const q = String(req.query.q || '').trim();
  const { rows } = await query(
    `SELECT u.id, u.name, st.roll_no, b.code || ' ' || y.code || '-' || sec.name AS section
       FROM students st JOIN users u ON u.id = st.user_id JOIN sections sec ON sec.id = st.section_id
       JOIN branches b ON b.id = sec.branch_id JOIN years y ON y.id = sec.year_id
      WHERE ($1::int IS NULL OR sec.id = $1) AND ($2 = '' OR u.name ILIKE '%' || $2 || '%' OR st.roll_no ILIKE '%' || $2 || '%')
      ORDER BY section, u.name LIMIT 100`, [sectionId, q]);
  res.json({ students: rows });
});
