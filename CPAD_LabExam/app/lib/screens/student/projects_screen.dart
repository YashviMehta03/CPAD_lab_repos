import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../shell.dart';

String slotLabel(Map periods, String date, int period) => '${fmtDay(date)}, ${periods[period]?['start'] ?? 'P$period'}';

/// Student: my project group(s), meeting history, and request a meeting at a time everyone is free.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  Future<Json> _load() async {
    final r = await Future.wait([Api.I.get('/meetings/groups'), Api.I.get('/meetings')]);
    return {'groups': r[0]['groups'], 'meetings': r[1]['meetings'], 'periods': r[1]['periods']};
  }

  @override
  Widget build(BuildContext context) {
    final loaderKey = GlobalKey<LoaderState>();
    Future<void> newGroup() async {
      final made = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
      if (made == true) loaderKey.currentState?.reload();
    }

    return SubPage(
      title: 'Project meetings',
      actions: [IconButton(tooltip: 'New group', onPressed: newGroup, icon: const Icon(Icons.group_add_outlined))],
      fab: FloatingActionButton.extended(
        onPressed: newGroup,
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('New group'),
      ),
      child: Loader(
        key: loaderKey,
        load: _load,
        pollEvery: const Duration(seconds: 30),
        builder: (context, d, reload) {
          final cs = Theme.of(context).colorScheme;
          final groups = d['groups'] as List;
          final meetings = d['meetings'] as List;
          final periods = {for (final p in d['periods'] as List) p['period']: p};
          if (groups.isEmpty) {
            return PageList(children: [
              EmptyState(
                icon: Icons.groups_outlined,
                text: 'You are not in a project group yet.',
                action: FilledButton.icon(
                  onPressed: newGroup,
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Create a group'),
                ),
              ),
            ]);
          }
          return PageList(children: [
            for (final g in groups) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(g['name'] as String, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    if (g['title'] != null) Text(g['title'] as String, style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.person_outline, size: 18, color: cs.primary),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Guide: ${g['guide_name']} · ${g['guide_cabin'] ?? ''}')),
                    ]),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final m in (g['members'] as List? ?? [])) Chip(label: Text(m['name'] as String), visualDensity: VisualDensity.compact),
                    ]),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          if (await confirm(context, 'Leave ${g['name']}?', 'You will no longer see this group or its meetings.', ok: 'Leave') &&
                              context.mounted &&
                              await run(context, () => Api.I.delete('/meetings/groups/${g['id']}/members/me'))) {
                            reload();
                          }
                        },
                        child: const Text('Leave group'),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        final sent = await Navigator.push<bool>(
                            context, MaterialPageRoute(builder: (_) => RequestMeetingScreen(group: g as Json)));
                        if (sent == true) reload();
                      },
                      icon: const Icon(Icons.event_available),
                      label: const Text('Request a meeting'),
                    ),
                  ]),
                ),
              ),
              const SectionHeader('Requests'),
              for (final m in meetings.where((m) => m['group_id'] == g['id']))
                MeetingCard(m: m as Json, periods: periods, actions: [
                  if (m['status'] == 'suggested') ...[
                    FilledButton(
                      onPressed: () async {
                        if (await run(context, () => Api.I.post('/meetings/${m['id']}/suggestion', {'accept': true}),
                            success: 'Meeting confirmed')) {
                          reload();
                        }
                      },
                      child: const Text('Accept new time'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        if (await run(context, () => Api.I.post('/meetings/${m['id']}/suggestion', {'accept': false}))) reload();
                      },
                      child: const Text('Decline'),
                    ),
                  ],
                ]),
              if (!meetings.any((m) => m['group_id'] == g['id']))
                const EmptyState(icon: Icons.event_note_outlined, text: 'No meeting requests yet'),
            ],
          ]);
        },
      ),
    );
  }
}

class MeetingCard extends StatelessWidget {
  const MeetingCard({super.key, required this.m, required this.periods, this.actions = const [], this.showGroup = false});
  final Json m;
  final Map periods;
  final List<Widget> actions;
  final bool showGroup;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(showGroup ? '${m['group_name']}' : slotLabel(periods, m['date'] as String, (m['period'] as num).toInt()),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              StatusPill(m['status'] as String, styles: meetingStatusStyles, dense: true),
            ]),
            if (showGroup) ...[
              const SizedBox(height: 2),
              Text('${m['group_title'] ?? ''}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.schedule, size: 16, color: cs.primary),
                const SizedBox(width: 4),
                Text(slotLabel(periods, m['date'] as String, (m['period'] as num).toInt())),
              ]),
            ],
            const SizedBox(height: 6),
            Text(m['agenda'] as String),
            const SizedBox(height: 4),
            Text('Requested by ${m['requested_by_name']} · ${timeAgo(m['created_at'] as String)}',
                style: TextStyle(color: cs.outline, fontSize: 12)),
            if (m['status'] == 'suggested' && m['suggested_date'] != null) ...[
              const SizedBox(height: 8),
              Pill('Suggested: ${slotLabel(periods, m['suggested_date'] as String, (m['suggested_period'] as num).toInt())}',
                  color: Colors.orange.shade800, icon: Icons.schedule),
            ],
            if (m['professor_note'] != null) ...[
              const SizedBox(height: 8),
              Text('Note: ${m['professor_note']}', style: TextStyle(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ]),
        ),
      ),
    );
  }
}

class RequestMeetingScreen extends StatefulWidget {
  const RequestMeetingScreen({super.key, required this.group});
  final Json group;

  @override
  State<RequestMeetingScreen> createState() => _RequestMeetingScreenState();
}

class _RequestMeetingScreenState extends State<RequestMeetingScreen> {
  Json? _slot;
  final _agenda = TextEditingController();
  bool _busy = false;

  Future<void> _send() async {
    if (_slot == null) {
      toast(context, 'Pick a time');
      return;
    }
    setState(() => _busy = true);
    final ok = await run(context, () => Api.I.post('/meetings', {
          'group_id': widget.group['id'],
          'date': _slot!['date'],
          'period': _slot!['period'],
          'agenda': _agenda.text,
        }), success: 'Request sent to ${widget.group['guide_name']}');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Request a meeting',
      child: Loader(
        load: () => Api.I.get('/meetings/groups/${widget.group['id']}/slots'),
        builder: (context, d, _) {
          final cs = Theme.of(context).colorScheme;
          final slots = (d['slots'] as List).cast<Json>();
          final byDay = <String, List<Json>>{};
          for (final s in slots) {
            byDay.putIfAbsent(s['date'] as String, () => []).add(s);
          }
          return PageList(children: [
            Card(
              color: cs.primaryContainer.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Icon(Icons.auto_awesome, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'These are times when every member\'s class and ${widget.group['guide_name']} are free, from the timetable.'),
                  ),
                ]),
              ),
            ),
            if (slots.isEmpty) const EmptyState(icon: Icons.event_busy, text: 'No common free time this week'),
            for (final e in byDay.entries) ...[
              SectionHeader(fmtDayLong(e.key)),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in e.value)
                  ChoiceChip(
                    label: Text('${s['start_time']} - ${s['end_time']}'),
                    selected: _slot == s,
                    onSelected: (_) => setState(() => _slot = s),
                  ),
              ]),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _agenda,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Agenda', hintText: 'What do you want to discuss?'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _send,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.send),
              label: const Text('Send request'),
            ),
          ]);
        },
      ),
    );
  }
}

/// Start a project group: name, guide professor and classmates (searched by name or roll number).
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _search = TextEditingController();
  final _members = <int, Json>{};
  List<Json> _professors = [];
  List<Json> _results = [];
  int? _guide;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Api.I.get('/professors').then((r) {
      if (mounted) setState(() => _professors = (r['professors'] as List).cast<Json>());
    }).catchError((_) {});
  }

  Future<void> _find(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    try {
      final r = await Api.I.get('/meetings/students', query: {'q': q.trim()});
      if (mounted && _search.text.trim() == q.trim()) setState(() => _results = (r['students'] as List).cast<Json>());
    } catch (_) {}
  }

  Future<void> _create() async {
    if (_name.text.trim().length < 2) return toast(context, 'Give the group a name');
    if (_guide == null) return toast(context, 'Pick a guide professor');
    setState(() => _busy = true);
    final ok = await run(
        context,
        () => Api.I.post('/meetings/groups', {
              'name': _name.text.trim(),
              'title': _title.text.trim(),
              'guide_id': _guide,
              'member_ids': _members.keys.toList(),
            }),
        success: 'Group created');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('New project group')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Group name', prefixIcon: Icon(Icons.groups_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'Project title (optional)', prefixIcon: Icon(Icons.title))),
        const SizedBox(height: 12),
        OptionDropdown(
          label: 'Guide professor',
          options: [for (final p in _professors) {'id': p['id'], 'label': '${p['name']} (${p['code']})'}],
          value: _guide,
          onChanged: (v) => setState(() => _guide = v as int),
        ),
        const SectionHeader('Members'),
        Text('You are added automatically. Search classmates by name or roll number.', style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        if (_members.isNotEmpty)
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final m in _members.values)
              InputChip(label: Text(m['name'] as String), onDeleted: () => setState(() => _members.remove(m['id']))),
          ]),
        const SizedBox(height: 8),
        TextField(
          controller: _search,
          onChanged: _find,
          decoration: const InputDecoration(hintText: 'Search students', prefixIcon: Icon(Icons.search)),
        ),
        for (final s in _results.where((s) => !_members.containsKey(s['id'])))
          ListTile(
            dense: true,
            title: Text(s['name'] as String),
            subtitle: Text('${s['roll_no']} · ${s['section']}'),
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () => setState(() {
              _members[s['id'] as int] = s;
              _search.clear();
              _results = [];
            }),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _create,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('Create group'),
        ),
      ]),
    );
  }
}
