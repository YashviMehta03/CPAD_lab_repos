import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/widgets.dart';

/// Own timetable (section for students, own classes for professors) plus read-only browsing of any section.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  bool _browse = false;
  int? _sectionId;
  int _day = 0;
  Json? _structure;

  @override
  void initState() {
    super.initState();
    Api.I.get('/meta/structure').then((s) {
      if (!mounted) return;
      final dow = (s['now']['dow'] as num).toInt();
      setState(() {
        _structure = s;
        _day = dow <= 5 ? dow : 1;
        _sectionId = (s['sections'] as List).first['id'] as int;
      });
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (_structure == null) return const Center(child: CircularProgressIndicator());
    final sections = (_structure!['sections'] as List)
        .map((s) => {'id': s['id'], 'label': '${s['branch_code']} ${s['year_code']}-${s['name']}'})
        .toList();
    final path = _browse ? '/timetable/section/$_sectionId' : '/timetable/me';
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false,
                    label: Text(Session.I.role == 'professor' ? 'My classes' : 'My section'),
                    icon: const Icon(Icons.person_outline)),
                const ButtonSegment(value: true, label: Text('Browse'), icon: Icon(Icons.travel_explore)),
              ],
              selected: {_browse},
              onSelectionChanged: (s) => setState(() => _browse = s.first),
            ),
          ),
          if (_browse) ...[
            const SizedBox(height: 10),
            OptionDropdown(
              label: 'Branch, year and section',
              options: sections,
              value: _sectionId,
              onChanged: (v) => setState(() => _sectionId = v as int),
            ),
          ],
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (var d = 1; d <= 5; d++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(dayShort[d]),
                    selected: _day == d,
                    onSelected: (_) => setState(() => _day = d),
                  ),
                ),
            ]),
          ),
        ]),
      ),
      Expanded(
        child: Loader(
          key: ValueKey(path),
          load: () => Api.I.get(path),
          builder: (context, data, reload) => _DayView(data: data, day: _day, browsing: _browse),
        ),
      ),
    ]);
  }
}

class _DayView extends StatelessWidget {
  const _DayView({required this.data, required this.day, required this.browsing});
  final Json data;
  final int day;
  final bool browsing;

  @override
  Widget build(BuildContext context) {
    final periods = {for (final p in data['periods'] as List) p['period']: p};
    final week = data['week'] as Json;
    final date = isoDay(parseDay(week['from'] as String).add(Duration(days: day - 1)));
    final items = (week['occurrences'] as List).where((o) => o['date'] == date).toList();
    final section = data['section'] as Json?;
    final isProf = Session.I.role == 'professor' && !browsing;

    return PageList(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(
          [
            fmtDayLong(date),
            if (section != null) '${section['branch_code']} ${section['year_code']}-${section['name']}',
          ].join('  ·  '),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      if (items.isEmpty) const EmptyState(icon: Icons.free_breakfast_outlined, text: 'No classes on this day'),
      ..._grouped(items.cast<Json>(), periods, isProf, context),
    ]);
  }
}

/// Classes sharing a parallel group (electives, batches) run at the same time: show them as one
/// block instead of looking like the student has several classes at once.
List<Widget> _grouped(List<Json> items, Map periods, bool showSection, BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final out = <Widget>[];
  final done = <String>{};
  for (final o in items) {
    final g = o['parallel_group'] as String?;
    final same = g == null ? <Json>[o] : items.where((x) => x['parallel_group'] == g).toList();
    if (same.length < 2) {
      out.add(OccurrenceCard(o: o, periods: periods, showSection: showSection));
      continue;
    }
    if (!done.add(g!)) continue;
    final start = periods[same.first['period_start']]?['start'] ?? '';
    final end = periods[same.first['period_end']]?['end'] ?? '';
    final batches = same.every((x) => x['batch'] != null);
    out.add(Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(children: [
              Icon(Icons.call_split, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text('$start - $end  ·  ${batches ? 'Batches run in parallel' : 'Pick one (parallel options)'}',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
          ),
          for (final x in same) OccurrenceCard(o: x, periods: periods, showSection: showSection),
        ]),
      ),
    ));
  }
  return out;
}

/// One class on one day, with cancelled / moved states.
class OccurrenceCard extends StatelessWidget {
  const OccurrenceCard({super.key, required this.o, required this.periods, this.showSection = false, this.trailing});
  final Json o;
  final Map<dynamic, dynamic> periods;
  final bool showSection;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = o['status'] as String;
    final inactive = status == 'cancelled' || status == 'moved_away';
    final start = periods[o['period_start']]?['start'] ?? '';
    final end = periods[o['period_end']]?['end'] ?? '';
    final kindColor = switch (o['kind']) { 'lab' => Colors.purple, 'project' => Colors.teal, _ => cs.primary };
    final title = (o['label'] as String?) ?? o['subject_name'] as String;
    final details = [
      if (o['room_name'] != null) o['room_name'],
      if (o['professor_name'] != null && !showSection) o['professor_name'],
      if (showSection) '${o['branch_code']} ${o['year_code']}-${o['section_name']}',
      if (o['batch'] != null) o['batch'],
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: inactive ? 0.6 : 1,
        child: Card(
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: inactive ? cs.outline : kindColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
              SizedBox(
                width: 64,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(start, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(end, style: TextStyle(fontSize: 12, color: cs.outline)),
                ]),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text(title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              decoration: inactive ? TextDecoration.lineThrough : null,
                            )),
                      ),
                      if (o['kind'] == 'lab') ...[
                        const SizedBox(width: 6),
                        Pill('Lab', color: Colors.purple, dense: true),
                      ],
                    ]),
                    if (o['label'] != null && o['label'] != o['subject_name'])
                      Text(o['subject_name'] as String, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(details, style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                    if (status != 'scheduled') ...[
                      const SizedBox(height: 6),
                      _changeBadge(status),
                    ],
                  ]),
                ),
              ),
              if (trailing != null) Center(child: trailing),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _changeBadge(String status) {
    switch (status) {
      case 'cancelled':
        return Pill('Cancelled${o['reason'] != null ? ': ${o['reason']}' : ''}', color: Colors.red, icon: Icons.block, dense: true);
      case 'moved_away':
        final to = periods[o['new_period_start']]?['start'] ?? '';
        return Pill('Moved to ${fmtDay(o['new_date'] as String)}, $to${o['new_room_name'] != null ? ' in ${o['new_room_name']}' : ''}',
            color: Colors.orange.shade800, icon: Icons.east, dense: true);
      default:
        return Pill('Rescheduled from ${fmtDay(o['original_date'] as String)}', color: Colors.green.shade700,
            icon: Icons.event_available, dense: true);
    }
  }
}
