import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Exam helpline (professors only): the assigned teacher first, with status and a call button, then ranked backups.
class HelplineScreen extends StatefulWidget {
  const HelplineScreen({super.key});

  @override
  State<HelplineScreen> createState() => _HelplineScreenState();
}

class _HelplineScreenState extends State<HelplineScreen> {
  Json? _structure;
  int? _branch;
  int? _year;
  String _q = '';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    Api.I.get('/meta/structure').then((s) {
      if (mounted) setState(() => _structure = s);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (_structure == null) return const Center(child: CircularProgressIndicator());
    final branches = [for (final b in _structure!['branches'] as List) {'id': b['id'], 'label': b['code']}];
    final years = [for (final y in _structure!['years'] as List) {'id': y['id'], 'label': y['code']}];
    final key = '$_branch-$_year-$_q';
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: OptionDropdown(
                  label: 'Branch', options: branches, value: _branch, allowNone: true, onChanged: (v) => setState(() => _branch = v as int?)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OptionDropdown(
                  label: 'Year', options: years, value: _year, allowNone: true, onChanged: (v) => setState(() => _year = v as int?)),
            ),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => setState(() => _q = v.trim()),
            decoration: InputDecoration(
              hintText: 'Subject, e.g. Data Management or DM',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => setState(() => _q = _search.text.trim())),
            ),
          ),
        ]),
      ),
      Expanded(
        child: Loader(
          key: ValueKey(key),
          load: () => Api.I.get('/helpline', query: {'branch_id': _branch, 'year_id': _year, 'q': _q}),
          builder: (context, d, _) {
            final subjects = d['subjects'] as List;
            if (subjects.isEmpty) {
              return PageList(children: const [EmptyState(icon: Icons.search_off, text: 'No subject matches. Try another branch, year or name.')]);
            }
            return PageList(children: [for (final s in subjects) _SubjectCard(s: s as Json)]);
          },
        ),
      ),
    ]);
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.s});
  final Json s;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final assigned = s['assigned'] as List;
    final backups = s['backups'] as List;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Pill(s['code'] as String, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            ]),
            const SizedBox(height: 10),
            Text('ASSIGNED', style: TextStyle(fontSize: 11, letterSpacing: 1, color: cs.outline, fontWeight: FontWeight.w700)),
            if (assigned.isEmpty) const Text('No assigned teacher in the timetable'),
            for (final p in assigned) _PersonRow(p: p as Json, primary: true),
            if (backups.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('BACKUPS', style: TextStyle(fontSize: 11, letterSpacing: 1, color: cs.outline, fontWeight: FontWeight.w700)),
              for (var i = 0; i < backups.length; i++) _PersonRow(p: backups[i] as Json, rank: i + 1),
            ],
          ]),
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.p, this.primary = false, this.rank});
  final Json p;
  final bool primary;
  final int? rank;

  Future<void> _call(BuildContext context) async {
    final phone = (p['phone'] as String?)?.replaceAll(' ', '');
    if (phone == null) return;
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok && context.mounted) toast(context, 'Could not open the dialer. Number: ${p['phone']}');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cur = p['current_class'];
    final sub = [
      if (cur != null) 'In ${cur['room']} till ${cur['end_time']}' else p['cabin'],
      if (p['sections'] != null) (p['sections'] as List).join(', '),
      if (p['reason'] != null) p['reason'],
      if (p['phone'] != null) p['phone'],
    ].whereType<String>().join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        CircleAvatar(
          radius: primary ? 22 : 18,
          backgroundColor: primary ? cs.primaryContainer : cs.surfaceContainerHigh,
          child: Text(rank != null ? '$rank' : p['code'] as String, style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(p['name'] as String, style: TextStyle(fontWeight: primary ? FontWeight.w700 : FontWeight.w600))),
              const SizedBox(width: 6),
              StatusPill(p['status'] as String, styles: statusStyles, dense: true),
            ]),
            Text(sub, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ]),
        ),
        IconButton.filledTonal(
          tooltip: 'Call',
          onPressed: p['phone'] == null ? null : () => _call(context),
          icon: const Icon(Icons.call),
        ),
      ]),
    );
  }
}
