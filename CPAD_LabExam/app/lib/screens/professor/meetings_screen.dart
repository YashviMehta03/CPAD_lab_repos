import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/widgets.dart';
import '../shell.dart';
import '../student/projects_screen.dart';

/// Professor: project group meeting requests. Accept, reject or suggest another time.
class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final _key = GlobalKey<LoaderState>();

  Future<void> _respond(Json m, String action) async {
    final note = await askText(context, action == 'accept' ? 'Accept meeting' : 'Reject meeting',
        hint: 'Note for the group (optional)', ok: action == 'accept' ? 'Accept' : 'Reject');
    if (note == null || !mounted) return;
    if (await run(context, () => Api.I.post('/meetings/${m['id']}/respond', {'action': action, 'note': note}),
        success: 'Sent. The group is notified.')) {
      _key.currentState?.reload();
    }
  }

  Future<void> _suggest(Json m) async {
    final picked = await showModalBottomSheet<Json>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SuggestSheet(groupId: m['group_id'] as int),
    );
    if (picked == null || !mounted) return;
    if (await run(context, () => Api.I.post('/meetings/${m['id']}/respond', {
          'action': 'suggest',
          'date': picked['date'],
          'period': picked['period'],
          'note': picked['note'],
        }), success: 'New time suggested')) {
      _key.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Project meetings',
      child: Loader(
        key: _key,
        load: () => Api.I.get('/meetings'),
        pollEvery: const Duration(seconds: 30),
        builder: (context, d, reload) {
          final meetings = (d['meetings'] as List).cast<Json>();
          final periods = {for (final p in d['periods'] as List) p['period']: p};
          final pending = meetings.where((m) => m['status'] == 'pending').toList();
          final rest = meetings.where((m) => m['status'] != 'pending').toList();
          return PageList(children: [
            SectionHeader('Waiting for you (${pending.length})'),
            if (pending.isEmpty) const EmptyState(icon: Icons.inbox_outlined, text: 'No pending requests'),
            for (final m in pending)
              MeetingCard(m: m, periods: periods, showGroup: true, actions: [
                FilledButton.icon(onPressed: () => _respond(m, 'accept'), icon: const Icon(Icons.check), label: const Text('Accept')),
                OutlinedButton.icon(onPressed: () => _suggest(m), icon: const Icon(Icons.schedule), label: const Text('Suggest time')),
                TextButton(onPressed: () => _respond(m, 'reject'), child: const Text('Reject')),
              ]),
            if (rest.isNotEmpty) ...[
              const SectionHeader('Earlier'),
              for (final m in rest) MeetingCard(m: m, periods: periods, showGroup: true),
            ],
          ]);
        },
      ),
    );
  }
}

class _SuggestSheet extends StatefulWidget {
  const _SuggestSheet({required this.groupId});
  final int groupId;

  @override
  State<_SuggestSheet> createState() => _SuggestSheetState();
}

class _SuggestSheetState extends State<_SuggestSheet> {
  Json? _slot;
  final _note = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Loader(
          load: () => Api.I.get('/meetings/groups/${widget.groupId}/slots'),
          builder: (context, d, _) {
            final slots = (d['slots'] as List).cast<Json>();
            return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
              Text('Suggest a time', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('Times when you and every group member are free.'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in slots)
                  ChoiceChip(
                    label: Text('${dayShort[parseDay(s['date'] as String).weekday]} ${fmtDay(s['date'] as String).split(', ').last}, ${s['start_time']}'),
                    selected: _slot == s,
                    onSelected: (_) => setState(() => _slot = s),
                  ),
              ]),
              if (slots.isEmpty) const EmptyState(icon: Icons.event_busy, text: 'No common free time this week'),
              const SizedBox(height: 16),
              TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note (optional)')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _slot == null ? null : () => Navigator.pop(context, {..._slot!, 'note': _note.text}),
                child: const Text('Suggest this time'),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
