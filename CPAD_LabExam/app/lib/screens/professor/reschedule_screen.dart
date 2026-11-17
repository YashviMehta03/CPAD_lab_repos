import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/widgets.dart';
import '../shared/timetable_screen.dart';
import '../shell.dart';

/// My classes for the next 7 days: cancel, move (with smart suggestions) or undo.
class RescheduleScreen extends StatefulWidget {
  const RescheduleScreen({super.key});

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  final _key = GlobalKey<LoaderState>();

  Future<void> _cancel(Json o) async {
    final reason = await askText(context, 'Cancel ${o['label'] ?? o['subject_name']}?',
        hint: 'Reason students will see (optional)', ok: 'Cancel class');
    if (reason == null || !mounted) return;
    var n = 0;
    if (await run(context, () async {
      final r = await Api.I.post('/reschedule/cancel', {'entry_id': o['id'], 'original_date': o['date'], 'reason': reason});
      n = (r['change']['notified'] as num).toInt();
    })) {
      if (mounted) toast(context, 'Cancelled. $n students notified.');
      _key.currentState?.reload();
    }
  }

  Future<void> _undo(Json o) async {
    if (!await confirm(context, 'Undo change?', 'The class goes back to its usual time and room, and students are told.', ok: 'Undo')) {
      return;
    }
    if (!mounted) return;
    if (await run(context, () => Api.I.delete('/reschedule/changes/${o['change_id']}'), success: 'Restored')) {
      _key.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Loader(
      key: _key,
      load: () => Api.I.get('/reschedule/my-classes'),
      builder: (context, d, reload) {
        final periods = {for (final p in d['periods'] as List) p['period']: p};
        final occ = (d['occurrences'] as List).cast<Json>();
        final byDate = <String, List<Json>>{};
        for (final o in occ) {
          byDate.putIfAbsent(o['date'] as String, () => []).add(o);
        }
        return PageList(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Text('Your classes in the next 7 days. Move one and CampusSphere finds slots where the whole section and a suitable room are free.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          if (occ.isEmpty) const EmptyState(icon: Icons.event_available, text: 'No classes in the next 7 days'),
          for (final e in byDate.entries) ...[
            SectionHeader(fmtDayLong(e.key)),
            for (final o in e.value)
              OccurrenceCard(
                o: o,
                periods: periods,
                showSection: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'move') {
                      final moved = await Navigator.push<bool>(
                          context, MaterialPageRoute(builder: (_) => SuggestSlotsScreen(occurrence: o, periods: periods)));
                      if (moved == true) reload();
                    } else if (v == 'cancel') {
                      _cancel(o);
                    } else if (v == 'undo') {
                      _undo(o);
                    }
                  },
                  itemBuilder: (_) => o['status'] == 'scheduled'
                      ? const [
                          PopupMenuItem(value: 'move', child: ListTile(leading: Icon(Icons.auto_awesome), title: Text('Move (find slots)'))),
                          PopupMenuItem(value: 'cancel', child: ListTile(leading: Icon(Icons.block), title: Text('Cancel class'))),
                        ]
                      : const [PopupMenuItem(value: 'undo', child: ListTile(leading: Icon(Icons.undo), title: Text('Undo change')))],
                ),
              ),
          ],
        ]);
      },
    );
  }
}

class SuggestSlotsScreen extends StatefulWidget {
  const SuggestSlotsScreen({super.key, required this.occurrence, required this.periods});
  final Json occurrence;
  final Map periods;

  @override
  State<SuggestSlotsScreen> createState() => _SuggestSlotsScreenState();
}

class _SuggestSlotsScreenState extends State<SuggestSlotsScreen> {
  final _reason = TextEditingController();
  final _room = <int, int>{};
  bool _busy = false;

  Future<void> _apply(Json opt, int index) async {
    setState(() => _busy = true);
    var n = 0;
    final o = widget.occurrence;
    final ok = await run(context, () async {
      final r = await Api.I.post('/reschedule/apply', {
        'entry_id': o['id'],
        'original_date': o['date'],
        'new_date': opt['date'],
        'period_start': opt['period_start'],
        'room_id': _room[index] ?? opt['room_id'],
        'reason': _reason.text,
      });
      n = (r['change']['notified'] as num).toInt();
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      toast(context, 'Moved. $n students notified.');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.occurrence;
    final label = o['label'] ?? o['subject_name'];
    return SubPage(
      title: 'Move $label',
      child: Loader(
        load: () => Api.I.post('/reschedule/suggest', {'entry_id': o['id'], 'original_date': o['date']}),
        builder: (context, d, _) {
          final cs = Theme.of(context).colorScheme;
          final options = (d['options'] as List).cast<Json>();
          return PageList(children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: Text('$label · ${o['branch_code']} ${o['year_code']}-${o['section_name']}'),
                subtitle: Text('Now: ${fmtDay(o['date'] as String)}, ${widget.periods[o['period_start']]['start']}'
                    '-${widget.periods[o['period_end']]['end']} in ${o['room_name'] ?? 'TBA'}'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _reason, decoration: const InputDecoration(labelText: 'Reason for students (optional)')),
            SectionHeader(options.isEmpty ? 'No free slots found' : 'Top ${options.length} slots'),
            if (options.isEmpty)
              const EmptyState(
                  icon: Icons.event_busy, text: 'The section, you, or every suitable room is busy at all other times this week.'),
            for (var i = 0; i < options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  shape: i == 0
                      ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.primary, width: 2))
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: i == 0 ? cs.primary : cs.surfaceContainerHigh,
                          child: Text('${i + 1}', style: TextStyle(color: i == 0 ? cs.onPrimary : cs.onSurface, fontSize: 13)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${options[i]['day']}, ${fmtDay(options[i]['date'] as String)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        if (i == 0) Pill('Best', color: cs.primary, icon: Icons.star),
                      ]),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 38),
                        child: Text('${options[i]['start_time']} - ${options[i]['end_time']}',
                            style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final r in options[i]['reasons'] as List)
                          Pill(r as String,
                              color: r.startsWith('Back-to-back') || r.contains('period of the day') ? Colors.orange.shade800 : Colors.green.shade700,
                              dense: true),
                      ]),
                      const SizedBox(height: 12),
                      OptionDropdown(
                        label: 'Room',
                        options: [
                          {'id': options[i]['room_id'], 'label': '${options[i]['room_name']} (${options[i]['room_capacity']} seats)'},
                          for (final r in options[i]['other_free_rooms'] as List) {'id': r['id'], 'label': '${r['name']} (${r['capacity']} seats)'},
                        ],
                        value: _room[i] ?? options[i]['room_id'],
                        onChanged: (v) => setState(() => _room[i] = v as int),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _apply(options[i], i),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                        icon: const Icon(Icons.check),
                        label: const Text('Move here and notify students'),
                      ),
                    ]),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}
