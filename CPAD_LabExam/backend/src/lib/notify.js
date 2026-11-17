import { pool } from '../db.js';

/** Insert one in-app notification per user. Returns the number sent. */
export async function notifyUsers(db, userIds, { type, title, body = null, data = {} }) {
  const ids = [...new Set(userIds.filter(Boolean))];
  if (!ids.length) return 0;
  await (db || pool).query(
    `INSERT INTO notifications (user_id, type, title, body, data)
     SELECT unnest($1::int[]), $2, $3, $4, $5::jsonb`,
    [ids, type, title, body, JSON.stringify(data)],
  );
  return ids.length;
}

export async function studentIdsOfSection(db, sectionId) {
  const { rows } = await (db || pool).query('SELECT user_id FROM students WHERE section_id = $1', [sectionId]);
  return rows.map((r) => r.user_id);
}
