// Smart rescheduler: professors cancel or move their own classes; the section is notified.
import { Router } from 'express';
import { z } from 'zod';
import { pool, query, tx } from '../db.js';
import { badRequest, conflict, forbidden, notFound, parse } from '../lib/http.js';
import { notifyUsers, studentIdsOfSection } from '../lib/notify.js';
import { checkSlot, getOccurrences, loadEntries, suggestSlots } from '../lib/schedule.js';
import { addDays, DAY_NAMES, dowOf, getPeriods, isDate, nowIST, toMin } from '../lib/time.js';

export const router = Router();

const fmtSlot = (periods, date, s, e) => {
  const st = periods.find((p) => p.period === s)?.start;
  const en = periods.find((p) => p.period === e)?.end;
  return `${DAY_NAMES[dowOf(date)]} ${date}, ${st}-${en}`;
};

/** Loads an entry and checks it belongs to the professor and actually runs on originalDate. */
async function ownedOccurrence(userId, entryId, originalDate) {
  if (!isDate(originalDate)) throw badRequest('original_date must be YYYY-MM-DD');
  const [entry] = await loadEntries(pool, 'WHERE e.id = $1', [entryId]);
  if (!entry) throw notFound('Class not found');
  if (entry.professor_id !== userId) throw forbidden('You can only reschedule your own classes');
  if (dowOf(originalDate) !== entry.day) throw badRequest(`This class runs on ${DAY_NAMES[entry.day]}s`);
  const now = nowIST();
  if (originalDate < now.date || originalDate > addDays(now.date, 14)) {
    throw badRequest('You can change classes from today up to two weeks ahead');
  }
  const { rows: [existing] } = await query(
    'SELECT id FROM class_changes WHERE entry_id = $1 AND original_date = $2', [entryId, originalDate]);
  if (existing) throw conflict('This class is already cancelled or moved. Undo that first.');
  return entry;
}

/** Upcoming occurrences of my classes (next 7 days), including already-changed ones. */
router.get('/my-classes', async (req, res) => {
  const now = nowIST();
  const periods = await getPeriods();
  const occ = (await getOccurrences(pool, now.date, addDays(now.date, 7), { includeInactive: true }))
    .filter((o) => o.professor_id === req.user.id)
    .filter((o) => o.date > now.date || toMin(periods.find((p) => p.period === o.period_end).end) > now.minutes);
  res.json({ periods, occurrences: occ });
});

router.post('/suggest', async (req, res) => {
  const { entry_id, original_date } = parse(z.object({
    entry_id: z.coerce.number().int(), original_date: z.string(),
  }), req.body);
  const entry = await ownedOccurrence(req.user.id, entry_id, original_date);
  const options = await suggestSlots(pool, entry, original_date, { days: 7, limit: 3 });
  res.json({ entry, original_date, options });
});

router.post('/apply', async (req, res) => {
  const b = parse(z.object({
    entry_id: z.coerce.number().int(),
    original_date: z.string(),
    new_date: z.string().refine(isDate, 'Use YYYY-MM-DD'),
    period_start: z.coerce.number().int(),
    room_id: z.coerce.number().int(),
    reason: z.string().trim().max(200).optional().nullable(),
  }), req.body);
  const entry = await ownedOccurrence(req.user.id, b.entry_id, b.original_date);
  const periods = await getPeriods();
  const change = await tx(async (db) => {
    await db.query('SELECT pg_advisory_xact_lock(3003, 0)');  // rescheduling is rare; one at a time is fine
    const check = await checkSlot(db, entry, b.original_date, b.new_date, b.period_start, b.room_id);
    if (check.error) throw conflict(`That slot no longer works: ${check.error}`);
    const { rows: [c] } = await db.query(
      `INSERT INTO class_changes (entry_id, original_date, action, new_date, new_period_start, new_period_end, new_room_id, reason, created_by)
       VALUES ($1, $2, 'moved', $3, $4, $5, $6, $7, $8) RETURNING *`,
      [entry.id, b.original_date, b.new_date, b.period_start, check.period_end, b.room_id, b.reason || null, req.user.id]);
    const { rows: [room] } = await db.query('SELECT name FROM rooms WHERE id = $1', [b.room_id]);
    const label = entry.label || entry.subject_name;
    const sent = await notifyUsers(db, await studentIdsOfSection(db, entry.section_id), {
      type: 'class_change',
      title: `${label} moved`,
      body: `${label} on ${fmtSlot(periods, b.original_date, entry.period_start, entry.period_end)} is moved to `
        + `${fmtSlot(periods, b.new_date, b.period_start, check.period_end)} in ${room.name}.`
        + (b.reason ? ` Reason: ${b.reason}` : ''),
      data: { change_id: c.id, entry_id: entry.id },
    });
    return { ...c, notified: sent };
  });
  res.status(201).json({ change });
});

router.post('/cancel', async (req, res) => {
  const b = parse(z.object({
    entry_id: z.coerce.number().int(), original_date: z.string(),
    reason: z.string().trim().max(200).optional().nullable(),
  }), req.body);
  const entry = await ownedOccurrence(req.user.id, b.entry_id, b.original_date);
  const periods = await getPeriods();
  const change = await tx(async (db) => {
    const { rows: [c] } = await db.query(
      `INSERT INTO class_changes (entry_id, original_date, action, reason, created_by)
       VALUES ($1, $2, 'cancelled', $3, $4) RETURNING *`,
      [entry.id, b.original_date, b.reason || null, req.user.id]);
    const label = entry.label || entry.subject_name;
    const sent = await notifyUsers(db, await studentIdsOfSection(db, entry.section_id), {
      type: 'class_change',
      title: `${label} cancelled`,
      body: `${label} on ${fmtSlot(periods, b.original_date, entry.period_start, entry.period_end)} is cancelled.`
        + (b.reason ? ` Reason: ${b.reason}` : ''),
      data: { change_id: c.id, entry_id: entry.id },
    });
    return { ...c, notified: sent };
  });
  res.status(201).json({ change });
});

/** Undo a cancel / move (own changes only), and tell the section. */
router.delete('/changes/:id', async (req, res) => {
  const { rows: [c] } = await query(
    `SELECT c.*, e.professor_id, e.section_id, COALESCE(e.label, s.name) AS label
       FROM class_changes c JOIN timetable_entries e ON e.id = c.entry_id JOIN subjects s ON s.id = e.subject_id
      WHERE c.id = $1`, [Number(req.params.id) || 0]);
  if (!c) throw notFound('Change not found');
  if (c.professor_id !== req.user.id) throw forbidden('You can only undo changes to your own classes');
  if (c.original_date < nowIST().date) throw badRequest('This change is in the past');
  await tx(async (db) => {
    await db.query('DELETE FROM class_changes WHERE id = $1', [c.id]);
    await notifyUsers(db, await studentIdsOfSection(db, c.section_id), {
      type: 'class_change', title: `${c.label} is back on`,
      body: `${c.label} on ${c.original_date} is back at its usual time and room.`,
    });
  });
  res.json({ ok: true });
});
