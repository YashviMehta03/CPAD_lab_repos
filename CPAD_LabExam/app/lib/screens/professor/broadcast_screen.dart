import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/widgets.dart';
import '../shell.dart';

enum _Mode { branch, year, section, students }

/// Targeted broadcast: branch, year (optionally within a branch), section, or hand-picked students.
class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  Json? _structure;
  _Mode _mode = _Mode.section;
  int? _branch;
  int? _year;
  int? _section;
  final _picked = <int, String>{};
  final _title = TextEditingController();
  final _body = TextEditingController();
  int? _reach;
  String? _reachLabel;
  bool _busy = false;
  final _historyKey = GlobalKey<LoaderState>();

  @override
  void initState() {
    super.initState();
    Api.I.get('/meta/structure').then((s) {
      if (mounted) setState(() => _structure = s);
    }).catchError((_) {});
  }

  Json get _target => switch (_mode) {
        _Mode.branch => {'branch_id': _branch, 'year_id': _year},
        _Mode.year => {'year_id': _year, 'branch_id': _branch},
        _Mode.section => {'section_id': _section},
        _Mode.students => {'student_ids': _picked.keys.toList()},
      };

  Future<void> _preview() async {
    setState(() => _reach = null);
    try {
      final r = await Api.I.post('/broadcasts/preview', _target);
      if (mounted) {
        setState(() {
          _reach = (r['recipients'] as num).toInt();
          _reachLabel = r['label'] as String?;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _reach = null);
    }
  }

  Future<void> _pickStudents() async {
    final picked = await Navigator.push<Map<int, String>>(
        context, MaterialPageRoute(builder: (_) => _StudentPicker(initial: Map.of(_picked), structure: _structure!)));
    if (picked != null) {
      setState(() {
        _picked
          ..clear()
          ..addAll(picked);
      });
      _preview();
    }
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    var n = 0;
    final ok = await run(context, () async {
      final r = await Api.I.post('/broadcasts', {..._target, 'title': _title.text, 'body': _body.text});
      n = (r['broadcast']['recipients'] as num).toInt();
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      toast(context, 'Sent to $n students');
      _title.clear();
      _body.clear();
      _historyKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_structure == null) return const SubPage(title: 'Broadcast', child: Center(child: CircularProgressIndicator()));
    final cs = Theme.of(context).colorScheme;
    final branches = [for (final b in _structure!['branches'] as List) {'id': b['id'], 'label': b['name']}];
    final years = [for (final y in _structure!['years'] as List) {'id': y['id'], 'label': y['name']}];
    final sections = [
      for (final s in _structure!['sections'] as List) {'id': s['id'], 'label': '${s['branch_code']} ${s['year_code']}-${s['name']}'}
    ];

    return SubPage(
      title: 'Broadcast',
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        SegmentedButton<_Mode>(
          segments: const [
            ButtonSegment(value: _Mode.branch, label: Text('Branch')),
            ButtonSegment(value: _Mode.year, label: Text('Year')),
            ButtonSegment(value: _Mode.section, label: Text('Section')),
            ButtonSegment(value: _Mode.students, label: Text('Pick')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) {
            setState(() {
              _mode = s.first;
              _reach = null;
            });
            _preview();
          },
        ),
        const SizedBox(height: 12),
        if (_mode == _Mode.branch) ...[
          OptionDropdown(label: 'Branch', options: branches, value: _branch, onChanged: (v) {
            setState(() => _branch = v as int?);
            _preview();
          }),
          const SizedBox(height: 10),
          OptionDropdown(label: 'Year (optional)', options: years, value: _year, allowNone: true, noneLabel: 'All years', onChanged: (v) {
            setState(() => _year = v as int?);
            _preview();
          }),
        ],
        if (_mode == _Mode.year) ...[
          OptionDropdown(label: 'Year', options: years, value: _year, onChanged: (v) {
            setState(() => _year = v as int?);
            _preview();
          }),
          const SizedBox(height: 10),
          OptionDropdown(label: 'Branch (optional)', options: branches, value: _branch, allowNone: true, noneLabel: 'All branches', onChanged: (v) {
            setState(() => _branch = v as int?);
            _preview();
          }),
        ],
        if (_mode == _Mode.section)
          OptionDropdown(label: 'Section', options: sections, value: _section, onChanged: (v) {
            setState(() => _section = v as int?);
            _preview();
          }),
        if (_mode == _Mode.students) ...[
          OutlinedButton.icon(
              onPressed: _pickStudents,
              icon: const Icon(Icons.person_add_alt),
              label: Text(_picked.isEmpty ? 'Choose students' : '${_picked.length} chosen · change')),
          if (_picked.isNotEmpty)
            Wrap(spacing: 6, children: [for (final n in _picked.values) Chip(label: Text(n), visualDensity: VisualDensity.compact)]),
        ],
        const SizedBox(height: 12),
        if (_reach != null)
          Card(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            child: ListTile(
              leading: Icon(Icons.groups, color: cs.primary),
              title: Text('Will reach $_reach students'),
              subtitle: _reachLabel != null && _reachLabel!.isNotEmpty ? Text(_reachLabel!) : null,
            ),
          ),
        const SizedBox(height: 12),
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
        const SizedBox(height: 10),
        TextField(controller: _body, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Message')),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy || (_reach ?? 0) == 0 ? null : _send,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          icon: const Icon(Icons.send),
          label: Text(_reach == null ? 'Choose who to send to' : 'Send to $_reach students'),
        ),
        const SectionHeader('Sent'),
        SizedBox(
          height: 360,
          child: Loader(
            key: _historyKey,
            load: () => Api.I.get('/broadcasts/sent'),
            builder: (context, d, _) {
              final list = d['broadcasts'] as List;
              return ListView(children: [
                if (list.isEmpty) const EmptyState(icon: Icons.campaign_outlined, text: 'Nothing sent yet'),
                for (final b in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.campaign_outlined),
                    title: Text(b['title'] as String),
                    subtitle: Text('${b['target']['label'] ?? ''} · ${b['recipients']} students · ${timeAgo(b['created_at'] as String)}'),
                  ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class _StudentPicker extends StatefulWidget {
  const _StudentPicker({required this.initial, required this.structure});
  final Map<int, String> initial;
  final Json structure;

  @override
  State<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends State<_StudentPicker> {
  late final Map<int, String> _picked = widget.initial;
  int? _section;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final sections = [
      for (final s in widget.structure['sections'] as List) {'id': s['id'], 'label': '${s['branch_code']} ${s['year_code']}-${s['name']}'}
    ];
    return Scaffold(
      appBar: AppBar(title: Text('${_picked.length} chosen'), actions: [
        TextButton(onPressed: () => Navigator.pop(context, _picked), child: const Text('Done')),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(children: [
            OptionDropdown(
                label: 'Section', options: sections, value: _section, allowNone: true, noneLabel: 'All sections',
                onChanged: (v) => setState(() => _section = v as int?)),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(hintText: 'Search by name or roll no', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ]),
        ),
        Expanded(
          child: Loader(
            key: ValueKey('$_section-$_q'),
            load: () => Api.I.get('/broadcasts/students', query: {'section_id': _section, 'q': _q}),
            builder: (context, d, _) => ListView(children: [
              for (final s in d['students'] as List)
                CheckboxListTile(
                  value: _picked.containsKey(s['id']),
                  title: Text(s['name'] as String),
                  subtitle: Text('${s['roll_no']} · ${s['section']}'),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _picked[s['id'] as int] = s['name'] as String;
                    } else {
                      _picked.remove(s['id']);
                    }
                  }),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
