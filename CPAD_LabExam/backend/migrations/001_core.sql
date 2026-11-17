-- Step 1: users, roles and the campus model (branches, years, sections, rooms, subjects, timetable).
-- Everything here is data: adding a branch, section or room needs no code change.

CREATE TABLE branches (
  id    SERIAL PRIMARY KEY,
  code  TEXT NOT NULL UNIQUE,
  name  TEXT NOT NULL
);

CREATE TABLE years (
  id    SERIAL PRIMARY KEY,
  code  TEXT NOT NULL UNIQUE,
  name  TEXT NOT NULL,
  ord   INT  NOT NULL DEFAULT 0
);

CREATE TABLE sections (
  id         SERIAL PRIMARY KEY,
  branch_id  INT  NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  year_id    INT  NOT NULL REFERENCES years(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  strength   INT  NOT NULL DEFAULT 60 CHECK (strength > 0),
  UNIQUE (branch_id, year_id, name)
);

CREATE TABLE rooms (
  id        SERIAL PRIMARY KEY,
  name      TEXT NOT NULL UNIQUE,
  type      TEXT NOT NULL CHECK (type IN ('classroom', 'lab')),
  capacity  INT  NOT NULL CHECK (capacity > 0),
  building  TEXT,
  bookable  BOOLEAN NOT NULL DEFAULT true
);

-- Teaching periods of the fixed weekly grid (the lunch break is simply the gap between two periods).
CREATE TABLE periods (
  period      INT  PRIMARY KEY,
  start_time  TIME NOT NULL,
  end_time    TIME NOT NULL
);

CREATE TABLE subjects (
  id         SERIAL PRIMARY KEY,
  code       TEXT NOT NULL UNIQUE,
  name       TEXT NOT NULL,
  branch_id  INT REFERENCES branches(id) ON DELETE SET NULL
);

CREATE TABLE users (
  id             SERIAL PRIMARY KEY,
  email          TEXT NOT NULL UNIQUE,
  password_hash  TEXT NOT NULL,
  name           TEXT NOT NULL,
  role           TEXT NOT NULL CHECK (role IN ('student', 'professor', 'admin')),
  phone          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE students (
  user_id     INT  PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  section_id  INT  NOT NULL REFERENCES sections(id),
  roll_no     TEXT NOT NULL UNIQUE
);

CREATE TABLE professors (
  user_id            INT  PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  code               TEXT NOT NULL UNIQUE,
  department_id      INT  REFERENCES branches(id) ON DELETE SET NULL,
  cabin              TEXT,
  manual_status      TEXT NOT NULL DEFAULT 'in_cabin'
                     CHECK (manual_status IN ('in_cabin', 'busy', 'away', 'on_leave')),
  status_note        TEXT,
  status_updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- level: 1 = category handler (warden, estate officer), 2 = HOD, 3 = dean.
CREATE TABLE admins (
  user_id  INT  PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  title    TEXT NOT NULL,
  level    INT  NOT NULL CHECK (level BETWEEN 1 AND 3)
);

-- Who teaches / knows which subject. is_backup = can stand in during exams (exam helpline).
CREATE TABLE professor_subjects (
  id            SERIAL PRIMARY KEY,
  professor_id  INT NOT NULL REFERENCES professors(user_id) ON DELETE CASCADE,
  subject_id    INT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  is_backup     BOOLEAN NOT NULL DEFAULT false,
  rank          INT NOT NULL DEFAULT 1,
  UNIQUE (professor_id, subject_id)
);

-- One row per weekly class. Entries with the same parallel_group run together (e.g. electives, batches).
CREATE TABLE timetable_entries (
  id              SERIAL PRIMARY KEY,
  section_id      INT  NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
  day             INT  NOT NULL CHECK (day BETWEEN 1 AND 5),
  period_start    INT  NOT NULL REFERENCES periods(period),
  period_end      INT  NOT NULL REFERENCES periods(period),
  subject_id      INT  NOT NULL REFERENCES subjects(id),
  professor_id    INT  REFERENCES professors(user_id) ON DELETE SET NULL,
  room_id         INT  REFERENCES rooms(id) ON DELETE SET NULL,
  kind            TEXT NOT NULL DEFAULT 'theory' CHECK (kind IN ('theory', 'lab', 'project')),
  label           TEXT,
  batch           TEXT,
  parallel_group  TEXT,
  CHECK (period_end >= period_start)
);
CREATE INDEX timetable_section_idx ON timetable_entries (section_id, day);
CREATE INDEX timetable_prof_idx ON timetable_entries (professor_id, day);

CREATE TABLE notifications (
  id          SERIAL PRIMARY KEY,
  user_id     INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT,
  data        JSONB NOT NULL DEFAULT '{}',
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX notifications_user_idx ON notifications (user_id, created_at DESC);
