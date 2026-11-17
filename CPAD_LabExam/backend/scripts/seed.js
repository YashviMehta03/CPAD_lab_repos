// Seeds the pilot campus. CE Final-A comes from the real timetable in ../data; the other sections
// get generated timetables that never clash with it (section, professor or room).
// Re-running wipes and reseeds everything. Seeded people have no login: real accounts come from
// sign up in the app (Supabase Auth), an admin, or `npm run link-login`.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { assertConfig } from '../src/config.js';
import { pool } from '../src/db.js';
import { deleteAuthUser } from '../src/lib/supabase.js';
import { createProfessorLogins } from './prof-logins.js';
import { addDays, dowOf, nowIST } from '../src/lib/time.js';

assertConfig();
const here = path.dirname(fileURLToPath(import.meta.url));
const dataDir = path.join(here, '..', '..', 'data');
const ce = JSON.parse(fs.readFileSync(path.join(dataDir, 'timetable_ce_final_btech.json'), 'utf8'));

// Deterministic randomness so every reseed gives the same campus.
function mulberry32(a) {
  return () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rand = mulberry32(20261116);
const shuffle = (arr) => {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
};
const DAY_NUM = { Monday: 1, Tuesday: 2, Wednesday: 3, Thursday: 4, Friday: 5 };

// ------------------------------------------------------------------ master data

const BRANCHES = [
  { code: 'CE', name: 'Computer Engineering' },
  { code: 'IT', name: 'Information Technology' },
  { code: 'EXTC', name: 'Electronics & Telecommunication' },
];
const YEARS = [
  { code: 'TY', name: 'Third Year BTech', ord: 3 },
  { code: 'Final', name: 'Final Year BTech', ord: 4 },
];
const ROOMS = [
  // name, type, capacity, building
  ['AL 004', 'classroom', 72, 'Academic Block, Ground floor'],
  ['AL 101', 'classroom', 66, 'Academic Block, 1st floor'],
  ['AL 102', 'classroom', 66, 'Academic Block, 1st floor'],
  ['AL 201', 'classroom', 80, 'Academic Block, 2nd floor'],
  ['AL 202', 'classroom', 72, 'Academic Block, 2nd floor'],
  ['AL 207', 'classroom', 60, 'Academic Block, 2nd floor'],
  ['AL 301', 'classroom', 45, 'Academic Block, 3rd floor'],
  ['AL 302', 'classroom', 60, 'Academic Block, 3rd floor'],
  ['Lab 1A', 'lab', 70, 'CE & IT Labs, 1st floor'],
  ['Lab 1B', 'lab', 66, 'CE & IT Labs, 1st floor'],
  ['Lab 3B', 'lab', 60, 'CE & IT Labs, 3rd floor'],
  ['Internet Lab', 'lab', 66, 'CE & IT Labs, Ground floor'],
  ['ARVR Lab', 'lab', 30, 'CE & IT Labs, 2nd floor'],
  ['EXTC Lab', 'lab', 60, 'Electronics Block, 1st floor'],
  ['Embedded Lab', 'lab', 60, 'Electronics Block, 2nd floor'],
];
const SECTIONS = [
  { key: 'CE Final A', branch: 'CE', year: 'Final', name: 'A', strength: 66, home: 'AL 202', labs: ['Lab 1A', 'Lab 1B'] },
  { key: 'CE Final B', branch: 'CE', year: 'Final', name: 'B', strength: 62, home: 'AL 101', labs: ['Lab 1B', 'Lab 1A', 'Internet Lab'] },
  { key: 'CE TY A', branch: 'CE', year: 'TY', name: 'A', strength: 64, home: 'AL 102', labs: ['Lab 1A', 'Lab 1B', 'Internet Lab'] },
  { key: 'IT TY A', branch: 'IT', year: 'TY', name: 'A', strength: 60, home: 'AL 201', labs: ['Internet Lab', 'Lab 3B', 'Lab 1B'] },
  { key: 'IT Final A', branch: 'IT', year: 'Final', name: 'A', strength: 60, home: 'AL 207', labs: ['Lab 3B', 'Internet Lab'] },
  { key: 'EXTC TY A', branch: 'EXTC', year: 'TY', name: 'A', strength: 58, home: 'AL 302', labs: ['EXTC Lab', 'Embedded Lab'] },
  { key: 'EXTC Final A', branch: 'EXTC', year: 'Final', name: 'A', strength: 58, home: 'AL 004', labs: ['Embedded Lab', 'EXTC Lab'] },
];

// Subjects beyond the real CE file. [code, name, branch, short label]
const EXTRA_SUBJECTS = [
  ['HONORS', 'Honors / Minor Degree', 'CE', null],
  ['OS', 'Operating Systems', 'CE', 'OS'], ['OS_LAB', 'Operating Systems Lab', 'CE', 'OS Lab'],
  ['CN', 'Computer Networks', 'CE', 'CN'], ['CN_LAB', 'Computer Networks Lab', 'CE', 'CN Lab'],
  ['TOC', 'Theory of Computation', 'CE', 'TOC'], ['SE', 'Software Engineering', 'CE', 'SE'],
  ['WT', 'Web Technologies', 'IT', 'WT'], ['WT_LAB', 'Web Technologies Lab', 'IT', 'WT Lab'],
  ['DAA', 'Design & Analysis of Algorithms', 'IT', 'DAA'],
  ['DBMS', 'Database Management Systems', 'IT', 'DBMS'], ['DBMS_LAB', 'DBMS Lab', 'IT', 'DBMS Lab'],
  ['CC', 'Cloud Computing', 'IT', 'CC'], ['CC_LAB', 'Cloud Computing Lab', 'IT', 'CC Lab'],
  ['BDA', 'Big Data Analytics', 'IT', 'BDA'], ['IS', 'Information Security', 'IT', 'IS'],
  ['DSP', 'Digital Signal Processing', 'EXTC', 'DSP'], ['DSP_LAB', 'DSP Lab', 'EXTC', 'DSP Lab'],
  ['CSYS', 'Control Systems', 'EXTC', 'Control Sys'], ['AC', 'Analog Circuits', 'EXTC', 'Analog Ckts'],
  ['AC_LAB', 'Analog Circuits Lab', 'EXTC', 'Analog Lab'], ['EMW', 'Electromagnetic Waves', 'EXTC', 'EM Waves'],
  ['VLSI', 'VLSI Design', 'EXTC', 'VLSI'], ['VLSI_LAB', 'VLSI Lab', 'EXTC', 'VLSI Lab'],
  ['WC', 'Wireless Communication', 'EXTC', 'Wireless Comm'], ['ES', 'Embedded Systems', 'EXTC', 'Embedded'],
  ['ES_LAB', 'Embedded Systems Lab', 'EXTC', 'Embedded Lab'], ['MWE', 'Microwave Engineering', 'EXTC', 'Microwave'],
];
const LABELS = { DM: 'DM', PEIII: 'PE III', PEIV: 'PE IV', MDMV: 'MDM V', CPAD_LAB: 'CPAD Lab' };

// Generated sections: [subject, professor code, lectures per week | lab block length, kind]
const GEN_PLAN = {
  'CE Final B': [['DM', 'RP', 3], ['PEIII', 'SB', 2], ['PEIV', 'HCD', 3], ['MDMV', 'AN', 2], ['CPAD_LAB', 'MS', 2, 'lab']],
  'CE TY A': [['OS', 'PMC', 3], ['CN', 'DSS', 3], ['TOC', 'MRS', 3], ['SE', 'RP', 3], ['OS_LAB', 'PMC', 2, 'lab'], ['CN_LAB', 'DSS', 2, 'lab']],
  'IT TY A': [['CN', 'VBN', 3], ['WT', 'MMC', 3], ['DAA', 'SCS', 3], ['DBMS', 'VKS', 3], ['WT_LAB', 'MMC', 2, 'lab'], ['DBMS_LAB', 'VKS', 2, 'lab']],
  'IT Final A': [['CC', 'VBN', 3], ['BDA', 'SCS', 3], ['IS', 'MMC', 3], ['DM', 'VKS', 3], ['CC_LAB', 'VBN', 2, 'lab']],
  'EXTC TY A': [['DSP', 'SGK', 3], ['CSYS', 'NAS', 3], ['AC', 'SN', 3], ['EMW', 'RS', 3], ['DSP_LAB', 'SGK', 2, 'lab'], ['AC_LAB', 'SN', 2, 'lab']],
  'EXTC Final A': [['VLSI', 'NAS', 3], ['WC', 'RS', 3], ['ES', 'SGK', 3], ['MWE', 'SN', 3], ['VLSI_LAB', 'NAS', 2, 'lab'], ['ES_LAB', 'SGK', 2, 'lab']],
};

// Professors seeded: everyone the real timetable uses, plus staff for the generated sections.
const PROF_DEPT = {
  PV: 'CE', VJN: 'CE', SB: 'CE', HCD: 'CE', STS: 'CE', MS: 'CE', AN: 'CE', RP: 'CE', MRS: 'CE', SJ: 'CE',
  PMC: 'CE', DSS: 'CE', VBN: 'IT', MMC: 'IT', SCS: 'IT', VKS: 'IT', SGK: 'EXTC', NAS: 'EXTC', SN: 'EXTC', RS: 'EXTC',
};
const PROF_STATUS = {
  SB: ['busy', 'Paper setting till 4 pm'], MMC: ['away', 'At the central library'],
  RS: ['on_leave', 'At a conference, back Thursday'], DSS: ['busy', null],
};

const FIRST = ['Aarav', 'Ananya', 'Rohan', 'Isha', 'Kabir', 'Meera', 'Arjun', 'Diya', 'Vihaan', 'Sneha',
  'Aditya', 'Riya', 'Siddharth', 'Pooja', 'Nikhil', 'Tanvi', 'Omkar', 'Shruti', 'Pranav', 'Neha',
  'Harsh', 'Kavya', 'Yash', 'Sakshi', 'Varun', 'Aditi', 'Rahul', 'Prachi', 'Tejas', 'Mansi',
  'Kunal', 'Nidhi', 'Atharva', 'Gauri', 'Sahil', 'Ritika', 'Parth', 'Anjali', 'Dhruv', 'Swara'];
const LAST = ['Shah', 'Kulkarni', 'Patil', 'Deshmukh', 'Iyer', 'Joshi', 'Naik', 'Pawar', 'Mehta', 'Gokhale',
  'Rao', 'Bhosale', 'Shetty', 'Chavan', 'Kamat', 'Desai', 'Jadhav', 'Menon', 'Sawant', 'Pillai'];
const STUDENTS_PER_SECTION = { 'CE Final A': 10, 'CE Final B': 5, 'CE TY A': 5, 'IT TY A': 5, 'IT Final A': 5, 'EXTC TY A': 5, 'EXTC Final A': 5 };

const CATEGORIES = [
  ['hostel', 'Hostel', 24], ['wifi', 'Wi-Fi & Network', 12], ['maintenance', 'Maintenance (fan, furniture, plumbing)', 48],
  ['electrical', 'Electrical', 24], ['classroom', 'Classroom & Lab Equipment', 48],
];
const ADMINS = [
  ['warden@campus.test', 'Mr. R. K. Pawar', 'Hostel Warden', 1, ['hostel']],
  ['estate@campus.test', 'Mr. S. D. Gaikwad', 'Estate Officer', 1, ['wifi', 'maintenance', 'electrical', 'classroom']],
  ['hod@campus.test', 'Dr. A. B. Kale', 'HOD, Computer & IT', 2, []],
  ['dean@campus.test', 'Dr. M. N. Rane', 'Dean, Student Affairs', 3, []],
];
const FORMS = [
  ['bonafide', 'Bonafide Certificate', 'For internships, passports, bank accounts and visas.', 'Academic Section, Main Building, Window 3'],
  ['idcard', 'Duplicate ID Card', 'Lost or damaged college ID card replacement.', 'Student Section, Main Building'],
  ['noc', 'No Objection Certificate (NOC)', 'For internships, competitions, or applying to another institute or company.', 'Department office, then Academic Section'],
];

// ------------------------------------------------------------------ timetable generation

function generateTimetables(periods, realEntries) {
  const periodNums = periods.map((p) => p.period);
  const busy = { section: new Set(), prof: new Set(), room: new Set() };
  const mark = (kind, id, day, ps, pe) => { for (let p = ps; p <= pe; p++) busy[kind].add(`${id}|${day}|${p}`); };
  const free = (kind, id, day, ps, pe) => { for (let p = ps; p <= pe; p++) if (busy[kind].has(`${id}|${day}|${p}`)) return false; return true; };

  for (const e of realEntries) {
    mark('section', 'CE Final A', e.day, e.period_start, e.period_end);
    if (e.prof) mark('prof', e.prof, e.day, e.period_start, e.period_end);
    if (e.room) mark('room', e.room, e.day, e.period_start, e.period_end);
  }
  const roomCap = Object.fromEntries(ROOMS.map((r) => [r[0], r[2]]));
  const classrooms = ROOMS.filter((r) => r[1] === 'classroom').map((r) => r[0]);
  const perDay = {};
  const generated = [];
  const warnings = [];

  for (const [key, plan] of Object.entries(GEN_PLAN)) {
    const sec = SECTIONS.find((s) => s.key === key);
    const load = (d) => perDay[`${key}|${d}`] || 0;
    for (const [subject, prof, n, kind = 'theory'] of plan) {
      const len = kind === 'lab' ? n : 1;
      const times = kind === 'lab' ? 1 : n;
      const roomOptions = kind === 'lab'
        ? sec.labs
        : [sec.home, ...shuffle(classrooms.filter((r) => r !== sec.home))].filter((r) => roomCap[r] >= sec.strength);
      const starts = kind === 'lab' ? [2, 4, 6, 7, 3] : [2, 3, 4, 5, 6, 7, 1, 8];
      let placed = 0;
      // Least-loaded days first, spreading lectures of one subject over different days.
      const days = shuffle([1, 2, 3, 4, 5]).sort((a, b) => load(a) - load(b));
      for (const day of days) {
        if (placed >= times) break;
        if (load(day) + len > 6) continue;
        let done = false;
        for (const ps of starts) {
          const pe = ps + len - 1;
          if (!periodNums.includes(pe) || (ps <= 5 && pe >= 6)) continue;  // no block across lunch
          if (!free('section', key, day, ps, pe) || !free('prof', prof, day, ps, pe)) continue;
          const room = roomOptions.find((r) => free('room', r, day, ps, pe));
          if (!room) continue;
          mark('section', key, day, ps, pe); mark('prof', prof, day, ps, pe); mark('room', room, day, ps, pe);
          perDay[`${key}|${day}`] = load(day) + len;
          generated.push({ section: key, day, period_start: ps, period_end: pe, subject, prof, room, kind });
          placed++; done = true;
          break;
        }
        if (!done) continue;
      }
      if (placed < times) warnings.push(`${key}: placed ${placed}/${times} of ${subject}`);
    }
  }
  return { generated, warnings };
}

// ------------------------------------------------------------------ main

const client = await pool.connect();
try {
  await client.query('BEGIN');
  const { rows: tables } = await client.query(
    `SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename <> 'schema_migrations'`);
  if (!tables.length) throw new Error('No tables found. Run `npm run migrate` first.');
  // Logins of the users about to be wiped are removed from Supabase Auth after the commit.
  const { rows: oldLogins } = await client.query('SELECT auth_id FROM users WHERE auth_id IS NOT NULL');
  await client.query(`TRUNCATE ${tables.map((t) => `"${t.tablename}"`).join(', ')} RESTART IDENTITY CASCADE`);

  const ins = async (sql, params) => (await client.query(sql, params)).rows[0];
  const id = { branch: {}, year: {}, room: {}, section: {}, subject: {}, prof: {}, cat: {}, form: {} };

  for (const b of BRANCHES) id.branch[b.code] = (await ins('INSERT INTO branches (code, name) VALUES ($1,$2) RETURNING id', [b.code, b.name])).id;
  for (const y of YEARS) id.year[y.code] = (await ins('INSERT INTO years (code, name, ord) VALUES ($1,$2,$3) RETURNING id', [y.code, y.name, y.ord])).id;
  for (const [name, type, cap, bld] of ROOMS) {
    id.room[name] = (await ins('INSERT INTO rooms (name, type, capacity, building) VALUES ($1,$2,$3,$4) RETURNING id', [name, type, cap, bld])).id;
  }
  const periods = ce.periods.filter((p) => p.period !== 'BREAK');
  for (const p of periods) await client.query('INSERT INTO periods VALUES ($1,$2,$3)', [p.period, p.start, p.end]);
  for (const s of SECTIONS) {
    id.section[s.key] = (await ins('INSERT INTO sections (branch_id, year_id, name, strength) VALUES ($1,$2,$3,$4) RETURNING id',
      [id.branch[s.branch], id.year[s.year], s.name, s.strength])).id;
  }
  for (const c of ce.courses) id.subject[c.code] = (await ins('INSERT INTO subjects (code, name, branch_id) VALUES ($1,$2,$3) RETURNING id', [c.code, c.name, id.branch.CE])).id;
  for (const [code, name, br, label] of EXTRA_SUBJECTS) {
    id.subject[code] = (await ins('INSERT INTO subjects (code, name, branch_id) VALUES ($1,$2,$3) RETURNING id', [code, name, id.branch[br]])).id;
    if (label) LABELS[code] = label;
  }

  // Professors (real names from the timetable file; phone numbers and cabins are demo values).
  const facultyName = Object.fromEntries(ce.faculty.map((f) => [f.code, f.name]));
  const cabinNo = { CE: 101, IT: 201, EXTC: 301 };
  let pi = 0;
  for (const [code, dept] of Object.entries(PROF_DEPT)) {
    if (!facultyName[code]) throw new Error(`Faculty ${code} missing from data file`);
    const u = await ins(`INSERT INTO users (email, name, role, phone) VALUES ($1,$2,'professor',$3) RETURNING id`,
      [`${code.toLowerCase()}@campus.test`, facultyName[code], `+91 98000 ${String(10001 + pi++).slice(-5)}`]);
    const [st, note] = PROF_STATUS[code] || ['in_cabin', null];
    await client.query('INSERT INTO professors (user_id, code, department_id, cabin, manual_status, status_note) VALUES ($1,$2,$3,$4,$5,$6)',
      [u.id, code, id.branch[dept], `${dept} Dept, Cabin ${cabinNo[dept]++}`, st, note]);
    id.prof[code] = u.id;
  }

  // Real CE Final-A timetable.
  const real = ce.entries.map((e) => {
    const prof = e.faculty?.[0] ?? null;
    if (prof && !id.prof[prof]) throw new Error(`Timetable uses unknown faculty ${prof}`);
    if (e.room && !id.room[e.room]) throw new Error(`Timetable uses unknown room ${e.room}`);
    return { ...e, day: DAY_NUM[e.day], prof, room: e.room };
  });
  for (const e of real) {
    await client.query(
      `INSERT INTO timetable_entries (section_id, day, period_start, period_end, subject_id, professor_id, room_id, kind, label, batch, parallel_group)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`,
      [id.section['CE Final A'], e.day, e.period_start, e.period_end, id.subject[e.course], e.prof ? id.prof[e.prof] : null,
        e.room ? id.room[e.room] : null, e.kind, e.label, e.batch ?? null, e.parallel_group ?? null]);
  }
  const { generated, warnings } = generateTimetables(periods, real);
  for (const g of generated) {
    await client.query(
      `INSERT INTO timetable_entries (section_id, day, period_start, period_end, subject_id, professor_id, room_id, kind, label)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
      [id.section[g.section], g.day, g.period_start, g.period_end, id.subject[g.subject], id.prof[g.prof], id.room[g.room], g.kind, LABELS[g.subject] ?? g.subject]);
  }

  // Who knows what: assigned teachers from the timetable, plus two backup tags per subject from the same department.
  await client.query(`INSERT INTO professor_subjects (professor_id, subject_id, is_backup, rank)
                      SELECT DISTINCT professor_id, subject_id, false, 1 FROM timetable_entries WHERE professor_id IS NOT NULL`);
  const { rows: taught } = await client.query(`SELECT DISTINCT e.subject_id, s.code, s.branch_id FROM timetable_entries e
                                                JOIN subjects s ON s.id = e.subject_id WHERE s.code <> 'PROJECT'`);
  for (const t of taught) {
    const dept = Object.entries(id.branch).find(([, v]) => v === t.branch_id)?.[0] ?? 'CE';
    const { rows: has } = await client.query('SELECT professor_id FROM professor_subjects WHERE subject_id = $1', [t.subject_id]);
    const pool2 = shuffle(Object.keys(PROF_DEPT).filter((c) => PROF_DEPT[c] === dept && !has.some((h) => h.professor_id === id.prof[c])));
    for (const [rank, code] of pool2.slice(0, 2).entries()) {
      await client.query('INSERT INTO professor_subjects (professor_id, subject_id, is_backup, rank) VALUES ($1,$2,true,$3)',
        [id.prof[code], t.subject_id, rank + 1]);
    }
  }

  // Students. The first CE Final-A student (student@campus.test) owns the demo activity below.
  const students = {};
  let n = 0;
  for (const s of SECTIONS) {
    students[s.key] = [];
    for (let i = 0; i < STUDENTS_PER_SECTION[s.key]; i++, n++) {
      const name = `${FIRST[n % FIRST.length]} ${LAST[(n * 7) % LAST.length]}`;
      const email = n === 0 ? 'student@campus.test' : `${name.toLowerCase().replace(' ', '.')}@campus.test`;
      const roll = `${s.year === 'Final' ? '22' : '23'}${s.branch}${s.name}${String(i + 1).padStart(3, '0')}`;
      const u = await ins(`INSERT INTO users (email, name, role, phone) VALUES ($1,$2,'student',$3) RETURNING id`,
        [email, name, `+91 98100 ${String(20001 + n).slice(-5)}`]);
      await client.query('INSERT INTO students (user_id, section_id, roll_no) VALUES ($1,$2,$3)', [u.id, id.section[s.key], roll]);
      students[s.key].push({ id: u.id, name, email });
    }
  }

  // Admins and helpdesk categories.
  for (const [code, name, sla] of CATEGORIES) id.cat[code] = (await ins('INSERT INTO ticket_categories (code, name, sla_hours) VALUES ($1,$2,$3) RETURNING id', [code, name, sla])).id;
  const admins = {};
  for (const [email, name, title, level, cats] of ADMINS) {
    const u = await ins(`INSERT INTO users (email, name, role, phone) VALUES ($1,$2,'admin',$3) RETURNING id`,
      [email, name, '+91 98200 00000']);
    await client.query('INSERT INTO admins (user_id, title, level) VALUES ($1,$2,$3)', [u.id, title, level]);
    for (const c of cats) await client.query('INSERT INTO admin_categories VALUES ($1,$2)', [u.id, id.cat[c]]);
    admins[email.split('@')[0]] = u.id;
  }

  // ---------------------------------------------------------------- demo activity
  const demo = students['CE Final A'][0];
  const ceA = students['CE Final A'];
  // The admin inbox starts empty: tickets come from students reporting real issues.

  for (const [code, name, desc, office] of FORMS) {
    id.form[code] = (await ins('INSERT INTO form_types (code, name, description, office) VALUES ($1,$2,$3,$4) RETURNING id', [code, name, desc, office])).id;
  }
  // Paperwork boards start empty: students fill them in themselves.

  // Project groups. Prof. Pragati Vaishnav (pv@campus.test) guides two of them.
  const group = async (name, title, guide, members) => {
    const g = await ins('INSERT INTO project_groups (name, title, guide_id) VALUES ($1,$2,$3) RETURNING id', [name, title, id.prof[guide]]);
    for (const m of members) await client.query('INSERT INTO project_group_members VALUES ($1,$2)', [g.id, m.id]);
    return g.id;
  };
  const g1 = await group('Team Nimbus', 'CampusSphere: campus logistics app', 'PV', [demo, ceA[1], ceA[2]]);
  await group('Team Quanta', 'Quantum circuit simulator', 'STS', [ceA[3], ceA[4], ceA[5]]);
  const g3 = await group('Team Orbit', 'Satellite image change detection', 'PV', students['CE Final B'].slice(0, 3));
  await group('Team Stratus', 'Serverless cost optimiser', 'VBN', students['IT Final A'].slice(0, 3));
  const today = nowIST().date;
  let nextWeekday = addDays(today, 1);
  while (dowOf(nextWeekday) > 5) nextWeekday = addDays(nextWeekday, 1);
  let lastWeekday = addDays(today, -1);
  while (dowOf(lastWeekday) > 5) lastWeekday = addDays(lastWeekday, -1);
  await client.query(`INSERT INTO meeting_requests (group_id, requested_by, date, period, agenda, status, responded_at)
                      VALUES ($1,$2,$3,6,'Review of API design and database schema','accepted', now() - interval '3 days')`, [g1, demo.id, lastWeekday]);
  await client.query(`INSERT INTO meeting_requests (group_id, requested_by, date, period, agenda)
                      VALUES ($1,$2,$3,4,'Mid-semester progress review: dataset and first results')`, [g3, students['CE Final B'][0].id, nextWeekday]);

  // A broadcast to CE Final-A so the student inbox is not empty.
  const bc = await ins(`INSERT INTO broadcasts (sender_id, title, body, target, recipients, created_at)
                        VALUES ($1,$2,$3,$4,$5, now() - interval '2 hours') RETURNING id`,
  [id.prof.PV, 'CPAD lab exam: bring your project running', 'Have the backend deployed and the app running on an emulator before you come in. Viva starts right after.',
    JSON.stringify({ section_id: id.section['CE Final A'], label: 'Section CE Final-A' }), ceA.length]);
  for (const s of ceA) {
    await client.query(`INSERT INTO notifications (user_id, type, title, body, data, created_at) VALUES ($1,'broadcast',$2,$3,$4, now() - interval '2 hours')`,
      [s.id, 'CPAD lab exam: bring your project running', 'Have the backend deployed and the app running on an emulator before you come in. Viva starts right after.',
        JSON.stringify({ broadcast_id: bc.id, from: facultyName.PV, to: 'Section CE Final-A' })]);
  }

  await client.query('COMMIT');
  for (const l of oldLogins) await deleteAuthUser(l.auth_id);
  await createProfessorLogins();
  if (oldLogins.length) console.log(`Removed ${oldLogins.length} Supabase Auth login(s) of wiped users.`);

  const count = async (t) => (await pool.query(`SELECT COUNT(*) AS n FROM ${t}`)).rows[0].n;
  console.log('Seeded:', {
    branches: await count('branches'), sections: await count('sections'), rooms: await count('rooms'),
    professors: await count('professors'), students: await count('students'), admins: await count('admins'),
    timetable_entries: await count('timetable_entries'), subjects: await count('subjects'),
  });
  if (warnings.length) console.warn('Timetable generator warnings:\n  ' + warnings.join('\n  '));
  console.log(`
No one has a login yet. Sign up in the app (student / professor), or give a seeded person a login:
  npm run link-login -- estate@campus.test you@example.com YourPassword   (Estate Officer, admin)
  npm run link-login -- pv@campus.test you@example.com YourPassword       (${facultyName.PV}, professor)`);
} catch (err) {
  await client.query('ROLLBACK');
  console.error('Seed failed:', err.message);
  process.exitCode = 1;
} finally {
  client.release();
  await pool.end();
}
