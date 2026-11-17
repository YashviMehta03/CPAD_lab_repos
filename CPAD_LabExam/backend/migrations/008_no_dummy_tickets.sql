-- Removes the seeded demo helpdesk tickets (those reported by people without a login).
-- Tickets reported by real signed-up students are kept.
DELETE FROM tickets WHERE student_id IN (SELECT id FROM users WHERE auth_id IS NULL);
DELETE FROM notifications
 WHERE type = 'ticket' AND NOT EXISTS (SELECT 1 FROM tickets t WHERE t.id = (notifications.data->>'ticket_id')::int);
