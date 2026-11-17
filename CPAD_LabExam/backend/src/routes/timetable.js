import { Router } from 'express';
import { query, pool } from '../db.js';
import { badRequest, notFound } from '../lib/http.js';
import { getOccurrences, loadEntries } from '../lib/schedule.js';
import { addDays, getPeriods, isDate, nowIST, weekStart } from '../lib/time.js';
import { requireRole } from '../middleware/auth.js';

export const router = Router();

async function sectionInfo(id) {
  const { rows: [s] } = await query(
    `SELECT s.id, s.name, s.strength, b.code AS branch_code, b.name AS branch_name, y.code AS year_code, y.name AS year_name
       FROM sections s JOIN branches b ON b.id = s.branch_id JOIN years y ON y.id = s.year_id WHERE s.id = $1`, [id]);
  return s;
}

/** The week (Mon-Fri) of `date` as concrete occurrences, including cancelled / moved classes. */
async function weekFor(filter, date) {
  const from = weekStart(date);
  const occ = await getOccurrences(pool, from, addDays(from, 4), { includeInactive: true });
  return { from, to: addDays(from, 4), occurrences: occ.filter(filter) };
}

/** Own timetable: the student's section, or the professor's classes across sections. */
router.get('/me', requireRole('student', 'professor'), async (req, res) => {
  const date = isDate(req.query.date) ? req.query.date : nowIST().date;
  const periods = await getPeriods();
  if (req.user.role === 'student') {
    const { rows: [st] } = await query('SELECT section_id FROM students WHERE user_id = $1', [req.user.id]);
    if (!st) throw notFound('Student profile missing');
    const entries = await loadEntries(pool, 'WHERE e.section_id = $1', [st.section_id]);
    const week = await weekFor((o) => o.section_id === st.section_id, date);
    return res.json({ section: await sectionInfo(st.section_id), periods, entries, week });
  }
  const entries = await loadEntries(pool, 'WHERE e.professor_id = $1', [req.user.id]);
  const week = await weekFor((o) => o.professor_id === req.user.id, date);
  res.json({ section: null, periods, entries, week });
});

/** Read-only timetable of any section (browse other branches, years, sections). */
router.get('/section/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) throw badRequest('Invalid section');
  const section = await sectionInfo(id);
  if (!section) throw notFound('Section not found');
  const date = isDate(req.query.date) ? req.query.date : nowIST().date;
  const entries = await loadEntries(pool, 'WHERE e.section_id = $1', [id]);
  const week = await weekFor((o) => o.section_id === id, date);
  res.json({ section, periods: await getPeriods(), entries, week });
});
