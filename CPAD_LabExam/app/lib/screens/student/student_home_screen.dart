import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/widgets.dart';
import '../shared/notifications_screen.dart';
import '../shared/timetable_screen.dart';
import '../shell.dart';
import 'boards_screen.dart';
import 'helpdesk_screen.dart';
import 'projects_screen.dart';

int toMin(String t) {
  final p = t.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key, required this.onOpenTab});
  final void Function(int) onOpenTab;

  Future<Json> _load() async {
    final r = await Future.wait([
      Api.I.get('/meta/structure'),
      Api.I.get('/timetable/me'),
      Api.I.get('/queue/mine'),
      Api.I.get('/notifications', query: {'type': 'broadcast,class_change'}),
    ]);
    return {'structure': r[0], 'tt': r[1], 'queue': r[2], 'news': r[3]};
  }

  @override
  Widget build(BuildContext context) {
    return Loader(
      load: _load,
      pollEvery: const Duration(seconds: 30),
      builder: (context, d, reload) {
        final cs = Theme.of(context).colorScheme;
        final now = d['structure']['now'] as Json;
        final today = now['date'] as String;
        final minutes = (now['minutes'] as num).toInt();
        final periods = {for (final p in d['tt']['periods'] as List) p['period']: p};
        final todays = (d['tt']['week']['occurrences'] as List).where((o) => o['date'] == today).toList();
        final active = todays.where((o) => o['status'] == 'scheduled' || o['status'] == 'moved_in').toList();
        final current = active.where((o) =>
            toMin(periods[o['period_start']]['start']) <= minutes && minutes <= toMin(periods[o['period_end']]['end']));
        final upcoming = active.where((o) => toMin(periods[o['period_start']]['start']) > minutes);
        final tokens = d['queue']['tokens'] as List;
        final news = (d['news']['notifications'] as List).take(3).toList();
        final st = Session.I.user!['student'] as Json;

        return PageList(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs.primary, cs.tertiary], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hi, ${Session.I.name.split(' ').first}',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${st['branch_name']} · ${st['year_code']}-${st['section_name']} · ${fmtDayLong(today)}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              _nowNext(current.isNotEmpty ? current.first : null, upcoming.isNotEmpty ? upcoming.first : null, periods),
            ]),
          ),
          if (tokens.isNotEmpty) ...[
            const SectionHeader('Your queue tokens'),
            for (final t in tokens)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: t['status'] == 'serving' ? Colors.green : cs.primaryContainer,
                    child: Text('#${t['token_no']}',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold, color: t['status'] == 'serving' ? Colors.white : null)),
                  ),
                  title: Text(t['professor_name'] as String),
                  subtitle: Text(t['status'] == 'serving'
                      ? "It's your turn. Go to ${t['cabin'] ?? 'the cabin'}"
                      : '${t['ahead']} ahead of you · ${t['cabin'] ?? ''}'),
                  trailing: TextButton(
                    onPressed: () async {
                      if (await run(context, () => Api.I.delete('/queue/tokens/${t['id']}'), success: 'Left the queue')) {
                        reload();
                      }
                    },
                    child: const Text('Leave'),
                  ),
                ),
              ),
          ],
          SectionHeader('Today', trailing: TextButton(onPressed: () => onOpenTab(1), child: const Text('Full timetable'))),
          if (todays.isEmpty) const EmptyState(icon: Icons.weekend_outlined, text: 'No classes today'),
          for (final o in todays) OccurrenceCard(o: o as Json, periods: periods),
          const SectionHeader('Quick actions'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _Quick(Icons.meeting_room_outlined, 'Find a free room', Colors.indigo, () => onOpenTab(3)),
              _Quick(Icons.badge_outlined, 'Meet a professor', Colors.teal, () => onOpenTab(2)),
              _Quick(Icons.report_problem_outlined, 'Report an issue', Colors.deepOrange,
                  () => push(context, const HelpdeskScreen())),
              _Quick(Icons.description_outlined, 'Paperwork help', Colors.purple, () => push(context, const BoardsScreen())),
              _Quick(Icons.groups_outlined, 'Project meetings', Colors.blueGrey, () => push(context, const ProjectsScreen())),
              _Quick(Icons.campaign_outlined, 'Announcements', Colors.pink,
                  () => push(context, const NotificationsScreen(types: 'broadcast,class_change', title: 'Announcements'))),
            ],
          ),
          if (news.isNotEmpty) ...[
            const SectionHeader('Latest announcements'),
            for (final n in news)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(notificationIcon(n['type'] as String), color: cs.primary),
                  title: Text(n['title'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${n['body'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(timeAgo(n['created_at'] as String), style: TextStyle(fontSize: 11, color: cs.outline)),
                ),
              ),
          ],
        ]);
      },
    );
  }

  Widget _nowNext(dynamic current, dynamic next, Map periods) {
    Widget block(String tag, dynamic o) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(o == null ? 'Free' : (o['label'] ?? o['subject_name']) as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              Text(
                  o == null
                      ? (tag == 'Now' ? 'No class right now' : 'Nothing more today')
                      : '${periods[o['period_start']]['start']} · ${o['room_name'] ?? 'TBA'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        );
    return Row(children: [block('Now', current), const SizedBox(width: 10), block('Next', next)]);
  }
}

class _Quick extends StatelessWidget {
  const _Quick(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon, color: color),
              Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}
