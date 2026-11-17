import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../shared/timetable_screen.dart';
import '../shell.dart';
import 'broadcast_screen.dart';
import 'meetings_screen.dart';

/// Professor dashboard: one-tap availability, queue at a glance, today's classes, pending requests.
class ProfHomeScreen extends StatelessWidget {
  const ProfHomeScreen({super.key, required this.onOpenTab});
  final void Function(int) onOpenTab;

  Future<Json> _load() async {
    final r = await Future.wait([
      Api.I.get('/professors/${Session.I.userId}'),
      Api.I.get('/queue/manage'),
      Api.I.get('/meetings'),
      Api.I.get('/meta/structure'),
    ]);
    return {'me': r[0], 'queue': r[1], 'meetings': r[2], 'structure': r[3]};
  }

  @override
  Widget build(BuildContext context) {
    return Loader(
      load: _load,
      pollEvery: const Duration(seconds: 30),
      builder: (context, d, reload) {
        final cs = Theme.of(context).colorScheme;
        final me = d['me']['professor'] as Json;
        final today = d['me']['today'] as List;
        final q = d['queue'] as Json;
        final waiting = (q['waiting'] as List).length;
        final pending = (d['meetings']['meetings'] as List).where((m) => m['status'] == 'pending').length;
        final periods = {for (final p in d['structure']['periods'] as List) p['period']: p};
        final nowDate = d['structure']['now']['date'] as String;

        return PageList(children: [
          _StatusCard(me: me, onChanged: reload),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _Stat(
                icon: Icons.people_outline,
                value: '$waiting',
                label: q['serving'] != null ? 'waiting · #${q['serving']['token_no']} with you' : 'waiting in queue',
                color: Colors.teal,
                onTap: () => onOpenTab(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                icon: Icons.groups_outlined,
                value: '$pending',
                label: 'meeting requests',
                color: Colors.indigo,
                onTap: () => push(context, const MeetingsScreen()),
              ),
            ),
          ]),
          SectionHeader('Today · ${fmtDay(nowDate)}',
              trailing: TextButton(onPressed: () => onOpenTab(2), child: const Text('Reschedule'))),
          if (today.isEmpty) const EmptyState(icon: Icons.free_breakfast_outlined, text: 'No classes today'),
          for (final o in today) OccurrenceCard(o: o as Json, periods: periods, showSection: true),
          const SectionHeader('Quick actions'),
          MoreTile(
              icon: Icons.campaign_outlined,
              title: 'Broadcast',
              subtitle: 'Notify a branch, year, section or chosen students',
              color: Colors.pink,
              onTap: () => push(context, const BroadcastScreen())),
          const SizedBox(height: 10),
          MoreTile(
              icon: Icons.support_agent_outlined,
              title: 'Exam helpline',
              subtitle: 'Who to call about a subject, right now',
              color: Colors.deepOrange,
              onTap: () => onOpenTab(3)),
          const SizedBox(height: 10),
          MoreTile(
              icon: Icons.calendar_view_week_outlined,
              title: 'Timetables',
              subtitle: 'My week, or any section',
              color: cs.primary,
              onTap: () => push(context, const SubPage(title: 'Timetable', child: TimetableScreen()))),
        ]);
      },
    );
  }
}

class _StatusCard extends StatefulWidget {
  const _StatusCard({required this.me, required this.onChanged});
  final Json me;
  final Future<void> Function() onChanged;

  @override
  State<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<_StatusCard> {
  bool _busy = false;

  Future<void> _set(String status) async {
    String? note;
    if (status == 'on_leave' || status == 'away' || status == 'busy') {
      note = await askText(context, statusStyles[status]!.label,
          hint: status == 'on_leave' ? 'e.g. Back on Thursday' : 'Optional note, e.g. Back at 3 pm', ok: 'Set');
      if (note == null) return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    await run(context, () => Api.I.put('/professors/me/status', {'status': status, 'note': note}));
    await widget.onChanged();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    final status = me['status'] as String;
    final manual = me['manual_status'] as String;
    final style = statusStyles[status]!;
    final cur = me['current_class'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [style.color, style.color.withValues(alpha: 0.75)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(style.icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Students see you as', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(style.label, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            ]),
          ),
          if (_busy) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        ]),
        const SizedBox(height: 6),
        Text(
          status == 'out_of_college'
              ? 'College hours are over (after 5:30 pm). Students see you as Out of college until tomorrow.'
              : cur != null
              ? 'Automatic from your timetable: ${cur['label']} in ${cur['room'] ?? '-'} until ${cur['end_time']}. '
                  'After class you will show as ${statusStyles[manual]!.label}.'
              : (me['status_note'] as String?) ?? 'Tap to change. During your classes this switches to In class by itself.',
          style: const TextStyle(color: Colors.white, height: 1.3),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in ['in_cabin', 'busy', 'away', 'on_leave'])
            ChoiceChip(
              avatar: Icon(statusStyles[s]!.icon, size: 16, color: manual == s ? statusStyles[s]!.color : Colors.white),
              label: Text(statusStyles[s]!.label),
              selected: manual == s,
              showCheckmark: false,
              // Solid dark fill + white outline so unselected options stay readable on any status colour.
              labelStyle: TextStyle(color: manual == s ? statusStyles[s]!.color : Colors.white, fontWeight: FontWeight.w600),
              backgroundColor: Colors.black.withValues(alpha: 0.28),
              side: const BorderSide(color: Colors.white70),
              selectedColor: Colors.white,
              onSelected: _busy ? null : (_) => _set(s),
            ),
        ]),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String value;
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            ]),
          ),
        ),
      );
}
