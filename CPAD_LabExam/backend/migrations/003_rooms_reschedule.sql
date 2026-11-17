-- Step 3: student room bookings and one-off class changes (cancel / move) made by the rescheduler.

CREATE TABLE room_bookings (
  id            SERIAL PRIMARY KEY,
  room_id       INT  NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  date          DATE NOT NULL,
  period_start  INT  NOT NULL REFERENCES periods(period),
  period_end    INT  NOT NULL REFERENCES periods(period),
  booked_by     INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  purpose       TEXT,
  status        TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (period_end >= period_start)
);
CREATE INDEX room_bookings_date_idx ON room_bookings (date, room_id) WHERE status = 'active';

-- Overrides the weekly timetable for one date. 'moved' puts the class at new_date / new periods / new room.
CREATE TABLE class_changes (
  id                SERIAL PRIMARY KEY,
  entry_id          INT  NOT NULL REFERENCES timetable_entries(id) ON DELETE CASCADE,
  original_date     DATE NOT NULL,
  action            TEXT NOT NULL CHECK (action IN ('cancelled', 'moved')),
  new_date          DATE,
  new_period_start  INT REFERENCES periods(period),
  new_period_end    INT REFERENCES periods(period),
  new_room_id       INT REFERENCES rooms(id) ON DELETE SET NULL,
  reason            TEXT,
  created_by        INT REFERENCES users(id) ON DELETE SET NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (entry_id, original_date),
  CHECK (action = 'cancelled' OR (new_date IS NOT NULL AND new_period_start IS NOT NULL AND new_period_end IS NOT NULL))
);
CREATE INDEX class_changes_new_date_idx ON class_changes (new_date);
