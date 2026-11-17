import { config } from '../config.js';
import { pool } from '../db.js';

const fmt = new Intl.DateTimeFormat('en-CA', {
  timeZone: 'Asia/Kolkata',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  hourCycle: 'h23',
});

export const DAY_NAMES = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/** Monday=1 ... Sunday=7 for a 'YYYY-MM-DD' string. */
export function dowOf(date) {
  const [y, m, d] = date.split('-').map(Number);
  const w = new Date(Date.UTC(y, m - 1, d)).getUTCDay();
  return w === 0 ? 7 : w;
}

export function addDays(date, n) {
  const [y, m, d] = date.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
}

export function diffDays(a, b) {
  const t = (s) => {
    const [y, m, d] = s.split('-').map(Number);
    return Date.UTC(y, m - 1, d);
  };
  return Math.round((t(b) - t(a)) / 86400000);
}

export const isDate = (s) => typeof s === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(s);

export const toMin = (t) => {
  const [h, m] = t.split(':').map(Number);
  return h * 60 + m;
};

/** Campus wall-clock now (IST). DEMO_NOW freezes it for demos. */
export function nowIST() {
  if (config.demoNow) {
    const [date, time = '12:00'] = config.demoNow.split('T');
    const [h, m] = time.split(':').map(Number);
    return { date, minutes: h * 60 + m, dow: dowOf(date) };
  }
  const p = Object.fromEntries(fmt.formatToParts(new Date()).map((x) => [x.type, x.value]));
  const date = `${p.year}-${p.month}-${p.day}`;
  return { date, minutes: Number(p.hour) * 60 + Number(p.minute), dow: dowOf(date) };
}

/** Monday of the week containing date. */
export const weekStart = (date) => addDays(date, 1 - dowOf(date));

let periodCache = null;
let periodCacheAt = 0;

/** Teaching periods, ordered: [{period, start:'HH:MM', end:'HH:MM'}]. */
export async function getPeriods(db = pool) {
  if (periodCache && Date.now() - periodCacheAt < 60_000) return periodCache;
  const { rows } = await db.query(
    `SELECT period, to_char(start_time,'HH24:MI') AS start, to_char(end_time,'HH24:MI') AS "end"
       FROM periods ORDER BY period`,
  );
  periodCache = rows;
  periodCacheAt = Date.now();
  return rows;
}

export function currentPeriod(periods, minutes) {
  return periods.find((p) => minutes >= toMin(p.start) && minutes <= toMin(p.end))?.period ?? null;
}

/** The current period, or the next one that has not started yet today. */
export function currentOrNextPeriod(periods, minutes) {
  return currentPeriod(periods, minutes) ?? periods.find((p) => toMin(p.start) > minutes)?.period ?? null;
}

/** Start periods where a contiguous block of `len` periods fits without crossing a break. */
export function blockStarts(periods, len) {
  const out = [];
  for (let i = 0; i + len - 1 < periods.length; i++) {
    let ok = true;
    for (let j = i; j < i + len - 1; j++) {
      const gap = toMin(periods[j + 1].start) - toMin(periods[j].end);
      if (periods[j + 1].period !== periods[j].period + 1 || gap > 10) ok = false;
    }
    if (ok) out.push(periods[i].period);
  }
  return out;
}
