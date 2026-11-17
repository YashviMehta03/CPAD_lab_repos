// Exam helpline: who to call about a subject during an exam. Professors only, since it shows phone numbers.
import { Router } from 'express';
import { query } from '../db.js';
import { professorStatuses } from '../lib/schedule.js';

export const router = Router();

const optInt = (v) => (v === undefined || v === '' ? null : Number(v) || null);

router.get('/', async (req, res) => {
  const branchId = optInt(req.query.branch_id);
  const yearId = optInt(req.query.year_id);
  const subjectId = optInt(req.query.subject_id);
  const q = String(req.query.q || '').trim();

  // Subjects taught to the chosen branch / year, with the teachers assigned to them there.
  const { rows: taught } = await query(
    `SELECT s.id AS subject_id, s.code, s.name, e.professor_id,
            array_agg(DISTINCT b.code || ' ' || y.code || '-' || sec.name) AS sections
       FROM timetable_entries e
       JOIN subjects s ON s.id = e.subject_id
       JOIN sections sec ON sec.id = e.section_id
       JOIN branches b ON b.id = sec.branch_id JOIN years y ON y.id = sec.year_id
      WHERE ($1::int IS NULL OR sec.branch_id = $1) AND ($2::int IS NULL OR sec.year_id = $2)
        AND ($3::int IS NULL OR s.id = $3)
        AND ($4 = '' OR s.name ILIKE '%' || $4 || '%' OR s.code ILIKE '%' || $4 || '%')
      GROUP BY s.id, s.code, s.name, e.professor_id
      ORDER BY s.name`,
    [branchId, yearId, subjectId, q]);

  const subjectIds = [...new Set(taught.map((t) => t.subject_id))];
  const { rows: knows } = subjectIds.length ? await query(
    `SELECT ps.subject_id, ps.professor_id, ps.is_backup, ps.rank FROM professor_subjects ps
      WHERE ps.subject_id = ANY($1)`, [subjectIds]) : { rows: [] };
  const { rows: phones } = await query(
    `SELECT u.id, u.phone FROM users u WHERE u.role = 'professor'`);
  const phoneOf = new Map(phones.map((p) => [p.id, p.phone]));
  const statusOf = new Map((await professorStatuses()).map((p) => [p.id, p]));
  const card = (id, extra = {}) => {
    const p = statusOf.get(id);
    return p && {
      id, name: p.name, code: p.code, cabin: p.cabin, department: p.department, status: p.status,
      status_note: p.status_note, current_class: p.current_class, phone: phoneOf.get(id) ?? null, ...extra,
    };
  };
  // Available people first among equals.
  const availability = { in_cabin: 0, busy: 1, in_class: 2, away: 3, out_of_college: 4, on_leave: 5 };

  const subjects = subjectIds.map((sid) => {
    const rows = taught.filter((t) => t.subject_id === sid);
    const assignedIds = [...new Set(rows.map((r) => r.professor_id).filter(Boolean))];
    const assigned = assignedIds.map((id) => card(id, {
      sections: rows.filter((r) => r.professor_id === id).flatMap((r) => r.sections),
    })).filter(Boolean);
    // Backups: tagged backups by rank, then others who teach this subject elsewhere.
    const backups = knows
      .filter((k) => k.subject_id === sid && !assignedIds.includes(k.professor_id))
      .map((k) => ({ k, c: card(k.professor_id, { reason: k.is_backup ? 'Tagged backup' : 'Teaches this subject' }) }))
      .filter((x) => x.c)
      .sort((a, b) => (a.k.is_backup === b.k.is_backup ? 0 : a.k.is_backup ? -1 : 1)
        || a.k.rank - b.k.rank
        || availability[a.c.status] - availability[b.c.status])
      .map((x) => x.c);
    return { subject_id: sid, code: rows[0].code, name: rows[0].name, assigned, backups };
  });
  res.json({ subjects });
});
