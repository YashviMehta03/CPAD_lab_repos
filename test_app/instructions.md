# Split-Bill Ledger — Flutter App Specification

## 1. Overview

A local-only (no backend, no auth, no internet required) Flutter app for tracking shared
group expenses and settling debts with the **minimum possible number of transactions**.

**Unique selling point:** Unlike Splitwise (where debt simplification is a buried settings
toggle), this app makes debt simplification the **hero feature** — a live, animated debt
graph where people are nodes and debts are edges. Tapping "Simplify" visibly collapses a
tangled web of arrows into the minimal clean set of payments needed to settle the group.

Every user has their own copy of the app on their own phone. There is no sync between
devices — each person manages their own group's data locally (this is a lab/portfolio
project, not a production multi-device product). Do not build any backend, cloud sync,
or authentication.

---

## 2. Tech Stack

- **Framework:** Flutter (latest stable), Dart
- **State management:** `provider` package (`ChangeNotifier` + `Consumer`/`Selector`)
- **Local persistence:** `hive` + `hive_flutter` (NoSQL, on-device, no native SQL boilerplate)
- **Local auth:** `crypto` package (for hashing the locally-stored password) — no real
  auth backend, no Firebase Auth, no OAuth
- **Charts/graph rendering:** Custom rendering via `CustomPainter` (do NOT use a heavy
  graph-visualization package — the animated debt graph should be hand-built with
  `CustomPainter` + `AnimationController` so the animation behavior is fully controllable)
- **Optional (only if time allows):** `share_plus` for exporting a settlement summary as text
- **No backend, no REST calls, no Firebase, no login/auth of any kind**

---

## 3. Data Models

```dart
class Group {
  String id;
  String name;
  DateTime createdAt;
  List<String> memberIds;
}

class Member {
  String id;
  String groupId;
  String name;
  String colorHex; // for consistent color-coding across graph/UI
}

class Expense {
  String id;
  String groupId;
  String description;
  double amount;
  String paidByMemberId;
  DateTime date;
  SplitType splitType; // equal, custom, percentage
  Map<String, double> splitAmong; // memberId -> amount owed for this expense
}

enum SplitType { equal, custom, percentage }
```

Store `Group`, `Member`, and `Expense` in separate Hive boxes, keyed by `id`.

---

## 4. Core Features (MVP — must build)

### 4.0 Local-Only Login (no backend, no cloud verification)
The app should feel like it has a real login/account system, but everything is stored
and checked **entirely on-device** — there is no server validating credentials.

- **First launch:** show a `SignUpScreen` — user enters a display name, email/username,
  and password (or a simple 4-digit PIN, either is fine)
- On submit, hash the password locally (e.g. with the `crypto` package's `sha256`) and
  store `{name, username, passwordHash}` in a dedicated Hive box (`authBox`)
- **Subsequent launches:** show a `LoginScreen` — user enters username + password; app
  hashes the input and compares against the stored hash in `authBox`
  - Match -> navigate to `GroupListScreen`
  - No match -> show inline error, do not proceed
- Store a simple `isLoggedIn` flag (or just check "does authBox have a matching session")
  in Hive so the user doesn't have to log in every single time the app opens — add a
  `LogoutButton` (e.g. in an app bar / settings screen) that clears the session flag and
  routes back to `LoginScreen`
- Support only a **single local account per device** — this is not a multi-user system,
  it's just enough of a login flow to feel like a real app. Do not attempt to support
  multiple accounts, password reset, or "forgot password" (no email service exists to
  send anything through)
- The logged-in user's name can be used as the default "you" identity when creating
  groups/expenses (e.g. auto-suggest them as a member when creating a new group)

**Why this is safe to build without a backend:** since there is no server and no shared
data, this login exists purely to gate access to the app and demonstrate an auth UI flow
— it is not meant to be secure against a determined attacker with access to the device's
local storage, and that's fine for this project's scope.

### 4.1 Group Management
- Create a group with a name (e.g. "Goa Trip")
- Add members to the group by name (no email/phone required, just a display name + auto
  assigned color from a fixed palette)
- Edit/delete a group
- List all groups on the home screen

### 4.2 Expense Tracking
- Add an expense: description, amount, who paid, which members are included, split type
  - **Equal split:** amount divided evenly among selected members
  - **Custom split:** manually enter each selected member's share (must sum to total)
  - **Percentage split:** enter percentage per member (must sum to 100%)
- Edit/delete an expense
- List of all expenses for a group (most recent first), swipe-to-delete (`Dismissible`)

### 4.3 Balance Calculation
- For each member, compute **net balance** = total amount they paid − total amount they owe
  across all expenses in the group
- Positive balance = they are owed money; negative = they owe money
- Display as a simple list/card view: green cards for "is owed", red cards for "owes"

### 4.4 Debt Simplification Algorithm (core logic — implement carefully)
Implement a pure Dart function, fully unit-testable, independent of UI:

```dart
List<Settlement> simplifyDebts(Map<String, double> netBalances);

class Settlement {
  final String fromMemberId; // who pays
  final String toMemberId;   // who receives
  final double amount;
}
```

**Algorithm (greedy max-heap / sorted-list approach):**
1. Split members into creditors (net balance > 0) and debtors (net balance < 0)
2. Sort creditors descending by amount owed to them; sort debtors descending by amount
   they owe
3. Repeatedly match the largest debtor with the largest creditor:
   - `settleAmount = min(abs(debtor.balance), creditor.balance)`
   - Record a `Settlement(from: debtor, to: creditor, amount: settleAmount)`
   - Reduce both balances by `settleAmount`; if either reaches ~0, remove from the list
4. Repeat until all balances are ~0 (use an epsilon like `0.01` for floating point safety)

This produces the **minimum number of transactions** to settle the group and is the app's
main differentiator — call it out clearly in the UI (e.g. "12 raw debts simplified into
3 payments").

### 4.5 Debt Graph Visualization (HERO FEATURE — this is the app's main visual identity)
Build a custom-painted, animated graph view:
- **Nodes:** one circle per member, labeled with their name/initial, positioned in a
  circle layout (evenly spaced around a center point — simple trig, no physics engine needed)
- **Edges (raw debts, "before" state):** curved or straight arrows between every pair of
  members with an outstanding debt between them, arrow thickness/opacity scaled to amount,
  arrow color could indicate direction (from debtor to creditor)
- **"Simplify" button/toggle:** on tap, animate the transition from the raw debt graph to
  the simplified graph:
  - Fade out edges that get eliminated
  - Animate remaining edges to their simplified amounts (use `AnimationController` +
    `Tween<double>` driving a `CustomPainter` repaint, e.g. 600–800ms duration, `Curves.easeInOut`)
  - Show a small counter animating from "N transactions" to "M transactions" alongside
    the graph
- Tapping an edge/arrow shows a tooltip or bottom sheet with "X owes Y ₹Z"
- Include a toggle to switch back to "raw" view vs "simplified" view at any time

This screen (Balances/Graph tab) should feel like the centerpiece of the app — polish
this over anything else.

### 4.6 Settle Up
- From the simplified settlement list, each suggested payment has a "Mark as Paid" action
- Marking a settlement as paid should record it (e.g. as a special "settlement" expense
  entry with a distinct type/flag) so balances recalculate correctly and the graph updates
- Once fully settled, group shows a "All settled up 🎉" state

### 4.7 Local Persistence
- All groups, members, expenses persist across app restarts via Hive
- No network calls anywhere in the app

---

## 5. Stretch Features (only after MVP is fully working)

- Expense categories (food/travel/stay/etc.) with icons, and a pie chart (`fl_chart`) of
  spend breakdown per category
- Multiple groups with a group switcher
- Export settlement summary as shareable text (`share_plus`)
- Dark mode toggle
- Animated "settlement timeline" showing how net balances evolved over time as expenses
  were added (secondary chart, not the main graph feature)

---

## 6. Screens / Navigation Structure

```
MyApp (MaterialApp)
 - checks Hive on startup: no account -> SignUpScreen
                            account exists, no active session -> LoginScreen
                            active session -> GroupListScreen

 └─ SignUpScreen
      - Name, username, password fields (Form + validators)
      - "Create Account" button -> hash + store in authBox -> GroupListScreen

 └─ LoginScreen
      - Username, password fields
      - "Log In" button -> verify hash against authBox -> GroupListScreen (or inline error)

 └─ GroupListScreen
      - ListView.builder of existing groups
      - FloatingActionButton -> CreateGroupScreen
      - Tap a group -> GroupDetailScreen

 └─ CreateGroupScreen
      - Text field for group name
      - Dynamic list of member name inputs (add/remove rows)
      - Save button -> back to GroupListScreen

 └─ GroupDetailScreen (TabBar with 3 tabs)
      ├─ ExpensesTab
      │    - ListView.builder of expense cards (Dismissible to delete, tap to edit)
      │    - FloatingActionButton -> AddExpenseScreen (as modal bottom sheet or new route)
      │
      ├─ BalancesTab  <-- HERO SCREEN
      │    - Toggle: "Raw Debts" / "Simplified"
      │    - Animated debt graph (CustomPainter) as centerpiece
      │    - Transaction count animated label ("12 → 3 transactions")
      │    - Below graph: list view of the same settlements as cards, each with
      │      "Mark as Paid" button
      │
      └─ MembersTab (optional, could merge into group settings)
           - List of members with running net balance shown as a colored chip

 └─ AddExpenseScreen
      - Description text field
      - Amount text field
      - "Paid by" dropdown (members)
      - Split type selector (ChoiceChip: Equal / Custom / Percentage)
      - Checkbox list of members to include in split
      - If Custom/Percentage: inline text fields per selected member that must sum
        correctly (show validation error if not)
      - Save button
```

---

## 7. Key Widgets to Use (for grading/demo purposes, make sure these appear)

- `TabBar` / `TabBarView`
- `ListView.builder`
- `Dismissible` (swipe to delete)
- `CustomPainter` + `AnimationController` (the debt graph — most important)
- `ChoiceChip` / `Chip` (split type selector, member color chips)
- `Provider` / `ChangeNotifier` / `Consumer` (state management)
- `showModalBottomSheet` or `Navigator.push` (add expense flow)
- `AnimatedContainer` / `AnimatedSwitcher` (balance card transitions)
- `Hive` (local persistence)
- Form validation (`TextFormField` + `Form` + validators) for expense amounts/splits

---

## 8. Suggested Build Order

1. Set up project, add dependencies (`provider`, `hive`, `hive_flutter`)
2. Define data models + Hive adapters (`hive_generator` + `build_runner`)
3. Build `GroupProvider`/`ExpenseProvider` (ChangeNotifier classes wrapping Hive boxes)
4. Build GroupListScreen + CreateGroupScreen (basic CRUD, no styling polish yet)
5. Build AddExpenseScreen + ExpensesTab (get expense CRUD fully working)
6. Implement `simplifyDebts()` as a **pure function with unit tests** — get this correct
   before touching any UI
7. Build BalancesTab with a simple non-animated list first (verify the numbers are correct)
8. Build the `CustomPainter` debt graph (static first: just draw nodes + straight edges)
9. Add the raw-to-simplified animation on top of the working static graph
10. Add "Mark as Paid" settlement flow
11. Polish: colors, spacing, empty states, dark mode if time allows
12. (Stretch) categories, charts, export

---

## 9. Non-Goals (explicitly do NOT build)

- No backend server, no REST API, no cloud database
- No real/cloud authentication (Firebase Auth, OAuth, etc.) — login exists but is
  entirely local-only, single-account, credentials checked against on-device Hive storage
- No multi-user accounts, password reset/forgot-password flow, or email verification
- No multi-device sync
- No push notifications
- No payment gateway integration (this app only calculates who-owes-whom, it does not
  move real money)