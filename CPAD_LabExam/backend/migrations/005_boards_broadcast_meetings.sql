-- Step 5: paperwork help boards with 1:1 chat, broadcasts, and group project meetings.

CREATE TABLE form_types (
  id           SERIAL PRIMARY KEY,
  code         TEXT NOT NULL UNIQUE,
  name         TEXT NOT NULL,
  description  TEXT,
  office       TEXT
);

CREATE TABLE board_posts (
  id            SERIAL PRIMARY KEY,
  form_type_id  INT  NOT NULL REFERENCES form_types(id) ON DELETE CASCADE,
  author_id     INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_id     INT  REFERENCES board_posts(id) ON DELETE CASCADE,
  body          TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX board_posts_form_idx ON board_posts (form_type_id, created_at DESC);

-- Students who tapped "I've done this".
CREATE TABLE board_helpers (
  form_type_id  INT NOT NULL REFERENCES form_types(id) ON DELETE CASCADE,
  student_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (form_type_id, student_id)
);

CREATE TABLE help_pings (
  id            SERIAL PRIMARY KEY,
  form_type_id  INT  NOT NULL REFERENCES form_types(id) ON DELETE CASCADE,
  requester_id  INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message       TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1:1 chat between two students. user_a < user_b so a pair has one conversation.
CREATE TABLE conversations (
  id            SERIAL PRIMARY KEY,
  user_a        INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b        INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  form_type_id  INT REFERENCES form_types(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (user_a < user_b),
  UNIQUE (user_a, user_b)
);

CREATE TABLE messages (
  id               SERIAL PRIMARY KEY,
  conversation_id  INT  NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id        INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body             TEXT NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX messages_conv_idx ON messages (conversation_id, id);

CREATE TABLE broadcasts (
  id          SERIAL PRIMARY KEY,
  sender_id   INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  target      JSONB NOT NULL,
  recipients  INT  NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE project_groups (
  id            SERIAL PRIMARY KEY,
  name          TEXT NOT NULL,
  title         TEXT,
  guide_id      INT  NOT NULL REFERENCES professors(user_id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE project_group_members (
  group_id    INT NOT NULL REFERENCES project_groups(id) ON DELETE CASCADE,
  student_id  INT NOT NULL REFERENCES students(user_id) ON DELETE CASCADE,
  PRIMARY KEY (group_id, student_id)
);

CREATE TABLE meeting_requests (
  id                SERIAL PRIMARY KEY,
  group_id          INT  NOT NULL REFERENCES project_groups(id) ON DELETE CASCADE,
  requested_by      INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date              DATE NOT NULL,
  period            INT  NOT NULL REFERENCES periods(period),
  agenda            TEXT NOT NULL,
  status            TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'accepted', 'rejected', 'suggested', 'cancelled')),
  suggested_date    DATE,
  suggested_period  INT REFERENCES periods(period),
  professor_note    TEXT,
  responded_at      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX meeting_requests_group_idx ON meeting_requests (group_id, created_at DESC);
