# CampusSphere

Solve the campus hassle, one tap away. 

CampusSphere is a live operating system for campus life. Most college apps digitise the classroom: notes, assignments and marks. CampusSphere digitises everything around it: the walk to a professor's cabin, the hunt for an empty room, the class that moved at the last minute, the certificate nobody explains, and the broken fan nobody fixes. Because one shared model of the timetable, rooms and people drives every feature, the app can answer questions no notice board or WhatsApp group can: is my professor actually free right now, which lab is empty until 4 pm, and when is the earliest time my whole project group and our guide are all available.

The idea grew out of my own four years at college. I have stood outside cabins not knowing whether the professor was even on campus, gone floor to floor looking for a quiet room before an exam, missed a rescheduled lecture because the message was buried in a group chat, and asked around for weeks to learn how to get a bonafide certificate. Watching my professors, I saw the other side too: crowds at their door between lectures, rescheduling a class by hand around everyone's timetable, and project groups chasing them over messages. I wanted to build something genuinely useful that fixes these everyday problems for both sides, so every feature in CampusSphere maps to a problem I faced or saw a professor face.

The app has a separate experience for each of its three roles: students, professors and administrators (hostel warden, estate officer, HOD and dean). All three share one Flutter app, one Node.js + Express backend and one PostgreSQL database hosted on Supabase.

CampusSphere is deliberately not a learning management system. It has no assignments, grades, notes or quizzes. It focuses only on logistics: people, rooms, time and paperwork.

The pilot is modelled on VJTI, with three branches (Computer Engineering, Information Technology, Electronics & Telecommunication), two years (Third Year and Final Year BTech) and seven sections. The Final Year CE section A uses the real departmental timetable. Everything about the campus (branches, years, sections, rooms, periods, subjects and the timetable) is stored as data, so more of the campus can be added without code changes.

```
CPAD_LabExam/
├── backend/   Express API, SQL migrations, seed script, API smoke test
├── app/       Flutter app (Android emulator target)
└── data/      Real CE Final BTech timetable used by the seeder
```

## Run it

### 1. Backend

```powershell
cd backend
copy .env.example .env      # then fill in DATABASE_URL, JWT_SECRET, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
npm install
npm run migrate             # creates the tables
npm run seed                # loads the campus (wipes and reseeds every time)
npm run dev                 # API on http://localhost:4000/api
npm test                    # 73 end-to-end checks (run `npm run seed` first; the test changes data)
```

- **Supabase setup:** `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are required (they power sign up / login). Create a storage bucket named `helpdesk` (private is fine; the API hands out signed URLs).
- **No email confirmation:** sign-up creates an already-confirmed Supabase account, so any address works (e.g. `me@campus.test`) and no emails are sent.
- **Demo clock:** set `DEMO_NOW=2026-11-17T10:45` in `.env` to freeze campus time. Use it if you demo in the evening, so professors show as "In class" and the free-room finder has slots left in the day.

### 2. App

```powershell
cd app
flutter pub get
flutter run                 # with the Android emulator running
```

The app talks to `http://10.0.2.2:4000/api`, which is your PC as seen from the emulator. For a real phone, tap the server icon on the login screen and enter `http://<your-PC-LAN-IP>:4000/api`.

## Accounts

There are no demo logins. Accounts live in Supabase Auth (*Authentication > Users* in the dashboard); the backend checks the password with Supabase and then issues its own app token.

- **Students and professors** tap *Create an account* on the login screen. Students pick branch, year, section and roll number; professors enter their faculty code, department and cabin.
- **Seeded professors** already have logins: email `<code>@gmail.com`, password `<code>123` in lowercase, e.g. `pv@gmail.com` / `pv123` (`npm run prof-logins` creates any that are missing; `npm run seed` runs it for you).
- **Admins** cannot sign up. Give a seeded admin (or any seeded person) a login with
  `npm run link-login -- estate@campus.test you@example.com YourPassword`
  (seeded admins: `estate@`, `warden@`, `hod@`, `dean@campus.test`; seeded professors: `<code>@campus.test`, e.g. `pv@`). That admin can then add users or set passwords from *Master data*, which creates their Supabase logins.
- `npm run seed` wipes the campus and also deletes the Supabase logins of the wiped users.

## Features by build step

1. **Auth and campus model.** Sign up / login through Supabase Auth, then an app JWT; `requireRole` middleware plus ownership checks on every route. Branches, years, sections, rooms, subjects, periods and the timetable are all database rows.
2. **Availability, queue, helpline.**
   - A professor's status is set to *In class* automatically from the timetable; one tap sets In cabin, Busy, Away or On leave.
   - Virtual queue with tokens: call next, complete, skip.
   - Exam helpline (professors only): shows the assigned teacher, ranked backups, live status and phone numbers.
3. **Free rooms and smart rescheduler.**
   - Free rooms now or at any slot, with conflict-checked group-study booking.
   - The rescheduler builds the busy set from the section timetable, the professor's own classes and room bookings. It finds slots in the next 7 days with a free room that is big enough and of the right type. It ranks them by nearest day, avoiding first/last periods and back-to-back classes, then notifies the section.
4. **Helpdesk.** Photo and location upload. Each category has a deadline; an overdue ticket is escalated automatically (handler → HOD → dean) by a job that runs every minute, and admins can also escalate manually.
5. **Paperwork boards, broadcasts, project meetings.**
   - Boards per form, with "I've done this" helpers, "Need help" pings and 1:1 chat.
   - Targeted broadcasts to a branch, year, section or picked students.
   - Project meeting requests at common free slots taken from the timetable. The professor can accept, reject or suggest another time.

All roles have a notification bell (polled every 30 s). Queue and availability refresh on pull or on a short poll; neither is real-time, by design.

## Seed data

- **CE Final-A** uses the real timetable from `data/`.
- **Six more sections** (CE Final-B, CE TY-A, IT TY/Final-A, EXTC TY/Final-A) get generated timetables. The generator is deterministic and never clashes with the real one on section, professor or room.
- **Generated demo values:** phone numbers, cabins, student names and backup-teacher tags.
- **Totals:** 20 professors, 40 students, 15 rooms, 4 admins.
