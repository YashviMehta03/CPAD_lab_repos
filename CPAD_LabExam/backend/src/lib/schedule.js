// The shared timetable + room model. It feeds the professor availability default,
// the free-room finder, the smart rescheduler and the project meeting slot finder.
import { pool } from '../db.js';
import {
  addDays, blockStarts, currentPeriod, DAY_NAMES, dowOf, getPeriods, nowIST, toMin,
} from './time.js';

const ENTRY_SQL = `
  SELECT e.id, e.section_id, e.day, e.period_start, e.period_end, e.subject_id, e.professor_id,
         e.room_id, e.kind, e.label, e.batch, e.parallel_group,
         s.code AS subject_code, s.name AS subject_name, r.name AS room_name,
         u.name AS professor_name, p.code AS professor_code,
         sec.name AS section_name, b.code AS branch_code, y.code AS year_code
    FROM timetable_entries e
    JOIN subjects s   ON s.id = e.subject_id
    JOIN sections sec ON sec.id = e.section_id
    JOIN branches b   ON b.id = sec.branch_id
    JOIN years y      ON y.id = sec.year_id
    LEFT JOIN rooms r      ON r.id = e.room_id
    LEFT JOIN professors p ON p.user_id = e.professor_id
    LEFT JOIN users u      ON u.id = e.professor_id`;

export async function loadEntries(db = pool, where = '', params = []) {
  const { rows } = await db.query(`${ENTRY_SQL} ${where} ORDER BY e.day, e.period_start, e.id`, params);
  return rows;
}

export const overlaps = (a1, a2, b1, b2) => a1 <= b2 && b1 <= a2;
export const isActive = (o) => o.status === 'scheduled' || o.status === 'moved_in';

/**
 * Concrete class occurrences between two dates (inclusive), with one-off changes applied.
 * status: scheduled | moved_in (rescheduled into this slot) | cancelled | moved_away.
 * The last two are only returned with includeInactive, for display.
 */
export async function getOccurrences(db, from, to, { includeInactive = false } = {}) {
  const entries = await loadEntries(db);
  const { rows: changes } = await db.query(
    `SELECT c.*, r.name AS new_room_name
       FROM class_changes c LEFT JOIN rooms r ON r.id = c.new_room_id
      WHERE c.original_date BETWEEN $1 AND $2 OR c.new_date BETWEEN $1 AND $2`,
    [from, to],
  );
  const changeByKey = new Map(changes.map((c) => [`${c.entry_id}|${c.original_date}`, c]));
  const entryById = new Map(entries.map((e) => [e.id, e]));
  const out = [];

  for (let d = from; d <= to; d = addDays(d, 1)) {
    const dow = dowOf(d);
    if (dow > 5) continue;
    for (const e of entries) {
      if (e.day !== dow) continue;
      const c = changeByKey.get(`${e.id}|${d}`);
      if (!c) out.push({ ...e, date: d, status: 'scheduled' });
      else if (includeInactive) {
        out.push({
          ...e, date: d, status: c.action === 'cancelled' ? 'cancelled' : 'moved_away',
          change_id: c.id, reason: c.reason,
          new_date: c.new_date, new_period_start: c.new_period_start, new_period_end: c.new_period_end,
          new_room_name: c.new_room_name,
        });
      }
    }
  }
  for (const c of changes) {
    if (c.action !== 'moved' || c.new_date < from || c.new_date > to) continue;
    const e = entryById.get(c.entry_id);
    if (!e) continue;
    out.push({
      ...e, date: c.new_date, period_start: c.new_period_start, period_end: c.new_period_end,
      room_id: c.new_room_id ?? e.room_id, room_name: c.new_room_name ?? e.room_name,
      status: 'moved_in', change_id: c.id, original_date: c.original_date, reason: c.reason,
    });
  }
  out.sort((a, b) => a.date.localeCompare(b.date) || a.period_start - b.period_start || a.id - b.id);
  return out;
}

const periodInfo = (periods, s, e) => ({
  start_time: periods.find((p) => p.period === s)?.start,
  end_time: periods.find((p) => p.period === e)?.end,
});

// ---------------------------------------------------------------- availability

/** Campus closes at 5:30 pm: from then on professors who are not on leave show as out of college. */
const CLOSING_MINUTES = 17 * 60 + 30;

/** Effective status per professor: on_leave > out_of_college (after 5:30 pm) > in_class (from timetable) > manual toggle. */
export async function professorStatuses(db = pool) {
  const now = nowIST();
  const periods = await getPeriods(db);
  const cur = now.dow <= 5 ? currentPeriod(periods, now.minutes) : null;
  const todays = now.dow <= 5 ? (await getOccurrences(db, now.date, now.date)).filter(isActive) : [];
  const inClass = new Map();
  if (cur) {
    for (const o of todays) {
      if (o.professor_id && o.period_start <= cur && cur <= o.period_end) inClass.set(o.professor_id, o);
    }
  }
  const { rows } = await db.query(`
    SELECT p.user_id AS id, u.name, p.code, p.cabin, p.manual_status, p.status_note, p.status_updated_at,
           b.code AS department,
           (SELECT COUNT(*) FROM queue_tokens q
             WHERE q.professor_id = p.user_id AND q.queue_date = $1 AND q.status = 'waiting') AS queue_waiting
      FROM professors p JOIN users u ON u.id = p.user_id
      LEFT JOIN branches b ON b.id = p.department_id
     ORDER BY u.name`, [now.date]);
  return rows.map((p) => {
    const occ = inClass.get(p.id);
    let status = p.manual_status;
    if (status !== 'on_leave' && occ) status = 'in_class';
    if (status !== 'on_leave' && now.minutes >= CLOSING_MINUTES) status = 'out_of_college';
    const nextClass = todays.find(
      (o) => o.professor_id === p.id && toMin(periodInfo(periods, o.period_start, o.period_end).start_time) > now.minutes,
    );
    return {
      ...p,
      status,
      auto: status === 'in_class',
      current_class: occ ? {
        label: occ.label || occ.subject_name, room: occ.room_name,
        section: `${occ.branch_code} ${occ.year_code}-${occ.section_name}`,
        ...periodInfo(periods, occ.period_start, occ.period_end),
      } : null,
      next_class: nextClass ? {
        label: nextClass.label || nextClass.subject_name, room: nextClass.room_name,
        ...periodInfo(periods, nextClass.period_start, nextClass.period_end),
      } : null,
    };
  });
}

// ---------------------------------------------------------------- rooms

/** Rooms free for the whole of [ps, pe] on date, plus what occupies the others. */
export async function roomAvailability(db, date, ps, pe) {
  const periods = await getPeriods(db);
  const occ = (await getOccurrences(db, date, date)).filter(isActive);
  const { rows: rooms } = await db.query('SELECT * FROM rooms ORDER BY type, name');
  const lastP = periods.at(-1).period;

  return rooms.map((r) => {
    const uses = [
      ...occ.filter((o) => o.room_id === r.id).map((o) => ({
        kind: 'class', period_start: o.period_start, period_end: o.period_end,
        label: `${o.label || o.subject_name} (${o.branch_code} ${o.year_code}-${o.section_name})`,
      })),
    ];
    const blocking = uses.filter((u) => overlaps(u.period_start, u.period_end, ps, pe));
    let freeUntil = null;
    if (!blocking.length) {
      const nextUse = uses.filter((u) => u.period_start > pe).sort((a, b) => a.period_start - b.period_start)[0];
      const untilP = nextUse ? nextUse.period_start - 1 : lastP;
      freeUntil = periods.find((p) => p.period === untilP)?.end ?? null;
    }
    return { ...r, free: blocking.length === 0, occupied_by: blocking.map((u) => u.label), free_until: freeUntil };
  });
}

// ---------------------------------------------------------------- rescheduler

/**
 * Build the context needed to test candidate slots for moving one class occurrence:
 * the busy set comes from the section's timetable, and the professor's own classes.
 */
async function rescheduleContext(db, entry, originalDate, days) {
  const periods = await getPeriods(db);
  const now = nowIST();
  const from = now.date;
  const to = addDays(now.date, days);
  const occ = (await getOccurrences(db, from, to)).filter(
    (o) => isActive(o) && !(o.id === entry.id && o.date === originalDate && o.status === 'scheduled'),
  );
  const { rows: [section] } = await db.query('SELECT strength FROM sections WHERE id = $1', [entry.section_id]);
  const roomType = entry.kind === 'lab' ? 'lab' : 'classroom';
  const { rows: rooms } = await db.query(
    'SELECT id, name, type, capacity FROM rooms WHERE type = $1 AND capacity >= $2 ORDER BY capacity, name',
    [roomType, section.strength],
  );
  return { periods, now, from, to, occ, rooms, strength: section.strength, roomType };
}

/** Why a slot does not work, or null + the free rooms if it does. */
function evaluateSlot(ctx, entry, date, s, e) {
  const dayOcc = ctx.occ.filter((o) => o.date === date);
  const clash = (o) => overlaps(o.period_start, o.period_end, s, e);
  if (dayOcc.some((o) => o.section_id === entry.section_id && clash(o))) return { error: 'The section has another class then' };
  if (dayOcc.some((o) => o.professor_id === entry.professor_id && clash(o))) return { error: 'You have another class then' };
  const busyRooms = new Set(dayOcc.filter((o) => o.room_id && clash(o)).map((o) => o.room_id));
  const free = ctx.rooms.filter((r) => !busyRooms.has(r.id));
  if (!free.length) return { error: `No ${ctx.roomType} with ${ctx.strength}+ seats is free then` };
  const backToBack = dayOcc.some((o) => o.professor_id === entry.professor_id && (o.period_end === s - 1 || o.period_start === e + 1));
  return { free, backToBack };
}

export async function suggestSlots(db, entry, originalDate, { days = 7, limit = 3 } = {}) {
  const ctx = await rescheduleContext(db, entry, originalDate, days);
  const { periods, now } = ctx;
  const len = entry.period_end - entry.period_start + 1;
  const starts = blockStarts(periods, len);
  const firstP = periods[0].period;
  const lastP = periods.at(-1).period;
  const candidates = [];

  for (let off = 0; off <= days; off++) {
    const date = addDays(ctx.from, off);
    if (dowOf(date) > 5) continue;
    for (const s of starts) {
      const e = s + len - 1;
      if (off === 0 && toMin(periods.find((p) => p.period === s).start) <= now.minutes) continue;
      if (date === originalDate && s === entry.period_start) continue;
      const r = evaluateSlot(ctx, entry, date, s, e);
      if (r.error) continue;
      const room = r.free.find((x) => x.id === entry.room_id) ?? r.free[0];
      const edge = (s === firstP ? 1 : 0) + (e === lastP ? 1 : 0);
      const score = off * 20 + edge * 6 + (r.backToBack ? 4 : 0) + (room.id === entry.room_id ? 0 : 1);
      const reasons = [`Whole section free`, `${room.name} free (${room.capacity} seats)`];
      if (room.id === entry.room_id) reasons.push('Same room as usual');
      if (!r.backToBack) reasons.push('Not back-to-back for you');
      else reasons.push('Back-to-back with another of your classes');
      if (edge) reasons.push(s === firstP ? 'First period of the day' : 'Last period of the day');
      candidates.push({
        date, day: DAY_NAMES[dowOf(date)], period_start: s, period_end: e,
        ...periodInfo(periods, s, e),
        room_id: room.id, room_name: room.name, room_capacity: room.capacity,
        other_free_rooms: r.free.filter((x) => x.id !== room.id).map((x) => ({ id: x.id, name: x.name, capacity: x.capacity })),
        score, reasons,
      });
    }
  }
  candidates.sort((a, b) => a.score - b.score || a.date.localeCompare(b.date) || a.period_start - b.period_start);
  return candidates.slice(0, limit);
}

/** Re-check one slot right before applying it (someone may have booked it meanwhile). */
export async function checkSlot(db, entry, originalDate, date, s, roomId) {
  const ctx = await rescheduleContext(db, entry, originalDate, 14);
  const e = s + (entry.period_end - entry.period_start);
  const r = evaluateSlot(ctx, entry, date, s, e);
  if (r.error) return { error: r.error };
  if (!r.free.some((x) => x.id === roomId)) return { error: 'That room is not free or not suitable then' };
  return { period_end: e };
}

// ---------------------------------------------------------------- meetings

/** Single periods in the next `days` days when every given section and the professor are free. */
export async function commonFreeSlots(db, { sectionIds, professorId, days = 7, limit = 12 }) {
  const periods = await getPeriods(db);
  const now = nowIST();
  const from = now.date;
  const to = addDays(from, days);
  const occ = (await getOccurrences(db, from, to)).filter(isActive);
  const { rows: meetings } = await db.query(
    `SELECT m.date, m.period FROM meeting_requests m JOIN project_groups g ON g.id = m.group_id
      WHERE g.guide_id = $1 AND m.status = 'accepted' AND m.date BETWEEN $2 AND $3`,
    [professorId, from, to],
  );
  const out = [];
  for (let off = 0; off <= days && out.length < limit; off++) {
    const date = addDays(from, off);
    if (dowOf(date) > 5) continue;
    const dayOcc = occ.filter((o) => o.date === date);
    for (const p of periods) {
      if (off === 0 && toMin(p.start) <= now.minutes) continue;
      const clash = (o) => o.period_start <= p.period && p.period <= o.period_end;
      if (dayOcc.some((o) => sectionIds.includes(o.section_id) && clash(o))) continue;
      if (dayOcc.some((o) => o.professor_id === professorId && clash(o))) continue;
      if (meetings.some((m) => m.date === date && m.period === p.period)) continue;
      out.push({ date, day: DAY_NAMES[dowOf(date)], period: p.period, start_time: p.start, end_time: p.end });
      if (out.length >= limit) break;
    }
  }
  return out;
}
