// End-to-end smoke test of the API against the seeded database.
// Run `npm run seed` first (it resets data). Usage: npm test
import { assertConfig } from '../src/config.js';
import { createApp } from '../src/app.js';
import { pool } from '../src/db.js';
import { runEscalation } from '../src/lib/escalation.js';
import { signToken } from '../src/middleware/auth.js';

assertConfig();
const server = createApp().listen(0);
const base = `http://localhost:${server.address().port}/api`;
let passed = 0;
const failures = [];

async function call(token, method, path, body) {
  const res = await fetch(base + path, {
    method,
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, body: await res.json().catch(() => null) };
}
function check(name, cond, detail) {
  if (cond) passed++;
  else failures.push(`${name}${detail ? ` -> ${JSON.stringify(detail).slice(0, 300)}` : ''}`);
}
// Seeded people have no Supabase login, so the test mints app tokens for them directly.
const login = async (email) => {
  const { rows: [u] } = await pool.query(`SELECT id, role FROM users WHERE email = $1 OR email = split_part($1, '@', 1) || '@gmail.com'`, [email]);
  return u ? signToken(u) : null;
};

try {
  // ---------------- step 1: auth, roles, timetable
  const bad = await call(null, 'POST', '/auth/login', { email: 'nobody@campus.test', password: 'nope1234' });
  check('wrong password rejected', bad.status === 401, bad.body);
  check('signup options public', (await call(null, 'GET', '/auth/options')).body?.sections?.length > 0);
  const dupSignup = await call(null, 'POST', '/auth/signup', { role: 'student', name: 'Dup', email: 'student@campus.test', password: 'secret1', section_id: 1, roll_no: 'X1' });
  check('signup with taken email rejected', dupSignup.status === 409, dupSignup.body);
  const adminSignup = await call(null, 'POST', '/auth/signup', { role: 'admin', name: 'Hacker', email: 'h@campus.test', password: 'secret1' });
  check('admin self-signup rejected', adminSignup.status === 400, adminSignup.body);
  check('no token rejected', (await call(null, 'GET', '/auth/me')).status === 401);
  const stu = await login('student@campus.test');
  const stu2 = await login('rohan.chavan@campus.test');
  const prof = await login('pv@campus.test');
  const sts = await login('sts@campus.test');
  const estate = await login('estate@campus.test');
  const warden = await login('warden@campus.test');
  const hod = await login('hod@campus.test');
  check('logins work', stu && prof && estate && hod && sts && warden);
  const me = await call(stu, 'GET', '/auth/me');
  check('student profile has section', me.body?.user?.student?.section_name === 'A', me.body);
  const tt = await call(stu, 'GET', '/timetable/me');
  check('student timetable', tt.status === 200 && tt.body.entries.length > 30, tt.body?.entries?.length);
  const ptt = await call(prof, 'GET', '/timetable/me');
  check('professor timetable is own classes', ptt.body.entries.every((e) => e.professor_code === 'PV'));
  const struct = await call(stu, 'GET', '/meta/structure');
  check('structure', struct.body.sections.length === 7 && struct.body.periods.length === 9);
  const other = struct.body.sections.find((s) => s.branch_code === 'EXTC');
  check('read other section timetable', (await call(stu, 'GET', `/timetable/section/${other.id}`)).body.entries.length > 0);
  check('student blocked from admin', (await call(stu, 'GET', '/admin/rooms')).status === 403);
  check('professor blocked from admin', (await call(prof, 'GET', '/admin/users')).status === 403);

  // ---------------- step 2: availability, queue, helpline
  const profs = await call(stu, 'GET', '/professors');
  check('professor list', profs.body.professors.length === 20);
  check('no phone numbers for students', profs.body.professors.every((p) => !('phone' in p)));
  const pv = profs.body.professors.find((p) => p.code === 'PV');
  const rs = profs.body.professors.find((p) => p.code === 'RS');
  check('on leave shown', rs.status === 'on_leave');
  check('student cannot set status', (await call(stu, 'PUT', '/professors/me/status', { status: 'busy' })).status === 403);
  const st = await call(prof, 'PUT', '/professors/me/status', { status: 'in_cabin', note: 'Free till 4' });
  check('prof sets status', st.status === 200 && ['in_cabin', 'in_class'].includes(st.body.professor.status), st.body);
  const join = await call(stu, 'POST', `/queue/${pv.id}/join`, { purpose: 'Doubt in lab 9' });
  check('join queue', join.status === 201 && join.body.token.position === 1, join.body);
  check('cannot join twice', (await call(stu, 'POST', `/queue/${pv.id}/join`, {})).status === 409);
  check('cannot join queue of prof on leave', (await call(stu, 'POST', `/queue/${rs.id}/join`, {})).status === 400);
  if (stu2) {
    const j2 = await call(stu2, 'POST', `/queue/${pv.id}/join`, {});
    check('second student is position 2', j2.body?.token?.position === 2, j2.body);
  }
  check('other prof cannot touch token', (await call(sts, 'POST', `/queue/manage/tokens/${join.body.token.id}/skip`)).status === 403);
  const next = await call(prof, 'POST', '/queue/manage/next');
  check('call next', next.body.called?.token_no === 1, next.body);
  const mine = await call(stu, 'GET', '/queue/mine');
  check('student sees serving', mine.body.tokens[0]?.status === 'serving');
  const done = await call(prof, 'POST', `/queue/manage/tokens/${join.body.token.id}/complete`);
  check('complete token', done.status === 200 && !done.body.serving, done.body);
  check('student blocked from helpline', (await call(stu, 'GET', '/helpline')).status === 403);
  const ce = struct.body.branches.find((b) => b.code === 'CE');
  const fin = struct.body.years.find((y) => y.code === 'Final');
  const help = await call(prof, 'GET', `/helpline?branch_id=${ce.id}&year_id=${fin.id}&q=data`);
  const dm = help.body.subjects?.find((s) => s.code === 'DM');
  check('helpline finds DM with assigned + backups + phone', dm && dm.assigned.length && dm.backups.length && dm.assigned[0].phone, help.body);

  // ---------------- step 3: free rooms + rescheduler
  const free = await call(stu, 'GET', '/rooms/free');
  check('free rooms', free.status === 200 && free.body.free.length > 0, free.body);
  const date = free.body.date;
  check('rooms are look-up only', (await call(stu, 'POST', '/rooms/bookings', { room_id: 1, date, period_start: 1, period_end: 1 })).status === 404);

  const classes = await call(prof, 'GET', '/reschedule/my-classes');
  const occ = classes.body.occurrences.find((o) => o.status === 'scheduled');
  check('prof has upcoming classes', !!occ, classes.body);
  const notMine = (await call(sts, 'POST', '/reschedule/suggest', { entry_id: occ.id, original_date: occ.date }));
  check('cannot reschedule someone else\'s class', notMine.status === 403);
  const sug = await call(prof, 'POST', '/reschedule/suggest', { entry_id: occ.id, original_date: occ.date });
  check('3 suggestions', sug.body.options?.length === 3, sug.body);
  const opt = sug.body.options[0];
  const before = (await pool.query(`SELECT COUNT(*) AS n FROM notifications WHERE type = 'class_change'`)).rows[0].n;
  const ap = await call(prof, 'POST', '/reschedule/apply', { entry_id: occ.id, original_date: occ.date, new_date: opt.date, period_start: opt.period_start, room_id: opt.room_id, reason: 'Department meeting' });
  check('apply move', ap.status === 201 && ap.body.change.notified > 0, ap.body);
  const after = (await pool.query(`SELECT COUNT(*) AS n FROM notifications WHERE type = 'class_change'`)).rows[0].n;
  check('section notified', after > before);
  check('cannot move twice', (await call(prof, 'POST', '/reschedule/apply', { entry_id: occ.id, original_date: occ.date, new_date: opt.date, period_start: opt.period_start, room_id: opt.room_id })).status === 409);
  const moved = (await call(prof, 'GET', '/reschedule/my-classes')).body.occurrences.find((o) => o.status === 'moved_in' && o.id === occ.id);
  check('moved class appears in new slot', moved && moved.date === opt.date && moved.period_start === opt.period_start);
  const sug2 = await call(prof, 'POST', '/reschedule/suggest', {
    entry_id: classes.body.occurrences.filter((o) => o.status === 'scheduled')[1].id,
    original_date: classes.body.occurrences.filter((o) => o.status === 'scheduled')[1].date,
  });
  check('new suggestions avoid the moved class slot', sug2.body.options.every((o) => !(o.date === opt.date && o.period_start <= moved.period_end && moved.period_start <= o.period_end)));
  check('undo move', (await call(prof, 'DELETE', `/reschedule/changes/${ap.body.change.id}`)).status === 200);

  // ---------------- step 4: helpdesk + escalation
  const cats = (await call(stu, 'GET', '/tickets/categories')).body.categories;
  const fd = new FormData();
  fd.append('category_id', String(cats.find((c) => c.code === 'hostel').id));
  fd.append('title', 'Broken window latch');
  fd.append('location', 'Girls Hostel, Room 12');
  fd.append('photo', new Blob([Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', 'base64')], { type: 'image/png' }), 'p.png');
  const tRes = await fetch(`${base}/tickets`, { method: 'POST', headers: { authorization: `Bearer ${stu}` }, body: fd });
  const created = await tRes.json();
  check('create ticket with photo', tRes.status === 201 && created.ticket.photo_url, created);
  const tid = created.ticket.id;
  check('estate cannot see hostel ticket', (await call(estate, 'POST', `/tickets/${tid}/status`, { status: 'in_progress' })).status === 403);
  check('warden updates', (await call(warden, 'POST', `/tickets/${tid}/status`, { status: 'in_progress', note: 'Carpenter tomorrow' })).status === 200);
  check('other student cannot read ticket', !stu2 || (await call(stu2, 'GET', `/tickets/${tid}`)).status === 403);
  const hodInboxBefore = (await call(hod, 'GET', '/tickets/inbox')).body.tickets;
  check('HOD cannot see level-1 hostel ticket', !hodInboxBefore.some((t) => t.id === tid));
  await pool.query(`UPDATE tickets SET due_at = now() - interval '1 minute' WHERE id = $1`, [tid]);
  await runEscalation();
  check('deadline passed -> HOD sees it', (await call(hod, 'GET', '/tickets/inbox')).body.tickets.some((t) => t.id === tid));
  check('manual escalate to dean', (await call(hod, 'POST', `/tickets/${tid}/escalate`, { note: 'Needs budget' })).body.ticket?.escalation_level === 3);
  const detail = await call(stu, 'GET', `/tickets/${tid}`);
  check('ticket timeline', detail.body.events.length >= 4, detail.body.events);

  // ---------------- step 5: boards, broadcast, meetings
  const boards = (await call(stu, 'GET', '/boards')).body.boards;
  const bon = boards.find((b) => b.code === 'bonafide');
  check('boards list', boards.length === 3 && boards.every((b) => ['bonafide', 'idcard', 'noc'].includes(b.code)), boards.map((b) => b.code));
  check('boards start empty', bon.helpers === 0);
  check('second student becomes helper', stu2 && (await call(stu2, 'POST', `/boards/${bon.id}/helper`)).status < 300);
  check('post question', (await call(stu, 'POST', `/boards/${bon.id}/posts`, { body: 'How long does it take?' })).status === 201);
  const ping = await call(stu, 'POST', `/boards/${bon.id}/need-help`, { message: 'Urgent for internship' });
  check('need help pings helpers', ping.body.pinged === 3, ping.body);
  check('ping rate limited', (await call(stu, 'POST', `/boards/${bon.id}/need-help`, {})).status === 429);
  const board = (await call(stu, 'GET', `/boards/${bon.id}`)).body;
  const conv = await call(stu, 'POST', '/chats', { user_id: board.helpers[0].id, form_type_id: bon.id });
  check('open chat', conv.status === 200, conv.body);
  check('send message', (await call(stu, 'POST', `/chats/${conv.body.conversation.id}/messages`, { body: 'Hi! Which window?' })).status === 201);
  check('outsider cannot read chat', !stu2 || board.helpers[0].id === me.body.user.id || (await call(sts, 'GET', `/chats/${conv.body.conversation.id}/messages`)).status === 403);
  check('prof cannot use boards', (await call(prof, 'GET', '/boards')).status === 403);

  const secA = struct.body.sections.find((s) => s.branch_code === 'CE' && s.year_code === 'Final' && s.name === 'A');
  const prev = await call(prof, 'POST', '/broadcasts/preview', { section_id: secA.id });
  check('broadcast preview', prev.body.recipients === 10, prev.body);
  const bc = await call(prof, 'POST', '/broadcasts', { year_id: fin.id, title: 'Project review', body: 'Reviews on Friday in AL 202' });
  check('broadcast to year', bc.status === 201 && bc.body.broadcast.recipients === 25, bc.body);
  check('student cannot broadcast', (await call(stu, 'POST', '/broadcasts', { title: 'x', body: 'yyyy', year_id: fin.id })).status === 403);
  const inbox = await call(stu, 'GET', '/notifications');
  check('student inbox has broadcast + class change', inbox.body.notifications.some((n) => n.title === 'Project review') && inbox.body.unread > 0);

  const groups = (await call(stu, 'GET', '/meetings/groups')).body.groups;
  check('student group', groups.length === 1 && groups[0].guide_name.includes('Vaishnav'));
  const slots = (await call(stu, 'GET', `/meetings/groups/${groups[0].id}/slots`)).body.slots;
  check('common free slots', slots.length > 0, slots);
  const req1 = await call(stu, 'POST', '/meetings', { group_id: groups[0].id, date: slots[0].date, period: slots[0].period, agenda: 'Demo dry run' });
  check('request meeting', req1.status === 201, req1.body);
  check('other prof cannot respond', (await call(sts, 'POST', `/meetings/${req1.body.meeting.id}/respond`, { action: 'accept' })).status === 403);
  const sugg = await call(prof, 'POST', `/meetings/${req1.body.meeting.id}/respond`, { action: 'suggest', date: slots[1].date, period: slots[1].period, note: 'Busy then' });
  check('prof suggests time', sugg.body.meeting?.status === 'suggested', sugg.body);
  const acc = await call(stu, 'POST', `/meetings/${req1.body.meeting.id}/suggestion`, { accept: true });
  check('student accepts suggestion', acc.body.meeting?.status === 'accepted' && acc.body.meeting.date === slots[1].date, acc.body);

  // ---------------- admin master data
  const rooms = await call(estate, 'GET', '/admin/rooms');
  check('admin lists rooms', rooms.body.rows.length === 15);
  const nr = await call(estate, 'POST', '/admin/rooms', { name: 'Seminar Hall', type: 'classroom', capacity: 120, building: 'Main', bookable: true });
  check('admin adds room', nr.status === 201, nr.body);
  check('admin edits room', (await call(estate, 'PUT', `/admin/rooms/${nr.body.row.id}`, { capacity: 110 })).body.row?.capacity === 110);
  const anyEntry = (await call(estate, 'GET', '/admin/timetable_entries')).body.rows.find((e) => e.room_name === 'AL 202');
  const clashEntry = await call(estate, 'POST', '/admin/timetable_entries', {
    section_id: struct.body.sections.find((s) => s.branch_code === 'IT').id, day: anyEntry.day,
    period_start: anyEntry.period_start, period_end: anyEntry.period_start, subject_id: anyEntry.subject_id,
    room_id: anyEntry.room_id, kind: 'theory',
  });
  check('timetable clash rejected', clashEntry.status === 409, clashEntry.body);
  check('admin deletes room', (await call(estate, 'DELETE', `/admin/rooms/${nr.body.row.id}`)).status === 200);
  const nu = await call(estate, 'POST', '/admin/users', { role: 'student', name: 'Test User', email: 'test.user@campus.test', password: 'secret1', section_id: secA.id, roll_no: '22CEA999' });
  check('admin creates student', nu.status === 201, nu.body);
  check('new student can log in', !!(await call(null, 'POST', '/auth/login', { email: 'test.user@campus.test', password: 'secret1' })).body?.token);
  check('admin deletes user', (await call(estate, 'DELETE', `/admin/users/${nu.body.row.id}`)).status === 200);
} catch (err) {
  failures.push(`crashed: ${err.stack}`);
} finally {
  server.close();
  await pool.end();
}

console.log(`\n${passed} passed, ${failures.length} failed`);
for (const f of failures) console.log('  FAIL', f);
process.exitCode = failures.length ? 1 : 0;
