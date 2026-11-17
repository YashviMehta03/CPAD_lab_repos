// Group project meetings: students request, the guide accepts / rejects / suggests another time.
import { Router } from 'express';
import { z } from 'zod';
import { pool, query, tx } from '../db.js';
import { badRequest, forbidden, notFound, parse } from '../lib/http.js';
import { notifyUsers } from '../lib/notify.js';
import { commonFreeSlots } from '../lib/schedule.js';
import { DAY_NAMES, diffDays, dowOf, getPeriods, isDate, nowIST, toMin } from '../lib/time.js';
import { requireRole } from '../middleware/auth.js';

export const router = Router();

const GROUP_SQL = `
  SELECT g.id, g.name, g.title, g.guide_id, u.name AS guide_name, p.cabin AS guide_cabin,
         (SELECT json_agg(json_build_object('id', su.id, 'name', su.name, 'roll_no', st.roll_no) ORDER BY su.name)
            FROM project_group_members m JOIN users su ON su.id = m.student_id JOIN students st ON st.user_id = su.id
           WHERE m.group_id = g.id) AS members
    FROM project_groups g JOIN users u ON u.id = g.guide_id JOIN professors p ON p.user_id = g.guide_id`;

const MEETING_SQL = `
  SELECT m.*, g.name AS group_name, g.title AS group_title, g.guide_id, gu.name AS guide_name,
         ru.name AS requested_by_name
    FROM meeting_requests m JOIN project_groups g ON g.id = m.group_id
    JOIN users gu ON gu.id = g.guide_id JOIN users ru ON ru.id = m.requested_by`;

async function memberIds(groupId) {
  const { rows } = await query('SELECT student_id FROM project_group_members WHERE group_id = $1', [groupId]);
  return rows.map((r) => r.student_id);
}

/** Loads a group and checks the user is a member (student) or its guide (professor). */
async function myGroup(user, groupId) {
  const { rows: [g] } = await query(`${GROUP_SQL} WHERE g.id = $1`, [groupId]);
  if (!g) throw notFound('Project group not found');
  const isMember = (g.members || []).some((m) => m.id === user.id);
  if (user.role === 'student' && !isMember) throw forbidden('You are not in this project group');
  if (user.role === 'professor' && g.guide_id !== user.id) throw forbidden('You are not the guide of this group');
  return g;
}

const slotText = (periods, date, period) => {
  const p = periods.find((x) => x.period === period);
  return `${DAY_NAMES[dowOf(date)]} ${date} at ${p?.start}`;
};

async function validateSlot(date, period) {
  const periods = await getPeriods();
  const now = nowIST();
  const p = periods.find((x) => x.period === period);
  if (!p) throw badRequest('Unknown period');
  if (dowOf(date) > 5) throw badRequest('Pick a weekday');
  const ahead = diffDays(now.date, date);
  if (ahead < 0 || ahead > 14) throw badRequest('Pick a day in the next two weeks');
  if (ahead === 0 && toMin(p.start) <= now.minutes) throw badRequest('That time has already passed');
  return periods;
}

router.get('/groups', requireRole('student', 'professor'), async (req, res) => {
  const { rows } = req.user.role === 'student'
    ? await query(`${GROUP_SQL} WHERE g.id IN (SELECT group_id FROM project_group_members WHERE student_id = $1) ORDER BY g.name`, [req.user.id])
    : await query(`${GROUP_SQL} WHERE g.guide_id = $1 ORDER BY g.name`, [req.user.id]);
  res.json({ groups: rows });
});

/** Student search for the "new group" member picker (name or roll number). */
router.get('/students', requireRole('student'), async (req, res) => {
  const q = String(req.query.q || '').trim();
  if (q.length < 2) return res.json({ students: [] });
  const { rows } = await query(
    `SELECT u.id, u.name, st.roll_no, b.code || ' ' || y.code || '-' || sec.name AS section
       FROM students st JOIN users u ON u.id = st.user_id JOIN sections sec ON sec.id = st.section_id
       JOIN branches b ON b.id = sec.branch_id JOIN years y ON y.id = sec.year_id
      WHERE u.id <> $1 AND (u.name ILIKE $2 OR st.roll_no ILIKE $2)
      ORDER BY u.name LIMIT 15`, [req.user.id, `%${q.replace(/[%_]/g, '')}%`]);
  res.json({ students: rows });
});

/** Any student can start a project group: pick a guide and add classmates. The creator is a member. */
router.post('/groups', requireRole('student'), async (req, res) => {
  const b = parse(z.object({
    name: z.string().trim().min(2, 'Give the group a name').max(60),
    title: z.string().trim().max(120).optional().nullable(),
    guide_id: z.coerce.number().int(),
    member_ids: z.array(z.coerce.number().int()).max(8, 'A group can have at most 9 students').default([]),
  }), req.body);
  const { rows: [guide] } = await query('SELECT user_id FROM professors WHERE user_id = $1', [b.guide_id]);
  if (!guide) throw badRequest('Pick a professor as the guide');
  const members = [...new Set([req.user.id, ...b.member_ids])];
  const { rows: found } = await query('SELECT user_id FROM students WHERE user_id = ANY($1::int[])', [members]);
  if (found.length !== members.length) throw badRequest('Every member must be a registered student');
  const id = await tx(async (db) => {
    const { rows: [g] } = await db.query(
      'INSERT INTO project_groups (name, title, guide_id) VALUES ($1, $2, $3) RETURNING id', [b.name, b.title || null, b.guide_id]);
    for (const m of members) await db.query('INSERT INTO project_group_members (group_id, student_id) VALUES ($1, $2)', [g.id, m]);
    await notifyUsers(db, members.filter((m) => m !== req.user.id), {
      type: 'meeting', title: `${req.user.name} added you to project group "${b.name}"`,
      body: 'Open Project meetings to request a meeting with your guide.', data: { group_id: g.id },
    });
    await notifyUsers(db, [b.guide_id], {
      type: 'meeting', title: `New project group "${b.name}" chose you as guide`,
      body: `${req.user.name} and ${members.length - 1} other student(s).`, data: { group_id: g.id },
    });
    return g.id;
  });
  const { rows: [group] } = await query(`${GROUP_SQL} WHERE g.id = $1`, [id]);
  res.status(201).json({ group });
});

/** Leave a group; the group is removed when the last student leaves. */
router.delete('/groups/:id/members/me', requireRole('student'), async (req, res) => {
  const gid = Number(req.params.id) || 0;
  const { rowCount } = await query('DELETE FROM project_group_members WHERE group_id = $1 AND student_id = $2', [gid, req.user.id]);
  if (!rowCount) throw notFound('You are not in this group');
  await query('DELETE FROM project_groups g WHERE g.id = $1 AND NOT EXISTS (SELECT 1 FROM project_group_members m WHERE m.group_id = g.id)', [gid]);
  res.json({ ok: true });
});

/** Times when every member's section and the guide are free (from the shared timetable). */
router.get('/groups/:id/slots', requireRole('student', 'professor'), async (req, res) => {
  const g = await myGroup(req.user, Number(req.params.id) || 0);
  const { rows } = await query(
    `SELECT DISTINCT st.section_id FROM project_group_members m JOIN students st ON st.user_id = m.student_id
      WHERE m.group_id = $1`, [g.id]);
  const slots = await commonFreeSlots(pool, {
    sectionIds: rows.map((r) => r.section_id), professorId: g.guide_id, days: 7, limit: 12,
  });
  res.json({ slots });
});

router.get('/', requireRole('student', 'professor'), async (req, res) => {
  const { rows } = req.user.role === 'student'
    ? await query(`${MEETING_SQL} WHERE g.id IN (SELECT group_id FROM project_group_members WHERE student_id = $1)
                   ORDER BY m.created_at DESC`, [req.user.id])
    : await query(`${MEETING_SQL} WHERE g.guide_id = $1
                   ORDER BY (m.status = 'pending') DESC, m.date, m.period`, [req.user.id]);
  res.json({ meetings: rows, periods: await getPeriods() });
});

router.post('/', requireRole('student'), async (req, res) => {
  const b = parse(z.object({
    group_id: z.coerce.number().int(),
    date: z.string().refine(isDate, 'Use YYYY-MM-DD'),
    period: z.coerce.number().int(),
    agenda: z.string().trim().min(3, 'Add a short agenda').max(500),
  }), req.body);
  const g = await myGroup(req.user, b.group_id);
  const periods = await validateSlot(b.date, b.period);
  const { rows: [open] } = await query(
    `SELECT 1 FROM meeting_requests WHERE group_id = $1 AND status IN ('pending','suggested')`, [g.id]);
  if (open) throw badRequest('Your group already has a request waiting for a reply');
  const { rows: [m] } = await query(
    `INSERT INTO meeting_requests (group_id, requested_by, date, period, agenda) VALUES ($1, $2, $3, $4, $5) RETURNING *`,
    [g.id, req.user.id, b.date, b.period, b.agenda]);
  await notifyUsers(null, [g.guide_id], {
    type: 'meeting', title: `Meeting request from ${g.name}`,
    body: `${req.user.name} asked for ${slotText(periods, b.date, b.period)}: ${b.agenda.slice(0, 100)}`,
    data: { meeting_id: m.id },
  });
  res.status(201).json({ meeting: m });
});

router.post('/:id/respond', requireRole('professor'), async (req, res) => {
  const b = parse(z.object({
    action: z.enum(['accept', 'reject', 'suggest']),
    note: z.string().trim().max(300).optional().nullable(),
    date: z.string().optional().nullable(),
    period: z.coerce.number().int().optional().nullable(),
  }), req.body);
  const { rows: [m] } = await query(`${MEETING_SQL} WHERE m.id = $1`, [Number(req.params.id) || 0]);
  if (!m) throw notFound('Meeting request not found');
  if (m.guide_id !== req.user.id) throw forbidden('This request is not for you');
  if (m.status !== 'pending') throw badRequest('You already replied to this request');
  const periods = await getPeriods();
  let status;
  let body;
  if (b.action === 'suggest') {
    if (!isDate(b.date) || !b.period) throw badRequest('Pick the date and time you suggest');
    await validateSlot(b.date, b.period);
    status = 'suggested';
    body = `${req.user.name} suggested ${slotText(periods, b.date, b.period)} instead.`;
  } else {
    status = b.action === 'accept' ? 'accepted' : 'rejected';
    body = `${req.user.name} ${status} the meeting on ${slotText(periods, m.date, m.period)}.`;
  }
  const { rows: [u] } = await query(
    `UPDATE meeting_requests SET status = $1, professor_note = $2, suggested_date = $3, suggested_period = $4,
            responded_at = now() WHERE id = $5 RETURNING *`,
    [status, b.note || null, status === 'suggested' ? b.date : null, status === 'suggested' ? b.period : null, m.id]);
  await notifyUsers(null, await memberIds(m.group_id), {
    type: 'meeting', title: `Meeting ${status}: ${m.group_name}`,
    body: b.note ? `${body} Note: ${b.note}` : body, data: { meeting_id: m.id },
  });
  res.json({ meeting: u });
});

/** Students answer a suggested time: accept it, or decline and send a fresh request later. */
router.post('/:id/suggestion', requireRole('student'), async (req, res) => {
  const { accept } = parse(z.object({ accept: z.boolean() }), req.body);
  const { rows: [m] } = await query(`${MEETING_SQL} WHERE m.id = $1`, [Number(req.params.id) || 0]);
  if (!m) throw notFound('Meeting request not found');
  await myGroup(req.user, m.group_id);
  if (m.status !== 'suggested') throw badRequest('There is no suggested time to answer');
  const periods = await getPeriods();
  const { rows: [u] } = accept
    ? await query(`UPDATE meeting_requests SET status = 'accepted', date = suggested_date, period = suggested_period
                    WHERE id = $1 RETURNING *`, [m.id])
    : await query(`UPDATE meeting_requests SET status = 'cancelled' WHERE id = $1 RETURNING *`, [m.id]);
  await notifyUsers(null, [m.guide_id, ...(await memberIds(m.group_id))].filter((id) => id !== req.user.id), {
    type: 'meeting',
    title: accept ? `${m.group_name} confirmed the meeting` : `${m.group_name} declined the suggested time`,
    body: accept ? `Meeting on ${slotText(periods, m.suggested_date, m.suggested_period)} is confirmed.`
      : `${req.user.name} declined. They will send a new request.`,
    data: { meeting_id: m.id },
  });
  res.json({ meeting: u });
});
