import { Router } from 'express';
import { query } from '../db.js';

export const router = Router();

router.get('/', async (req, res) => {
  const type = typeof req.query.type === 'string' ? req.query.type.split(',') : null;
  const { rows } = await query(
    `SELECT id, type, title, body, data, read_at, created_at FROM notifications
      WHERE user_id = $1 AND ($2::text[] IS NULL OR type = ANY($2))
      ORDER BY created_at DESC LIMIT 100`,
    [req.user.id, type],
  );
  const { rows: [c] } = await query(
    'SELECT COUNT(*) AS unread FROM notifications WHERE user_id = $1 AND read_at IS NULL', [req.user.id]);
  res.json({ notifications: rows, unread: c.unread });
});

router.get('/unread-count', async (req, res) => {
  const { rows: [c] } = await query(
    'SELECT COUNT(*) AS unread FROM notifications WHERE user_id = $1 AND read_at IS NULL', [req.user.id]);
  res.json(c);
});

router.post('/read-all', async (req, res) => {
  await query('UPDATE notifications SET read_at = now() WHERE user_id = $1 AND read_at IS NULL', [req.user.id]);
  res.json({ ok: true });
});

router.post('/:id/read', async (req, res) => {
  // user_id in the WHERE clause is the ownership check.
  await query('UPDATE notifications SET read_at = now() WHERE id = $1 AND user_id = $2 AND read_at IS NULL',
    [Number(req.params.id) || 0, req.user.id]);
  res.json({ ok: true });
});
