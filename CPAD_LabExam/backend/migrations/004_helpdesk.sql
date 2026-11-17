-- Step 4: helpdesk tickets with per-category deadlines and escalation (handler -> HOD -> dean).

CREATE TABLE ticket_categories (
  id         SERIAL PRIMARY KEY,
  code       TEXT NOT NULL UNIQUE,
  name       TEXT NOT NULL,
  sla_hours  INT  NOT NULL CHECK (sla_hours > 0)
);

-- Level-1 admins handle the categories they are mapped to.
CREATE TABLE admin_categories (
  admin_id     INT NOT NULL REFERENCES admins(user_id) ON DELETE CASCADE,
  category_id  INT NOT NULL REFERENCES ticket_categories(id) ON DELETE CASCADE,
  PRIMARY KEY (admin_id, category_id)
);

CREATE TABLE tickets (
  id                SERIAL PRIMARY KEY,
  student_id        INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id       INT  NOT NULL REFERENCES ticket_categories(id),
  title             TEXT NOT NULL,
  description       TEXT,
  location          TEXT NOT NULL,
  photo_path        TEXT,
  status            TEXT NOT NULL DEFAULT 'open'
                    CHECK (status IN ('open', 'in_progress', 'resolved', 'rejected')),
  escalation_level  INT  NOT NULL DEFAULT 1 CHECK (escalation_level BETWEEN 1 AND 3),
  due_at            TIMESTAMPTZ NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX tickets_open_due_idx ON tickets (due_at) WHERE status IN ('open', 'in_progress');

CREATE TABLE ticket_events (
  id          SERIAL PRIMARY KEY,
  ticket_id   INT  NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  actor_id    INT  REFERENCES users(id) ON DELETE SET NULL,
  type        TEXT NOT NULL,  -- created | status | escalated | auto_escalated | note
  note        TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
