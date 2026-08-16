Build a Flutter app called **Campus Companion**, a clean student-focused campus information app.

The goal is to create a polished MVP that demonstrates good use of Flutter's **Row, Column, and Stack** widgets while keeping the functionality simple and easy to extend later.

## Overall Concept

Campus Companion should act as a central place where students can quickly access important campus information.

For the MVP, the Home screen should display around **6 main options**, but only these three need to be functional:

* **Timetable**
* **Professors**
* **Events**

The other three should be shown as "Coming Soon":

* Academic Calendar
* Lost & Found
* Announcements

Do not implement the Coming Soon features yet.

---

## Home Screen

Make the Home screen the main dashboard.

It should contain:

### Header

A simple greeting such as:

> Good morning 👋
> Campus Companion

Also show the current date underneath.

### Today's Classes

Show a compact card containing the next 2–3 classes for the student.

For example:

* 09:00 — Data Structures — Room 204
* 11:00 — Database Systems — Room 302
* 02:00 — Operating Systems — Lab 2

Include a **"View Timetable"** action that opens the full timetable.

### Feature Section

Below that, show the six main features in a clean 2-column grid or similar layout:

**Timetable**
View your weekly class schedule

**Professors**
Browse professors and their subjects

**Events**
See upcoming campus events

**Academic Calendar**
View holidays and important dates

**Lost & Found**
Find or report lost items

**Announcements**
View important campus updates

The first three should navigate to their respective screens.

The other three should have a subtle **Coming Soon** badge and show a SnackBar when tapped.

Use `Stack` meaningfully for the Coming Soon badge or similar overlays.

---

## Timetable Screen

Create a simple weekly timetable.

At the top, show the student's selected branch/year, for example:

> TY Computer Science

Below it, provide a day selector:

**MON | TUE | WED | THU | FRI**

When a day is selected, show a few hardcoded classes.

Each class should display:

* Time
* Subject
* Professor
* Room

For example:

> 09:00 – 10:00
> Data Structures
> Dr. Rahul Sharma
> Room 204

Use cards/list items and make the layout easy to scan.

The timetable does **not** need editing, database functionality, or personalization yet.

---

## Professor Screen

Create a simple **Professor Directory**.

Show around 5–6 hardcoded professors.

Each professor card/list item should contain:

* Professor name
* Department
* Main subject
* Profile/avatar icon
* Arrow indicating it can be opened

Example:

> Dr. Rahul Sharma
> Computer Science
> Data Structures →

When a professor is tapped, open a **Professor Details** screen.

The details screen can contain:

* Name
* Department
* Subjects taught
* Room
* Office hours
* Email/contact information

Keep this page relatively simple. The purpose is mainly to demonstrate navigation and good Flutter layouts.

---

## Events Screen

Create an **Upcoming Events** page with around 4–5 hardcoded events.

Each event should show:

* Event name
* Date
* Time
* Location
* Short description
* Category/icon

Example:

> **Tech Symposium**
> 24 August · 10:00 AM
> Main Auditorium
> Technology talks and student demonstrations

Clicking an event should open a simple **Event Details** screen with the same information in a larger layout.

A Register button can be included, but it does not need real functionality. It can simply show a SnackBar saying registration will be available later.

Use `Stack` where it makes sense, such as placing a date/category badge over an event image or card.

---

## UI Style

Make the app feel like a **real modern student app**, not a basic Flutter tutorial.

Use:

* Material 3
* Clean light background
* One main accent color
* Rounded cards
* Consistent spacing
* Clear typography
* Simple Material icons
* Subtle shadows/borders
* Good visual hierarchy

Avoid excessive gradients, animations, or overly decorative UI.

The Home screen should feel like a dashboard and should be vertically scrollable.

---

## Row / Column / Stack Requirement

The project is specifically intended to demonstrate these widgets, so use them naturally.

### Column

Use for:

* Overall screen layouts
* Text groups
* Professor/event details
* Sections on the Home page

### Row

Use for:

* Header
* Class information
* Professor cards
* Timetable day selector
* Horizontal information groups

### Stack

Use for:

* Coming Soon badges
* Event/date overlays
* Status indicators
* Image/icon overlays

Do not force `Stack` into places where it doesn't make sense.

---

## Code Structure

Keep the project reasonably organized rather than putting everything into `main.dart`.

A simple structure like this is enough:

```text
lib/
  main.dart
  models/
  data/
  screens/
  widgets/
  theme/
```

Create simple model classes for things like:

* Professor
* Class/Timetable entry
* Event

Keep the mock data separate from the UI so it can later be replaced with Firebase/API data.

Create reusable widgets for things like:

* Feature cards
* Class cards
* Professor cards
* Event cards

Don't introduce complicated architecture or state-management packages for this MVP.

---

## Scope

This is an **MVP**, not the final application.

Do NOT implement:

* Login/authentication
* Firebase
* Backend
* APIs
* Database
* Push notifications
* Real event registration
* Admin panel
* Lost & Found functionality
* Academic Calendar functionality
* Announcements functionality

However, structure the code so these features can be added later without rebuilding the entire app.

The final result should be a **polished, functional Flutter prototype** with:

**Home → Timetable → Professor Directory → Professor Details → Events → Event Details**

and the three additional features visible as **Coming Soon**.

Prioritize **good UI, clean navigation, meaningful Row/Column/Stack usage, and extensibility** over adding unnecessary functionality.
