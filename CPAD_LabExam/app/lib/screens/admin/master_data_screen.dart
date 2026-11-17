import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/widgets.dart';
import '../shell.dart';

enum FType { text, number, toggle, ref, choice, multiRef }

/// One editable field. `options` is the key into /admin/options for ref fields.
class F {
  const F(this.key, this.label, this.type, {this.options, this.choices, this.optional = false, this.createOnly = false});
  final String key;
  final String label;
  final FType type;
  final String? options;
  final List<(Object, String)>? choices;
  final bool optional;
  final bool createOnly;
}

class Res {
  const Res(this.path, this.title, this.icon, this.fields, this.titleOf, this.subtitleOf);
  final String path;
  final String title;
  final IconData icon;
  final List<F> Function(Json values) fields;
  final String Function(Json) titleOf;
  final String Function(Json) subtitleOf;
}

const _days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

List<F> _userFields(Json v) => [
      const F('role', 'Role', FType.choice,
          choices: [('student', 'Student'), ('professor', 'Professor'), ('admin', 'Admin')], createOnly: true),
      const F('name', 'Full name', FType.text),
      const F('email', 'Email', FType.text),
      const F('phone', 'Phone', FType.text, optional: true),
      F('password', v['id'] == null ? 'Password' : 'New password (leave empty to keep)', FType.text, optional: v['id'] != null),
      if (v['role'] == 'student') ...const [
        F('section_id', 'Section', FType.ref, options: 'section_id'),
        F('roll_no', 'Roll number', FType.text),
      ],
      if (v['role'] == 'professor') ...const [
        F('code', 'Short code (e.g. PV)', FType.text),
        F('cabin', 'Cabin', FType.text, optional: true),
        F('department_id', 'Department', FType.ref, options: 'branch_id', optional: true),
      ],
      if (v['role'] == 'admin') ...const [
        F('title', 'Title (e.g. Hostel Warden)', FType.text),
        F('level', 'Escalation level', FType.choice, choices: [(1, '1 · Category handler'), (2, '2 · HOD'), (3, '3 · Dean')]),
        F('category_ids', 'Helpdesk categories handled', FType.multiRef, options: 'category_id', optional: true),
      ],
    ];

final resources = <Res>[
  Res('users', 'Users', Icons.people_outline, _userFields, (r) => '${r['name']}',
      (r) => '${r['role']} · ${r['email']}${r['section_label'] != null ? ' · ${r['section_label']}' : ''}${r['code'] != null ? ' · ${r['code']}' : ''}${r['title'] != null ? ' · ${r['title']}' : ''}'),
  Res('timetable_entries', 'Timetable', Icons.calendar_view_week_outlined, (_) => const [
        F('section_id', 'Section', FType.ref, options: 'section_id'),
        F('day', 'Day', FType.ref, options: 'day'),
        F('period_start', 'From period', FType.ref, options: 'period_start'),
        F('period_end', 'To period', FType.ref, options: 'period_end'),
        F('subject_id', 'Subject', FType.ref, options: 'subject_id'),
        F('professor_id', 'Professor', FType.ref, options: 'professor_id', optional: true),
        F('room_id', 'Room', FType.ref, options: 'room_id', optional: true),
        F('kind', 'Kind', FType.choice, choices: [('theory', 'Theory'), ('lab', 'Lab'), ('project', 'Project')]),
        F('label', 'Label shown (optional)', FType.text, optional: true),
        F('batch', 'Batch (optional)', FType.text, optional: true),
        F('parallel_group', 'Parallel group (optional)', FType.text, optional: true),
      ], (r) => '${r['section_label']} · ${_days[r['day'] as int]} P${r['period_start']}${r['period_end'] != r['period_start'] ? '-${r['period_end']}' : ''}',
      (r) => '${r['label'] ?? r['subject_code']} · ${r['professor_code'] ?? '-'} · ${r['room_name'] ?? '-'}'),
  Res('sections', 'Sections', Icons.groups_2_outlined, (_) => const [
        F('branch_id', 'Branch', FType.ref, options: 'branch_id'),
        F('year_id', 'Year', FType.ref, options: 'year_id'),
        F('name', 'Section name (e.g. A)', FType.text),
        F('strength', 'Strength (students)', FType.number),
      ], (r) => '${r['branch_code']} ${r['year_code']}-${r['name']}', (r) => '${r['strength']} strength · ${r['students']} in app'),
  Res('rooms', 'Rooms', Icons.meeting_room_outlined, (_) => const [
        F('name', 'Name', FType.text),
        F('type', 'Type', FType.choice, choices: [('classroom', 'Classroom'), ('lab', 'Lab')]),
        F('capacity', 'Capacity', FType.number),
        F('building', 'Building / floor', FType.text, optional: true),
        F('bookable', 'Students can book it', FType.toggle),
      ], (r) => '${r['name']}', (r) => '${r['type']} · ${r['capacity']} seats${r['bookable'] == true ? '' : ' · not bookable'}'),
  Res('subjects', 'Subjects', Icons.menu_book_outlined, (_) => const [
        F('code', 'Code', FType.text),
        F('name', 'Name', FType.text),
        F('branch_id', 'Branch', FType.ref, options: 'branch_id', optional: true),
      ], (r) => '${r['code']}', (r) => '${r['name']}${r['branch_code'] != null ? ' · ${r['branch_code']}' : ''}'),
  Res('professor_subjects', 'Teaching & backups', Icons.swap_horiz, (_) => const [
        F('professor_id', 'Professor', FType.ref, options: 'professor_id'),
        F('subject_id', 'Subject', FType.ref, options: 'subject_id'),
        F('is_backup', 'Backup teacher (exam helpline)', FType.toggle),
        F('rank', 'Backup rank (1 = first)', FType.number),
      ], (r) => '${r['subject_code']} · ${r['professor_name']}', (r) => r['is_backup'] == true ? 'Backup #${r['rank']}' : 'Assigned'),
  Res('branches', 'Branches', Icons.account_tree_outlined, (_) => const [
        F('code', 'Code', FType.text),
        F('name', 'Name', FType.text),
      ], (r) => '${r['code']}', (r) => '${r['name']}'),
  Res('years', 'Years', Icons.timeline, (_) => const [
        F('code', 'Code', FType.text),
        F('name', 'Name', FType.text),
        F('ord', 'Order', FType.number),
      ], (r) => '${r['code']}', (r) => '${r['name']}'),
  Res('ticket_categories', 'Helpdesk categories', Icons.category_outlined, (_) => const [
        F('code', 'Code', FType.text),
        F('name', 'Name', FType.text),
        F('sla_hours', 'Deadline (hours) before escalation', FType.number),
      ], (r) => '${r['name']}', (r) => 'Escalates after ${r['sla_hours']} h'),
];

class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: resources.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = resources[i];
        return MoreTile(
          icon: r.icon,
          title: r.title,
          subtitle: 'View, add, edit and delete',
          onTap: () => push(context, ResourceListScreen(res: r)),
        );
      },
    );
  }
}

class ResourceListScreen extends StatefulWidget {
  const ResourceListScreen({super.key, required this.res});
  final Res res;

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  final _key = GlobalKey<LoaderState>();
  String _q = '';

  Future<void> _edit(Json? row) async {
    final saved = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => ResourceFormScreen(res: widget.res, row: row)));
    if (saved == true) _key.currentState?.reload();
  }

  Future<void> _delete(Json row) async {
    if (!await confirm(context, 'Delete?', '${widget.res.titleOf(row)} will be removed.', ok: 'Delete')) return;
    if (!mounted) return;
    if (await run(context, () => Api.I.delete('/admin/${widget.res.path}/${row['id']}'), success: 'Deleted')) {
      _key.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: widget.res.title,
      fab: FloatingActionButton.extended(onPressed: () => _edit(null), icon: const Icon(Icons.add), label: const Text('Add')),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            decoration: const InputDecoration(hintText: 'Filter', prefixIcon: Icon(Icons.filter_list)),
            onChanged: (v) => setState(() => _q = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: Loader(
            key: _key,
            load: () => Api.I.get('/admin/${widget.res.path}'),
            builder: (context, d, _) {
              final rows = (d['rows'] as List).cast<Json>().where((r) {
                if (_q.isEmpty) return true;
                return '${widget.res.titleOf(r)} ${widget.res.subtitleOf(r)}'.toLowerCase().contains(_q);
              }).toList();
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                itemCount: rows.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text('${rows.length} records', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                    );
                  }
                  final r = rows[i - 1];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(widget.res.titleOf(r), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(widget.res.subtitleOf(r)),
                      onTap: () => _edit(r),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(r)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class ResourceFormScreen extends StatefulWidget {
  const ResourceFormScreen({super.key, required this.res, this.row});
  final Res res;
  final Json? row;

  @override
  State<ResourceFormScreen> createState() => _ResourceFormScreenState();
}

class _ResourceFormScreenState extends State<ResourceFormScreen> {
  late final Json _v = {
    if (widget.res.path == 'users') 'role': 'student',
    if (widget.res.path == 'rooms') 'bookable': true,
    if (widget.res.path == 'rooms') 'type': 'classroom',
    if (widget.res.path == 'timetable_entries') 'kind': 'theory',
    if (widget.res.path == 'professor_subjects') ...{'is_backup': false, 'rank': 1},
    ...?widget.row,
  };
  final _ctrls = <String, TextEditingController>{};
  bool _busy = false;

  TextEditingController _ctrl(String key) =>
      _ctrls.putIfAbsent(key, () => TextEditingController(text: key == 'password' ? '' : '${_v[key] ?? ''}'));

  Future<void> _save() async {
    final fields = widget.res.fields(_v);
    final body = <String, dynamic>{};
    for (final f in fields) {
      dynamic value;
      switch (f.type) {
        case FType.text:
          value = _ctrl(f.key).text.trim();
          if ('$value'.isEmpty) value = null;
        case FType.number:
          value = int.tryParse(_ctrl(f.key).text.trim());
        default:
          value = _v[f.key];
      }
      if (value == null && !f.optional) {
        toast(context, '${f.label} is required');
        return;
      }
      if (!(f.key == 'password' && value == null)) body[f.key] = value;
    }
    if (widget.res.path == 'users') body['role'] = _v['role'];
    setState(() => _busy = true);
    final id = widget.row?['id'];
    final ok = await run(context,
        () => id == null ? Api.I.post('/admin/${widget.res.path}', body) : Api.I.put('/admin/${widget.res.path}/$id', body),
        success: 'Saved');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.row != null;
    return SubPage(
      title: '${editing ? 'Edit' : 'Add'} ${widget.res.title.toLowerCase()}',
      child: Loader(
        load: () => Api.I.get('/admin/options'),
        builder: (context, opts, _) {
          final fields = widget.res.fields(_v);
          return PageList(children: [
            for (final f in fields)
              if (!(f.createOnly && editing))
                Padding(padding: const EdgeInsets.only(bottom: 12), child: _field(f, opts)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Save'),
            ),
          ]);
        },
      ),
    );
  }

  Widget _field(F f, Json opts) {
    switch (f.type) {
      case FType.text:
        return TextField(
          controller: _ctrl(f.key),
          obscureText: f.key == 'password',
          decoration: InputDecoration(labelText: f.label),
        );
      case FType.number:
        return TextField(
          controller: _ctrl(f.key),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: f.label),
        );
      case FType.toggle:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          value: _v[f.key] == true,
          onChanged: (b) => setState(() => _v[f.key] = b),
        );
      case FType.ref:
        return OptionDropdown(
          label: f.label,
          options: (opts[f.options] as List?) ?? const [],
          value: _v[f.key],
          allowNone: f.optional,
          noneLabel: 'None',
          onChanged: (v) => setState(() => _v[f.key] = v),
        );
      case FType.choice:
        return OptionDropdown(
          label: f.label,
          options: [for (final c in f.choices!) {'id': c.$1, 'label': c.$2}],
          value: _v[f.key],
          onChanged: (v) => setState(() => _v[f.key] = v),
        );
      case FType.multiRef:
        final selected = ((_v[f.key] as List?) ?? []).cast<dynamic>().toSet();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (final o in (opts[f.options] as List? ?? []))
              FilterChip(
                label: Text('${o['label']}'),
                selected: selected.contains(o['id']),
                onSelected: (b) => setState(() {
                  b ? selected.add(o['id']) : selected.remove(o['id']);
                  _v[f.key] = selected.toList();
                }),
              ),
          ]),
        ]);
    }
  }
}
