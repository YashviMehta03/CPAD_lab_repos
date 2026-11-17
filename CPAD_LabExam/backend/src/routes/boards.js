// Paperwork help boards (one per form type) and 1:1 student chat.
import { Router } from 'express';
import { z } from 'zod';
import { query, tx } from '../db.js';
import { badRequest, forbidden, HttpError, notFound, parse } from '../lib/http.js';
import { notifyUsers } from '../lib/notify.js';

export const router = Router();
export const chatRouter = Router();

const formId = (req) => Number(req.params.id) || 0;

async function mustExist(id) {
  const { rows: [f] } = await query('SELECT * FROM form_types WHERE id = $1', [id]);
  if (!f) throw notFound('Board not found');
  return f;
}

router.get('/', async (req, res) => {
  const { rows } = await query(
    `SELECT f.*,
            (SELECT COUNT(*) FROM board_helpers h WHERE h.form_type_id = f.id) AS helpers,
            (SELECT COUNT(*) FROM board_posts p WHERE p.form_type_id = f.id AND p.parent_id IS NULL) AS questions,
            EXISTS (SELECT 1 FROM board_helpers h WHERE h.form_type_id = f.id AND h.student_id = $1) AS am_helper
       FROM form_types f ORDER BY f.name`, [req.user.id]);
  res.json({ boards: rows });
});

router.get('/:id', async (req, res) => {
  const f = await mustExist(formId(req));
  const { rows: posts } = await query(
    `SELECT p.id, p.parent_id, p.body, p.created_at, p.author_id, u.name AS author_name,
            EXISTS (SELECT 1 FROM board_helpers h WHERE h.form_type_id = p.form_type_id AND h.student_id = p.author_id) AS author_is_helper
       FROM board_posts p JOIN users u ON u.id = p.author_id
      WHERE p.form_type_id = $1 ORDER BY p.created_at`, [f.id]);
  const { rows: helpers } = await query(
    `SELECT u.id, u.name, b.code AS branch_code, y.code AS year_code, h.created_at
       FROM board_helpers h JOIN users u ON u.id = h.student_id
       LEFT JOIN students st ON st.user_id = u.id LEFT JOIN sections sec ON sec.id = st.section_id
       LEFT JOIN branches b ON b.id = sec.branch_id LEFT JOIN years y ON y.id = sec.year_id
      WHERE h.form_type_id = $1 ORDER BY h.created_at`, [f.id]);
  const threads = posts.filter((p) => !p.parent_id).reverse()
    .map((p) => ({ ...p, replies: posts.filter((r) => r.parent_id === p.id) }));
  res.json({ board: f, threads, helpers, am_helper: helpers.some((h) => h.id === req.user.id) });
});

router.post('/:id/posts', async (req, res) => {
  if (req.user.role !== 'student') throw forbidden('Only students post on paperwork boards');
  const f = await mustExist(formId(req));
  const { body, parent_id } = parse(z.object({
    body: z.string().trim().min(2).max(1000),
    parent_id: z.coerce.number().int().optional().nullable(),
  }), req.body);
  let parent = null;
  if (parent_id) {
    ({ rows: [parent] } = await query('SELECT * FROM board_posts WHERE id = $1 AND form_type_id = $2', [parent_id, f.id]));
    if (!parent) throw badRequest('That question is not on this board');
    if (parent.parent_id) throw badRequest('Reply to the question, not to a reply');
  }
  const { rows: [p] } = await query(
    'INSERT INTO board_posts (form_type_id, author_id, parent_id, body) VALUES ($1, $2, $3, $4) RETURNING *',
    [f.id, req.user.id, parent?.id ?? null, body]);
  if (parent && parent.author_id !== req.user.id) {
    await notifyUsers(null, [parent.author_id], {
      type: 'board', title: `New reply on ${f.name}`, body: `${req.user.name}: ${body.slice(0, 120)}`,
      data: { form_type_id: f.id },
    });
  }
  res.status(201).json({ post: p });
});

router.post('/:id/helper', async (req, res) => {
  if (req.user.role !== 'student') throw forbidden('Only students can be helpers');
  const f = await mustExist(formId(req));
  await query('INSERT INTO board_helpers (form_type_id, student_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
    [f.id, req.user.id]);
  res.json({ am_helper: true });
});

router.delete('/:id/helper', async (req, res) => {
  await query('DELETE FROM board_helpers WHERE form_type_id = $1 AND student_id = $2', [formId(req), req.user.id]);
  res.json({ am_helper: false });
});

/** "Need help": pings every helper on the board. Limited to once per 30 minutes per board. */
router.post('/:id/need-help', async (req, res) => {
  if (req.user.role !== 'student') throw forbidden('Only students can ask for help');
  const f = await mustExist(formId(req));
  const { message } = parse(z.object({ message: z.string().trim().max(200).optional().nullable() }), req.body);
  const { rows: [recent] } = await query(
    `SELECT 1 FROM notifications WHERE type = 'help_ping' AND created_at > now() - interval '30 minutes'
        AND (data->>'form_type_id')::int = $1 AND (data->>'user_id')::int = $2 LIMIT 1`,
    [f.id, req.user.id]);
  if (recent) throw new HttpError(429, 'You already pinged the helpers in the last 30 minutes');
  const { rows: helpers } = await query(
    'SELECT student_id FROM board_helpers WHERE form_type_id = $1 AND student_id <> $2', [f.id, req.user.id]);
  if (!helpers.length) throw badRequest('Nobody has marked this form as done yet. Post a question instead.');
  await tx(async (db) => {
    await notifyUsers(db, helpers.map((h) => h.student_id), {
      type: 'help_ping', title: `${req.user.name} needs help with ${f.name}`,
      body: message || 'Open the board to chat with them.', data: { form_type_id: f.id, user_id: req.user.id },
    });
  });
  res.json({ pinged: helpers.length });
});

// ------------------------------------------------------------------ 1:1 chat (students)

async function myConversation(convId, userId) {
  const { rows: [c] } = await query('SELECT * FROM conversations WHERE id = $1', [convId]);
  if (!c) throw notFound('Chat not found');
  if (c.user_a !== userId && c.user_b !== userId) throw forbidden('This is not your chat');
  return c;
}

chatRouter.get('/', async (req, res) => {
  const { rows } = await query(
    `SELECT c.id, c.form_type_id, f.name AS form_name,
            other.id AS other_id, other.name AS other_name,
            m.body AS last_body, m.created_at AS last_at, m.sender_id AS last_sender
       FROM conversations c
       JOIN users other ON other.id = CASE WHEN c.user_a = $1 THEN c.user_b ELSE c.user_a END
       LEFT JOIN form_types f ON f.id = c.form_type_id
       LEFT JOIN LATERAL (SELECT body, created_at, sender_id FROM messages WHERE conversation_id = c.id
                           ORDER BY id DESC LIMIT 1) m ON true
      WHERE c.user_a = $1 OR c.user_b = $1
      ORDER BY COALESCE(m.created_at, c.created_at) DESC`, [req.user.id]);
  res.json({ conversations: rows });
});

chatRouter.post('/', async (req, res) => {
  const { user_id, form_type_id } = parse(z.object({
    user_id: z.coerce.number().int(), form_type_id: z.coerce.number().int().optional().nullable(),
  }), req.body);
  if (user_id === req.user.id) throw badRequest('You cannot chat with yourself');
  const { rows: [other] } = await query('SELECT id, role FROM users WHERE id = $1', [user_id]);
  if (!other || other.role !== 'student') throw badRequest('You can only chat with other students');
  const [a, b] = user_id < req.user.id ? [user_id, req.user.id] : [req.user.id, user_id];
  const { rows: [c] } = await query(
    `INSERT INTO conversations (user_a, user_b, form_type_id) VALUES ($1, $2, $3)
     ON CONFLICT (user_a, user_b) DO UPDATE SET form_type_id = COALESCE(EXCLUDED.form_type_id, conversations.form_type_id)
     RETURNING *`, [a, b, form_type_id || null]);
  res.json({ conversation: c });
});

chatRouter.get('/:id/messages', async (req, res) => {
  const c = await myConversation(Number(req.params.id) || 0, req.user.id);
  const after = Number(req.query.after) || 0;
  const { rows } = await query(
    `SELECT id, sender_id, body, created_at FROM messages WHERE conversation_id = $1 AND id > $2 ORDER BY id LIMIT 200`,
    [c.id, after]);
  const otherId = c.user_a === req.user.id ? c.user_b : c.user_a;
  const { rows: [other] } = await query('SELECT id, name FROM users WHERE id = $1', [otherId]);
  res.json({ conversation: { ...c, other }, messages: rows });
});

chatRouter.post('/:id/messages', async (req, res) => {
  const c = await myConversation(Number(req.params.id) || 0, req.user.id);
  const { body } = parse(z.object({ body: z.string().trim().min(1).max(1000) }), req.body);
  const { rows: [m] } = await query(
    'INSERT INTO messages (conversation_id, sender_id, body) VALUES ($1, $2, $3) RETURNING id, sender_id, body, created_at',
    [c.id, req.user.id, body]);
  const otherId = c.user_a === req.user.id ? c.user_b : c.user_a;
  // One unread chat notification per conversation is enough.
  const { rows: [pending] } = await query(
    `SELECT 1 FROM notifications WHERE user_id = $1 AND type = 'chat' AND read_at IS NULL AND (data->>'conversation_id')::int = $2`,
    [otherId, c.id]);
  if (!pending) {
    await notifyUsers(null, [otherId], {
      type: 'chat', title: `Message from ${req.user.name}`, body: body.slice(0, 120), data: { conversation_id: c.id },
    });
  }
  res.status(201).json({ message: m });
});
