-- Paperwork help keeps only Bonafide, Duplicate ID Card and NOC, and drops the seeded fake
-- helpers, questions and chats. Posts, helpers and chats by real (signed-up) users are kept.
DELETE FROM conversations WHERE user_a IN (SELECT id FROM users WHERE auth_id IS NULL AND role = 'student')
                             OR user_b IN (SELECT id FROM users WHERE auth_id IS NULL AND role = 'student');
DELETE FROM board_posts   WHERE author_id    IN (SELECT id FROM users WHERE auth_id IS NULL);
DELETE FROM board_helpers WHERE student_id   IN (SELECT id FROM users WHERE auth_id IS NULL);
DELETE FROM form_types WHERE code IN ('nodues', 'buspass', 'scholarship');
INSERT INTO form_types (code, name, description, office)
VALUES ('noc', 'No Objection Certificate (NOC)', 'For internships, competitions, or applying to another institute or company.', 'Department office, then Academic Section')
ON CONFLICT (code) DO NOTHING;
