import { Router } from 'express';
import { query } from '../db.js';
import { getPeriods, nowIST, currentPeriod } from '../lib/time.js';

export const router = Router();

/** Campus structure for pickers: branches, years, sections, periods, rooms and the campus clock. */
router.get('/structure', async (_req, res) => {
  const [branches, years, sections, rooms, periods] = await Promise.all([
    query('SELECT id, code, name FROM branches ORDER BY code'),
    query('SELECT id, code, name, ord FROM years ORDER BY ord'),
    query(`SELECT s.id, s.name, s.strength, s.branch_id, s.year_id, b.code AS branch_code, y.code AS year_code
             FROM sections s JOIN branches b ON b.id = s.branch_id JOIN years y ON y.id = s.year_id
            ORDER BY b.code, y.ord, s.name`),
    query('SELECT id, name, type, capacity, building, bookable FROM rooms ORDER BY type, name'),
    getPeriods(),
  ]);
  const now = nowIST();
  res.json({
    branches: branches.rows,
    years: years.rows,
    sections: sections.rows,
    rooms: rooms.rows,
    periods,
    now: { ...now, period: now.dow <= 5 ? currentPeriod(periods, now.minutes) : null },
  });
});

router.get('/subjects', async (_req, res) => {
  const { rows } = await query(
    `SELECT s.id, s.code, s.name, b.code AS branch_code FROM subjects s
       LEFT JOIN branches b ON b.id = s.branch_id ORDER BY s.name`,
  );
  res.json({ subjects: rows });
});
