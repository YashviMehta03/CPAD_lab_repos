# Campus Companion 🎓

**Campus Companion** is a student-focused mobile dashboard designed for **Final Year B.Tech Computer Engineering (LY CE) students at VJTI, Mumbai**. 

The app acts as a central hub where students can seamlessly access their daily class timetable, faculty directory, campus events, and upcoming feature updates.

---

## 📌 Features

### 1. 📅 Timetable (`TimetableScreen`)
* Populated with the official **AY 2026–27 ODD Semester Timetable** for Final BTech (CE), VJTI.
* Includes interactive **Mon–Fri day selector** (auto-detects current weekday).
* Detailed class cards displaying time slot, subject name, faculty, and room/lab numbers (e.g., AL 202, Lab 1A, AL 004).

### 2. 👨‍🏫 Professor Directory (`ProfessorsScreen` & `ProfessorDetailScreen`)
* Complete directory of CE department faculty (e.g., Prof. Riddhi Patil, Prof. Harshala C Dalal, Dr. Varshapriya J N, Dr. M. R. Shirole, etc.).
* Detailed view with room location, office hours, email address, and subjects taught.

### 3. 🎉 Upcoming Events (`EventsScreen` & `EventDetailScreen`)
* Showcases upcoming campus events (Tech Symposium, Cultural Fest, Hackathons, Placement Drives, etc.).
* Category badges, dates, locations, event descriptions, and an interactive event registration button.

### 4. 🚀 Dashboard & Coming Soon Features (`HomeScreen`)
* Daily greeting header with current date.
* "Today's Classes" quick view widget with quick navigation to full schedule.
* 2-column feature grid with **"Coming Soon"** badges for Academic Calendar, Lost & Found, and Campus Announcements.

---

## 🧩 Usage of Row, Column, and Stack Widgets

This application was structured to showcase effective and natural layout design using Flutter's core layout primitives: **`Row`**, **`Column`**, and **`Stack`**.

### 1. `Column` (Vertical Alignment)
`Column` is used to structure overall screen layouts, forms, list items, and stacked text blocks.

* **Screen Layouts:**
  * [`HomeScreen`](lib/screens/home_screen.dart): Vertically stacks the header greeting, Today's Classes card, section title, and feature grid.
  * [`TimetableScreen`](lib/screens/timetable_screen.dart): Vertically arranges the department banner, day selector, and class list.
  * [`ProfessorDetailScreen`](lib/screens/professor_detail_screen.dart): Stacks the profile card, contact section, and subject list vertically.
* **Card & Text Hierarchies:**
  * [`FeatureCard`](lib/widgets/feature_card.dart): Arranges icon, title, and description vertically.
  * [`ClassCard`](lib/widgets/class_card.dart): Arranges subject title and professor info in a vertical block.

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(_greeting(), style: AppTheme.labelStyle),
    Text('Campus Companion', style: AppTheme.displayStyle),
    Row(...), // Date row
  ],
)
```

---

### 2. `Row` (Horizontal Alignment)
`Row` is used for headers, side-by-side metadata items, chip selectors, and horizontal card splits.

* **Headers & Controls:**
  * [`HomeScreen`](lib/screens/home_screen.dart): Greeting text and profile avatar side-by-side.
  * [`DaySelector`](lib/widgets/day_selector.dart): Horizontally places `MON | TUE | WED | THU | FRI` selection chips.
* **Data Fields & Card Layouts:**
  * [`ClassCard`](lib/widgets/class_card.dart): Places start/end time column, vertical divider line, subject details, and room badge in a horizontal sequence.
  * [`ProfessorCard`](lib/widgets/professor_card.dart): Aligns faculty avatar icon, name/department info, and navigation chevron arrow across a row.
  * [`EventCard`](lib/widgets/event_card.dart): Displays date, time, and location icons with their text side-by-side using inner rows.

```dart
Row(
  children: [
    // Time Column
    Column(children: [Text(entry.startTime), Text(entry.endTime)]),
    VerticalDivider(),
    // Subject Info
    Expanded(child: Column(...)),
    // Room Badge
    Container(child: Text(entry.room)),
  ],
)
```

---

### 3. `Stack` (Overlapping & Badge Positioning)
`Stack` is used specifically where elements need to visually float or overlap on top of base containers.

* **Coming Soon Badges (`FeatureCard`):**
  * [`FeatureCard`](lib/widgets/feature_card.dart): Overlays a "Soon" pill badge at the top-right corner (`Positioned`) of disabled cards without disrupting the inner card content padding.
* **Category Badges (`EventCard`):**
  * [`EventCard`](lib/widgets/event_card.dart): Overlays color-coded event category badges (Tech, Cultural, Hackathon) at the top-right position of event cards.
* **Hero Event Banner (`EventDetailScreen`):**
  * [`EventDetailScreen`](lib/screens/event_detail_screen.dart): Overlays a translucent category tag over the top-right of the hero gradient header.

```dart
Stack(
  children: [
    // Main Card Content
    Container(
      padding: const EdgeInsets.all(16),
      child: Column(...),
    ),
    // Positioned Badge Overlay
    if (isComingSoon)
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          child: Text('Soon'),
        ),
      ),
  ],
)
```

---

## 📁 Project Architecture

```text
lib/
├── main.dart                      # App entry point & MaterialApp configuration
├── theme/
│   └── app_theme.dart             # Material 3 light design system & color tokens
├── models/
│   ├── professor.dart             # Professor data model
│   ├── class_entry.dart           # Timetable entry model
│   └── event.dart                 # Campus event data model
├── data/
│   └── mock_data.dart             # VJTI LY CE timetable & department mock data
├── widgets/
│   ├── feature_card.dart          # Grid feature card with Stack overlay
│   ├── class_card.dart            # Timetable entry row card
│   ├── professor_card.dart        # Faculty list item widget
│   ├── event_card.dart            # Event item widget with Stack category badge
│   ├── today_classes_card.dart    # Quick summary card on Home dashboard
│   └── day_selector.dart          # Horizontal day selector chip row
└── screens/
    ├── home_screen.dart           # Main dashboard screen
    ├── timetable_screen.dart      # Weekly timetable screen
    ├── professors_screen.dart     # Faculty directory screen
    ├── professor_detail_screen.dart # Faculty profile screen
    ├── events_screen.dart         # Events listing screen
    └── event_detail_screen.dart   # Event details & registration screen
```

---

## 🚀 How to Run

1. **Prerequisites:** Flutter SDK (3.x or higher) installed and configured.
2. **Clone / Open Workspace:** Navigate to the project root directory.
3. **Run Application:**

```bash
flutter run
```
