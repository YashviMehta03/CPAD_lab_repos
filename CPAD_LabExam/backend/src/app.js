import cors from 'cors';
import express from 'express';
import { errorHandler, notFound } from './lib/http.js';
import { storageMode, uploadsDir } from './lib/storage.js';
import { authenticate, requireRole } from './middleware/auth.js';
import { router as admin } from './routes/admin.js';
import { router as auth } from './routes/auth.js';
import { router as boards, chatRouter as chats } from './routes/boards.js';
import { router as broadcasts } from './routes/broadcasts.js';
import { router as helpline } from './routes/helpline.js';
import { router as meetings } from './routes/meetings.js';
import { router as meta } from './routes/meta.js';
import { router as notifications } from './routes/notifications.js';
import { router as professors } from './routes/professors.js';
import { router as queue } from './routes/queue.js';
import { router as reschedule } from './routes/reschedule.js';
import { router as rooms } from './routes/rooms.js';
import { router as tickets } from './routes/tickets.js';
import { router as timetable } from './routes/timetable.js';

export function createApp() {
  const app = express();
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));

  app.get('/api/health', (_req, res) => res.json({ ok: true, storage: storageMode }));
  if (storageMode === 'local') app.use('/uploads', express.static(uploadsDir));

  // Public
  app.use('/api/auth', auth);

  // Everything below needs a valid login. Role checks sit on each router or route.
  app.use('/api', authenticate);
  app.use('/api/meta', meta);
  app.use('/api/timetable', timetable);
  app.use('/api/notifications', notifications);
  app.use('/api/professors', professors);
  app.use('/api/queue', queue);
  app.use('/api/helpline', requireRole('professor'), helpline);
  app.use('/api/rooms', rooms);
  app.use('/api/reschedule', requireRole('professor'), reschedule);
  app.use('/api/tickets', tickets);
  app.use('/api/boards', requireRole('student'), boards);
  app.use('/api/chats', requireRole('student'), chats);
  app.use('/api/broadcasts', broadcasts);
  app.use('/api/meetings', meetings);
  app.use('/api/admin', requireRole('admin'), admin);

  app.use((_req, _res) => { throw notFound('No such endpoint'); });
  app.use(errorHandler);
  return app;
}
