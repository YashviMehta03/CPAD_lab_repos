-- Step 2: virtual queue for professors (availability lives on the professors table).

CREATE TABLE queue_tokens (
  id            SERIAL PRIMARY KEY,
  professor_id  INT  NOT NULL REFERENCES professors(user_id) ON DELETE CASCADE,
  student_id    INT  NOT NULL REFERENCES students(user_id) ON DELETE CASCADE,
  queue_date    DATE NOT NULL,
  token_no      INT  NOT NULL,
  purpose       TEXT,
  status        TEXT NOT NULL DEFAULT 'waiting'
                CHECK (status IN ('waiting', 'serving', 'done', 'skipped', 'left')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  called_at     TIMESTAMPTZ,
  finished_at   TIMESTAMPTZ,
  UNIQUE (professor_id, queue_date, token_no)
);

-- A student can hold at most one live token per professor per day.
CREATE UNIQUE INDEX queue_one_active_idx
  ON queue_tokens (professor_id, student_id, queue_date)
  WHERE status IN ('waiting', 'serving');
