import { Router } from 'express';
import { z } from 'zod';
import { pool, query } from '../db.js';
import { notFound, parse } from '../lib/http.js';
import { getOccurrences, professorStatuses } from '../lib/schedule.js';
import { nowIST } from '../lib/time.js';
import { requireRole } from '../middleware/auth.js';

export const router = Router();

// Note: phone numbers are never part of these responses. Only the exam helpline (professors only) has them.

router.get('/', async (req, res) => {
  const q = String(req.query.q || '').trim().toLowerCase();
  let list = await professorStatuses();
  if (q) list = list.filter((p) => p.name.toLowerCase().includes(q) || p.code.toLowerCase().includes(q));
  res.json({ professors: list });
});

router.put('/me/status', requireRole('professor'), async (req, res) => {
  const { status, note } = parse(z.object({
    status: z.enum(['in_cabin', 'busy', 'away', 'on_leave']),
    note: z.string().trim().max(120).optional().nullable(),
  }), req.body);
  await query(
    'UPDATE professors SET manual_status = $1, status_note = $2, status_updated_at = now() WHERE user_id = $3',
    [status, note || null, req.user.id],
  );
  const me = (await professorStatuses()).find((p) => p.id === req.user.id);
  res.json({ professor: me });
});

router.get('/:id', async (req, res) => {
  const id = Number(req.params.id);
  const me = (await professorStatuses()).find((p) => p.id === id);
  if (!me) throw notFound('Professor not found');
  const today = nowIST().date;
  const todays = (await getOccurrences(pool, today, today, { includeInactive: true }))
    .filter((o) => o.professor_id === id);
  const { rows: subjects } = await query(
    `SELECT s.code, s.name, ps.is_backup FROM professor_subjects ps JOIN subjects s ON s.id = ps.subject_id
      WHERE ps.professor_id = $1 ORDER BY ps.is_backup, s.name`, [id]);
  res.json({ professor: me, today: todays, subjects });
});
