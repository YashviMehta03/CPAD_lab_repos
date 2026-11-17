import 'package:flutter/material.dart';

import '../shared/notifications_screen.dart';
import '../shell.dart';
import 'boards_screen.dart';
import 'helpdesk_screen.dart';
import 'projects_screen.dart';

class StudentMoreScreen extends StatelessWidget {
  const StudentMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      MoreTile(
          icon: Icons.report_problem_outlined,
          title: 'Helpdesk',
          subtitle: 'Report a fan, Wi-Fi or hostel issue and track it',
          color: Colors.deepOrange,
          onTap: () => push(context, const HelpdeskScreen())),
      MoreTile(
          icon: Icons.description_outlined,
          title: 'Paperwork help',
          subtitle: 'Bonafide, no-dues, concession, scholarship boards',
          color: Colors.purple,
          onTap: () => push(context, const BoardsScreen())),
      MoreTile(
          icon: Icons.chat_bubble_outline,
          title: 'Chats',
          subtitle: 'Your 1:1 chats with helpers',
          color: Colors.indigo,
          onTap: () => push(context, const ChatsScreen())),
      MoreTile(
          icon: Icons.groups_outlined,
          title: 'Project meetings',
          subtitle: 'Request a meeting with your project guide',
          color: Colors.blueGrey,
          onTap: () => push(context, const ProjectsScreen())),
      MoreTile(
          icon: Icons.campaign_outlined,
          title: 'Announcements',
          subtitle: 'Broadcasts and class changes',
          color: Colors.pink,
          onTap: () => push(context, const NotificationsScreen(types: 'broadcast,class_change', title: 'Announcements'))),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: tiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => tiles[i],
    );
  }
}
