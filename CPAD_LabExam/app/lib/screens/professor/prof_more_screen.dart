import 'package:flutter/material.dart';

import '../shared/timetable_screen.dart';
import '../shell.dart';
import 'broadcast_screen.dart';
import 'meetings_screen.dart';

class ProfMoreScreen extends StatelessWidget {
  const ProfMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      MoreTile(
          icon: Icons.campaign_outlined,
          title: 'Broadcast',
          subtitle: 'Send to a branch, year, section or chosen students',
          color: Colors.pink,
          onTap: () => push(context, const BroadcastScreen())),
      MoreTile(
          icon: Icons.groups_outlined,
          title: 'Project meetings',
          subtitle: 'Accept, reject or suggest a time',
          color: Colors.indigo,
          onTap: () => push(context, const MeetingsScreen())),
      MoreTile(
          icon: Icons.calendar_view_week_outlined,
          title: 'Timetables',
          subtitle: 'My week, or any branch, year and section',
          color: Colors.teal,
          onTap: () => push(context, const SubPage(title: 'Timetable', child: TimetableScreen()))),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: tiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => tiles[i],
    );
  }
}
