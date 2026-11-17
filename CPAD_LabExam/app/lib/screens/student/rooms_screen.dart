import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/widgets.dart';

/// Free-room and lab finder for now or a chosen slot. Look-up only, no booking.
class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  String? _date;
  int? _ps;
  int? _pe;
  String? _type;
  Json? _structure;

  @override
  void initState() {
    super.initState();
    Api.I.get('/meta/structure').then((s) {
      if (mounted) setState(() => _structure = s);
    }).catchError((_) {});
  }

  Future<Json> _load() => Api.I.get('/rooms/free', query: {'date': _date, 'period_start': _ps, 'period_end': _pe, 'type': _type});

  @override
  Widget build(BuildContext context) {
    if (_structure == null) return const Center(child: CircularProgressIndicator());
    final periods = (_structure!['periods'] as List).cast<Json>();
    final days = nextWeekdays(_structure!['now']['date'] as String, 6);
    return Loader(
      load: _load,
      builder: (context, d, reload) {
        final f = d;
        final cs = Theme.of(context).colorScheme;
        final free = f['free'] as List;
        final occupied = f['occupied'] as List;
        final ps = (f['period_start'] as num).toInt();
        final pe = (f['period_end'] as num).toInt();
        final periodOpts = [for (final p in periods) {'id': p['period'], 'label': '${p['start']} (P${p['period']})'}];
        final endOpts = [
          for (final p in periods)
            if ((p['period'] as num) >= ps && (p['period'] as num) <= ps + 2) {'id': p['period'], 'label': 'till ${p['end']}'}
        ];

        void change(VoidCallback fn) {
          setState(fn);
          reload();
        }

        return PageList(children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final day in days)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(day == days.first ? 'Today' : fmtDay(day)),
                    selected: f['date'] == day,
                    onSelected: (_) => change(() {
                      _date = day;
                      _ps ??= ps;
                      _pe ??= pe;
                    }),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OptionDropdown(
                label: 'From',
                options: periodOpts,
                value: ps,
                onChanged: (v) => change(() {
                  _date ??= f['date'] as String;
                  _ps = v as int;
                  _pe = v;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OptionDropdown(
                label: 'Until',
                options: endOpts,
                value: pe,
                onChanged: (v) => change(() {
                  _date ??= f['date'] as String;
                  _ps ??= ps;
                  _pe = v as int;
                }),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final t in [null, 'classroom', 'lab'])
              ChoiceChip(
                label: Text(t == null ? 'All rooms' : (t == 'lab' ? 'Labs' : 'Classrooms')),
                selected: _type == t,
                onSelected: (_) => change(() => _type = t),
              ),
          ]),
          SectionHeader('${free.length} free · ${f['day']} ${f['start_time']}-${f['end_time']}'),
          if (free.isEmpty) const EmptyState(icon: Icons.no_meeting_room_outlined, text: 'Every room is taken then'),
          for (final r in free)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.12),
                  child: Icon(r['type'] == 'lab' ? Icons.computer : Icons.chair_alt_outlined, color: Colors.green.shade700),
                ),
                title: Text(r['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${r['capacity']} seats · free until ${r['free_until'] ?? 'end of day'}\n${r['building'] ?? ''}'),
                isThreeLine: true,
              ),
            ),
          if (occupied.isNotEmpty)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text('${occupied.length} occupied'),
              children: [
                for (final r in occupied)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.block, color: cs.error, size: 18),
                    title: Text(r['name'] as String),
                    subtitle: Text((r['occupied_by'] as List).join(', ')),
                  ),
              ],
            ),
        ]);
      },
    );
  }
}
