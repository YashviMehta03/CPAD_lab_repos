import { Router } from 'express';
import multer from 'multer';
import { z } from 'zod';
import { query, tx } from '../db.js';
import { adminsAtLevel, LEVEL_NAMES, runEscalation } from '../lib/escalation.js';
import { badRequest, forbidden, notFound, parse } from '../lib/http.js';
import { notifyUsers } from '../lib/notify.js';
import { photoUrl, savePhoto } from '../lib/storage.js';
import { requireRole } from '../middleware/auth.js';

export const router = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => cb(null, file.mimetype.startsWith('image/')),
});

const TICKET_SQL = `
  SELECT t.*, c.code AS category_code, c.name AS category_name, c.sla_hours,
         u.name AS student_name, st.roll_no
    FROM tickets t JOIN ticket_categories c ON c.id = t.category_id
    JOIN users u ON u.id = t.student_id LEFT JOIN students st ON st.user_id = t.student_id`;

/** Admin visibility: own categories, or anything escalated to (or above) this admin's level. */
const ADMIN_VISIBLE = `
  (t.category_id IN (SELECT category_id FROM admin_categories WHERE admin_id = $1)
   OR ($2::int >= 2 AND t.escalation_level >= $2::int))`;

async function adminLevel(userId) {
  const { rows: [a] } = await query('SELECT level FROM admins WHERE user_id = $1', [userId]);
  return a?.level ?? 0;
}

async function canAdminSee(userId, ticketId) {
  const level = await adminLevel(userId);
  const { rows } = await query(`SELECT 1 FROM tickets t WHERE t.id = $3 AND ${ADMIN_VISIBLE}`, [userId, level, ticketId]);
  return rows.length > 0;
}

const withUrl = async (t) => ({ ...t, photo_url: await photoUrl(t.photo_path), level_name: LEVEL_NAMES[t.escalation_level] });

router.get('/categories', async (_req, res) => {
  const { rows } = await query('SELECT id, code, name, sla_hours FROM ticket_categories ORDER BY name');
  res.json({ categories: rows });
});

// ------------------------------------------------------------------ student

router.post('/', requireRole('student'), upload.single('photo'), async (req, res) => {
  const b = parse(z.object({
    category_id: z.coerce.number().int(),
    title: z.string().trim().min(3, 'Give the issue a short title').max(100),
    description: z.string().trim().max(1000).optional().nullable(),
    location: z.string().trim().min(2, 'Say where the issue is').max(120),
  }), req.body);
  const { rows: [cat] } = await query('SELECT * FROM ticket_categories WHERE id = $1', [b.category_id]);
  if (!cat) throw badRequest('Unknown category');
  const photo = req.file ? await savePhoto(req.file) : null;
  const ticket = await tx(async (db) => {
    const { rows: [t] } = await db.query(
      `INSERT INTO tickets (student_id, category_id, title, description, location, photo_path, due_at)
       VALUES ($1, $2, $3, $4, $5, $6, now() + make_interval(hours => $7)) RETURNING *`,
      [req.user.id, cat.id, b.title, b.description || null, b.location, photo, cat.sla_hours]);
    await db.query(`INSERT INTO ticket_events (ticket_id, actor_id, type, note) VALUES ($1, $2, 'created', $3)`,
      [t.id, req.user.id, `Reported at ${b.location}`]);
    const { rows: handlers } = await db.query('SELECT admin_id FROM admin_categories WHERE category_id = $1', [cat.id]);
    await notifyUsers(db, handlers.map((h) => h.admin_id), {
      type: 'ticket', title: `New ${cat.name} ticket #${t.id}`, body: `${b.title} at ${b.location}`, data: { ticket_id: t.id },
    });
    return t;
  });
  res.status(201).json({ ticket: await withUrl(ticket) });
});

router.get('/mine', requireRole('student'), async (req, res) => {
  const { rows } = await query(`${TICKET_SQL} WHERE t.student_id = $1 ORDER BY t.created_at DESC`, [req.user.id]);
  res.json({ tickets: await Promise.all(rows.map(withUrl)) });
});

// ------------------------------------------------------------------ admin

router.get('/inbox', requireRole('admin'), async (req, res) => {
  await runEscalation();  // never show a stale level
  const level = await adminLevel(req.user.id);
  const status = typeof req.query.status === 'string' && req.query.status ? req.query.status.split(',') : null;
  const { rows } = await query(
    `${TICKET_SQL} WHERE ${ADMIN_VISIBLE} AND ($3::text[] IS NULL OR t.status = ANY($3))
      ORDER BY (t.status IN ('open','in_progress')) DESC, t.escalation_level DESC, t.due_at`,
    [req.user.id, level, status]);
  res.json({ level, tickets: await Promise.all(rows.map(withUrl)) });
});

router.post('/:id/status', requireRole('admin'), async (req, res) => {
  const id = Number(req.params.id) || 0;
  const { status, note } = parse(z.object({
    status: z.enum(['open', 'in_progress', 'resolved', 'rejected']),
    note: z.string().trim().max(300).optional().nullable(),
  }), req.body);
  if (!(await canAdminSee(req.user.id, id))) throw forbidden('This ticket is not in your categories');
  const ticket = await tx(async (db) => {
    const { rows: [t] } = await db.query(
      'UPDATE tickets SET status = $1, updated_at = now() WHERE id = $2 RETURNING *', [status, id]);
    await db.query(`INSERT INTO ticket_events (ticket_id, actor_id, type, note) VALUES ($1, $2, 'status', $3)`,
      [id, req.user.id, `Status set to ${status.replace('_', ' ')}${note ? `: ${note}` : ''}`]);
    await notifyUsers(db, [t.student_id], {
      type: 'ticket', title: `Ticket #${id} is ${status.replace('_', ' ')}`,
      body: note ? `${t.title}: ${note}` : t.title, data: { ticket_id: id },
    });
    return t;
  });
  res.json({ ticket: await withUrl(ticket) });
});

router.post('/:id/escalate', requireRole('admin'), async (req, res) => {
  const id = Number(req.params.id) || 0;
  const { note } = parse(z.object({ note: z.string().trim().max(300).optional().nullable() }), req.body);
  if (!(await canAdminSee(req.user.id, id))) throw forbidden('This ticket is not in your categories');
  const ticket = await tx(async (db) => {
    const { rows: [t] } = await db.query(
      `UPDATE tickets t SET escalation_level = t.escalation_level + 1, updated_at = now(),
              due_at = now() + make_interval(hours => c.sla_hours)
         FROM ticket_categories c
        WHERE c.id = t.category_id AND t.id = $1 AND t.escalation_level < 3 AND t.status IN ('open','in_progress')
        RETURNING t.*`, [id]);
    if (!t) throw badRequest('Only open tickets below the dean can be escalated');
    const to = LEVEL_NAMES[t.escalation_level];
    await db.query(`INSERT INTO ticket_events (ticket_id, actor_id, type, note) VALUES ($1, $2, 'escalated', $3)`,
      [id, req.user.id, `Escalated to ${to}${note ? `: ${note}` : ''}`]);
    await notifyUsers(db, [t.student_id], {
      type: 'ticket', title: `Ticket #${id} escalated to ${to}`, body: t.title, data: { ticket_id: id },
    });
    await notifyUsers(db, await adminsAtLevel(db, t.escalation_level), {
      type: 'ticket', title: `Ticket #${id} escalated to you`, body: note || t.title, data: { ticket_id: id },
    });
    return t;
  });
  res.json({ ticket: await withUrl(ticket) });
});

// ------------------------------------------------------------------ either side

router.get('/:id', requireRole('student', 'admin'), async (req, res) => {
  const id = Number(req.params.id) || 0;
  const { rows: [t] } = await query(`${TICKET_SQL} WHERE t.id = $1`, [id]);
  if (!t) throw notFound('Ticket not found');
  if (req.user.role === 'student' && t.student_id !== req.user.id) throw forbidden('This is not your ticket');
  if (req.user.role === 'admin' && !(await canAdminSee(req.user.id, id))) throw forbidden('This ticket is not in your categories');
  const { rows: events } = await query(
    `SELECT ev.id, ev.type, ev.note, ev.created_at, u.name AS actor_name, a.title AS actor_title
       FROM ticket_events ev LEFT JOIN users u ON u.id = ev.actor_id LEFT JOIN admins a ON a.user_id = ev.actor_id
      WHERE ev.ticket_id = $1 ORDER BY ev.created_at, ev.id`, [id]);
  res.json({ ticket: await withUrl(t), events });
});
