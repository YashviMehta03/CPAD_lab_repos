// Automatic helpdesk escalation: a ticket that passes its category deadline moves one level up
// (category handler -> HOD -> dean) and gets a fresh deadline.
import { tx } from '../db.js';
import { notifyUsers } from './notify.js';

export const LEVEL_NAMES = { 1: 'Handler', 2: 'HOD', 3: 'Dean' };

export async function adminsAtLevel(db, level) {
  const { rows } = await db.query('SELECT user_id FROM admins WHERE level = $1', [level]);
  return rows.map((r) => r.user_id);
}

export async function runEscalation() {
  return tx(async (db) => {
    const { rows } = await db.query(`
      UPDATE tickets t
         SET escalation_level = t.escalation_level + 1,
             due_at = now() + make_interval(hours => c.sla_hours),
             updated_at = now()
        FROM ticket_categories c
       WHERE c.id = t.category_id AND t.status IN ('open', 'in_progress')
         AND t.due_at < now() AND t.escalation_level < 3
      RETURNING t.id, t.title, t.student_id, t.escalation_level`);
    for (const t of rows) {
      const to = LEVEL_NAMES[t.escalation_level];
      await db.query(
        `INSERT INTO ticket_events (ticket_id, type, note) VALUES ($1, 'auto_escalated', $2)`,
        [t.id, `Deadline passed, escalated to ${to}`]);
      await notifyUsers(db, [t.student_id], {
        type: 'ticket', title: `Ticket #${t.id} escalated to ${to}`,
        body: `"${t.title}" was not resolved in time, so it went up to the ${to}.`, data: { ticket_id: t.id },
      });
      await notifyUsers(db, await adminsAtLevel(db, t.escalation_level), {
        type: 'ticket', title: `Escalated ticket #${t.id}`,
        body: `"${t.title}" passed its deadline and is now with you.`, data: { ticket_id: t.id },
      });
    }
    return rows.length;
  });
}

export function startEscalationJob(intervalMs = 60_000) {
  const tick = () => runEscalation()
    .then((n) => n && console.log(`auto-escalated ${n} ticket(s)`))
    .catch((e) => console.error('escalation job failed:', e.message));
  tick();
  return setInterval(tick, intervalMs);
}
