import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import 'admin/master_data_screen.dart';
import 'admin/tickets_inbox_screen.dart';
import 'professor/helpline_screen.dart';
import 'professor/prof_home_screen.dart';
import 'professor/queue_manage_screen.dart';
import 'professor/reschedule_screen.dart';
import 'professor/prof_more_screen.dart';
import 'shared/notifications_screen.dart';
import 'shared/timetable_screen.dart';
import 'student/faculty_screen.dart';
import 'student/rooms_screen.dart';
import 'student/student_home_screen.dart';
import 'student/student_more_screen.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.builder);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;
}

/// One app, a different home per role.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _unread = 0;
  Timer? _poll;
  late final List<_Tab> _tabs = _tabsFor(Session.I.role);
  late final List<Widget?> _built = List.filled(_tabs.length, null);

  List<_Tab> _tabsFor(String role) => switch (role) {
        'professor' => [
            _Tab('Home', Icons.dashboard_outlined, Icons.dashboard, () => ProfHomeScreen(onOpenTab: _go)),
            _Tab('Queue', Icons.people_outline, Icons.people, () => const QueueManageScreen()),
            _Tab('Classes', Icons.event_repeat_outlined, Icons.event_repeat, () => const RescheduleScreen()),
            _Tab('Helpline', Icons.support_agent_outlined, Icons.support_agent, () => const HelplineScreen()),
            _Tab('More', Icons.grid_view_outlined, Icons.grid_view, () => const ProfMoreScreen()),
          ],
        'admin' => [
            _Tab('Helpdesk', Icons.confirmation_number_outlined, Icons.confirmation_number,
                () => const TicketsInboxScreen()),
            _Tab('Master data', Icons.storage_outlined, Icons.storage, () => const MasterDataScreen()),
          ],
        _ => [
            _Tab('Home', Icons.home_outlined, Icons.home, () => StudentHomeScreen(onOpenTab: _go)),
            _Tab('Timetable', Icons.calendar_view_week_outlined, Icons.calendar_view_week,
                () => const TimetableScreen()),
            _Tab('Faculty', Icons.badge_outlined, Icons.badge, () => const FacultyScreen()),
            _Tab('Rooms', Icons.meeting_room_outlined, Icons.meeting_room, () => const RoomsScreen()),
            _Tab('More', Icons.grid_view_outlined, Icons.grid_view, () => const StudentMoreScreen()),
          ],
      };

  void _go(int i) => setState(() => _index = i);

  @override
  void initState() {
    super.initState();
    _refreshUnread();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refreshUnread());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnread() async {
    try {
      final r = await Api.I.get('/notifications/unread-count');
      if (mounted) setState(() => _unread = (r['unread'] as num).toInt());
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    _refreshUnread();
  }

  void _profileSheet() {
    final u = Session.I.user!;
    final sub = switch (Session.I.role) {
      'student' => '${u['student']?['roll_no']} · ${u['student']?['branch_code']} ${u['student']?['year_code']}-${u['student']?['section_name']}',
      'professor' => '${u['professor']?['code']} · ${u['professor']?['cabin'] ?? ''}',
      _ => '${u['admin']?['title']}',
    };
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: CircleAvatar(child: Text(Session.I.name.isNotEmpty ? Session.I.name[0] : '?')),
            title: Text(Session.I.name),
            subtitle: Text('$sub\n${u['email']}'),
            isThreeLine: true,
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Server'),
            subtitle: Text(Api.I.baseUrl),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {
              Navigator.pop(c);
              Session.I.logout();
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _built[_index] ??= _tabs[_index].builder();
    final title = _index == 0 && _tabs.length > 2 ? 'CampusSphere' : _tabs[_index].label;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: Badge(
              isLabelVisible: _unread > 0,
              label: Text(_unread > 99 ? '99+' : '$_unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: _profileSheet,
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(Session.I.name.isNotEmpty ? Session.I.name[0] : '?',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Keep visited tabs alive so switching back is instant.
      body: IndexedStack(
        index: _index,
        children: [for (var i = 0; i < _tabs.length; i++) _built[i] ?? const SizedBox.shrink()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: t.label),
        ],
      ),
    );
  }
}

/// Shared helper for "More" grids.
class MoreTile extends StatelessWidget {
  const MoreTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap, this.color});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.primary;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: c),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ]),
            ),
            Icon(Icons.chevron_right, color: cs.outline),
          ]),
        ),
      ),
    );
  }
}

void push(BuildContext context, Widget screen) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

/// A pushed screen with its own app bar.
class SubPage extends StatelessWidget {
  const SubPage({super.key, required this.title, required this.child, this.fab, this.actions});
  final String title;
  final Widget child;
  final Widget? fab;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(title), actions: actions), body: child, floatingActionButton: fab);
}
