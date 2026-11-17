import { Router } from 'express';
import { pool } from '../db.js';
import { badRequest } from '../lib/http.js';
import { roomAvailability } from '../lib/schedule.js';
import {
  addDays, currentOrNextPeriod, DAY_NAMES, dowOf, getPeriods, isDate, nowIST,
} from '../lib/time.js';

export const router = Router();

/** Free rooms on a date for a period range. Defaults to now (or the next period today). */
router.get('/free', async (req, res) => {
  const periods = await getPeriods();
  const now = nowIST();
  let date = isDate(req.query.date) ? req.query.date : now.date;
  let ps = Number(req.query.period_start) || null;
  if (!ps && date === now.date) {
    ps = currentOrNextPeriod(periods, now.minutes);
    if (!ps) { date = addDays(date, 1); ps = periods[0].period; }  // day is over: show tomorrow morning
  }
  ps = ps || periods[0].period;
  while (dowOf(date) > 5) date = addDays(date, 1);
  const pe = Math.max(Number(req.query.period_end) || ps, ps);
  if (!periods.some((p) => p.period === ps) || !periods.some((p) => p.period === pe)) throw badRequest('Unknown period');

  const type = ['lab', 'classroom'].includes(req.query.type) ? req.query.type : null;
  const minCap = Number(req.query.min_capacity) || 0;
  let rooms = await roomAvailability(pool, date, ps, pe);
  rooms = rooms.filter((r) => (!type || r.type === type) && r.capacity >= minCap);
  res.json({
    date, day: DAY_NAMES[dowOf(date)], period_start: ps, period_end: pe,
    start_time: periods.find((p) => p.period === ps).start,
    end_time: periods.find((p) => p.period === pe).end,
    free: rooms.filter((r) => r.free),
    occupied: rooms.filter((r) => !r.free),
  });
});
