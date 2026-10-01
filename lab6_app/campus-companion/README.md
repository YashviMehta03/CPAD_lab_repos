# Campus Companion (React Native) 🎓

**Campus Companion** is a student-focused mobile dashboard designed for **Final Year B.Tech Computer Engineering (LY CE) students at VJTI, Mumbai**. 

This is the React Native (Expo) implementation of the same application built in Lab 2.

## 📌 Features

### 1. 📅 Timetable (`TimetableScreen`)
* Populated with the official **AY 2026–27 ODD Semester Timetable** for Final BTech (CE), VJTI.
* Includes interactive **Mon–Fri day selector**.
* Detailed class cards displaying time slot, subject name, faculty, and room/lab numbers.

### 2. 👨‍🏫 Professor Directory (`ProfessorsScreen`)
* Complete directory of CE department faculty.
* Detailed view with room location and email address.

### 3. 🎉 Upcoming Events (`EventsScreen`)
* Showcases upcoming campus events.
* Category badges, dates, and locations.

### 4. 🚀 Dashboard (`HomeScreen`)
* Daily greeting header with current date.
* "Today's Classes" quick view widget with quick navigation to full schedule.
* Upcoming Event widget.
* "Coming Soon" badges for additional features.

## 🚀 How to Run

1. **Prerequisites:** Node.js, Expo CLI, and Android Studio/Emulator.
2. **Install Dependencies:**
   ```bash
   npm install
   ```
3. **Run Application:**
   ```bash
   npx expo start --android
   ```
