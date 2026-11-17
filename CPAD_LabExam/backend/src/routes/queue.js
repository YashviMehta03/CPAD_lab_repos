import { Router } from 'express';
import { z } from 'zod';
import { query, tx } from '../db.js';
import { badRequest, conflict, forbidden, notFound, parse } from '../lib/http.js';
import { notifyUsers } from '../lib/notify.js';
import { nowIST } from '../lib/time.js';
import { requireRole } from '../middleware/auth.js';

export const router = Router();

const POSITION_SQL = `
  (SELECT COUNT(*) FROM queue_tokens q2
    WHERE q2.professor_id = q.professor_id AND q2.queue_date = q.queue_date
      AND q2.status = 'waiting' AND q2.token_no < q.token_no)`;

// ------------------------------------------------------------------ student side

router.get('/mine', requireRole('student'), async (req, res) => {
  const { rows } = await query(
    `SELECT q.id, q.professor_id, q.token_no, q.status, q.purpose, q.created_at, q.called_at,
            u.name AS professor_name, p.cabin, ${POSITION_SQL} AS ahead
       FROM queue_tokens q JOIN professors p ON p.user_id = q.professor_id JOIN users u ON u.id = q.professor_id
      WHERE q.student_id = $1 AND q.queue_date = $2 AND q.status IN ('waiting', 'serving')
      ORDER BY q.created_at`,
    [req.user.id, nowIST().date],
  );
  res.json({ tokens: rows.map((t) => ({ ...t, position: t.status === 'serving' ? 0 : t.ahead + 1 })) });
});

router.post('/:professorId/join', requireRole('student'), async (req, res) => {
  const professorId = Number(req.params.professorId);
  const { purpose } = parse(z.object({ purpose: z.string().trim().max(140).optional().nullable() }), req.body);
  const today = nowIST().date;
  const token = await tx(async (db) => {
    const { rows: [p] } = await db.query('SELECT manual_status FROM professors WHERE user_id = $1', [professorId]);
    if (!p) throw notFound('Professor not found');
    if (p.manual_status === 'on_leave') throw badRequest('This professor is on leave today');
    // Serialise token numbering per professor.
    await db.query('SELECT pg_advisory_xact_lock(1001, $1)', [professorId]);
    const { rows: [existing] } = await db.query(
      `SELECT id FROM queue_tokens WHERE professor_id = $1 AND student_id = $2 AND queue_date = $3
          AND status IN ('waiting','serving')`, [professorId, req.user.id, today]);
    if (existing) throw conflict('You are already in this queue');
    const { rows: [n] } = await db.query(
      'SELECT COALESCE(MAX(token_no), 0) + 1 AS next FROM queue_tokens WHERE professor_id = $1 AND queue_date = $2',
      [professorId, today]);
    const { rows: [t] } = await db.query(
      `INSERT INTO queue_tokens (professor_id, student_id, queue_date, token_no, purpose)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`, [professorId, req.user.id, today, n.next, purpose || null]);
    await notifyUsers(db, [professorId], {
      type: 'queue', title: `${req.user.name} joined your queue: token #${t.token_no}`,
      body: purpose ? `Wants to meet about: ${purpose}` : 'Waiting to meet you.', data: { token_id: t.id },
    });
    return t;
  });
  const { rows: [pos] } = await query(`SELECT ${POSITION_SQL} AS ahead FROM queue_tokens q WHERE q.id = $1`, [token.id]);
  res.status(201).json({ token: { ...token, ahead: pos.ahead, position: pos.ahead + 1 } });
});

router.delete('/tokens/:id', requireRole('student'), async (req, res) => {
  const { rowCount } = await query(
    `UPDATE queue_tokens SET status = 'left', finished_at = now()
      WHERE id = $1 AND student_id = $2 AND status IN ('waiting','serving')`,
    [Number(req.params.id) || 0, req.user.id]);
  if (!rowCount) throw notFound('No active token to leave');
  res.json({ ok: true });
});

// ------------------------------------------------------------------ professor side

async function professorQueue(professorId) {
  const { rows } = await query(
    `SELECT q.id, q.token_no, q.status, q.purpose, q.created_at, q.called_at, q.finished_at,
            u.name AS student_name, st.roll_no, sec.name AS section_name, b.code AS branch_code, y.code AS year_code
       FROM queue_tokens q JOIN users u ON u.id = q.student_id
       JOIN students st ON st.user_id = q.student_id JOIN sections sec ON sec.id = st.section_id
       JOIN branches b ON b.id = sec.branch_id JOIN years y ON y.id = sec.year_id
      WHERE q.professor_id = $1 AND q.queue_date = $2
      ORDER BY q.token_no`,
    [professorId, nowIST().date]);
  return {
    serving: rows.find((r) => r.status === 'serving') ?? null,
    waiting: rows.filter((r) => r.status === 'waiting'),
    finished: rows.filter((r) => ['done', 'skipped', 'left'].includes(r.status)).reverse(),
  };
}

router.get('/manage', requireRole('professor'), async (req, res) => {
  res.json(await professorQueue(req.user.id));
});

/** Completes whoever is being served (if anyone) and calls the next waiting token. */
router.post('/manage/next', requireRole('professor'), async (req, res) => {
  const today = nowIST().date;
  const called = await tx(async (db) => {
    await db.query('SELECT pg_advisory_xact_lock(1001, $1)', [req.user.id]);
    await db.query(
      `UPDATE queue_tokens SET status = 'done', finished_at = now()
        WHERE professor_id = $1 AND queue_date = $2 AND status = 'serving'`, [req.user.id, today]);
    const { rows: [next] } = await db.query(
      `UPDATE queue_tokens SET status = 'serving', called_at = now()
        WHERE id = (SELECT id FROM queue_tokens WHERE professor_id = $1 AND queue_date = $2 AND status = 'waiting'
                     ORDER BY token_no LIMIT 1)
        RETURNING *`, [req.user.id, today]);
    if (next) {
      await notifyUsers(db, [next.student_id], {
        type: 'queue', title: `It's your turn: token #${next.token_no}`,
        body: `${req.user.name} is ready to see you now.`, data: { token_id: next.id },
      });
    }
    return next ?? null;
  });
  res.json({ called, ...(await professorQueue(req.user.id)) });
});

router.post('/manage/tokens/:id/:action', requireRole('professor'), async (req, res) => {
  const action = req.params.action;
  if (!['complete', 'skip'].includes(action)) throw badRequest('Action must be complete or skip');
  const { rows: [t] } = await query('SELECT * FROM queue_tokens WHERE id = $1', [Number(req.params.id) || 0]);
  if (!t) throw notFound('Token not found');
  if (t.professor_id !== req.user.id) throw forbidden('This token is not in your queue');
  if (!['waiting', 'serving'].includes(t.status)) throw badRequest('This token is already finished');
  if (action === 'complete' && t.status !== 'serving') throw badRequest('Call this token before completing it');
  await query('UPDATE queue_tokens SET status = $1, finished_at = now() WHERE id = $2',
    [action === 'complete' ? 'done' : 'skipped', t.id]);
  if (action === 'skip') {
    await notifyUsers(null, [t.student_id], {
      type: 'queue', title: `Token #${t.token_no} was skipped`,
      body: `${req.user.name} skipped your token. You can join the queue again.`,
    });
  }
  res.json(await professorQueue(req.user.id));
});
