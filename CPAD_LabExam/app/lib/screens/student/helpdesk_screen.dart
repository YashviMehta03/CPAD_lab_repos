import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../shell.dart';

const levelNames = {1: 'Handler', 2: 'HOD', 3: 'Dean'};

/// Student: my tickets + report a new issue.
class HelpdeskScreen extends StatefulWidget {
  const HelpdeskScreen({super.key});

  @override
  State<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _HelpdeskScreenState extends State<HelpdeskScreen> {
  final _key = GlobalKey<LoaderState>();

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Helpdesk',
      fab: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const NewTicketScreen()));
          if (created == true) _key.currentState?.reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Report issue'),
      ),
      child: Loader(
        key: _key,
        load: () => Api.I.get('/tickets/mine'),
        pollEvery: const Duration(seconds: 30),
        builder: (context, d, reload) {
          final tickets = d['tickets'] as List;
          return PageList(children: [
            if (tickets.isEmpty) const EmptyState(icon: Icons.task_alt, text: 'No issues reported. Tap Report issue if something is broken.'),
            for (final t in tickets) TicketCard(t: t as Json, onChanged: reload),
          ]);
        },
      ),
    );
  }
}

class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.t, required this.onChanged, this.showStudent = false});
  final Json t;
  final Future<void> Function() onChanged;
  final bool showStudent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final open = t['status'] == 'open' || t['status'] == 'in_progress';
    final level = (t['escalation_level'] as num).toInt();
    final overdue = open && DateTime.parse(t['due_at'] as String).isBefore(DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(id: t['id'] as int)));
            onChanged();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              if (t['photo_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(Api.I.absolute(t['photo_url'] as String),
                      width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox(width: 56)),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.build_outlined, color: cs.outline),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('#${t['id']} ${t['title']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      t['category_name'],
                      t['location'],
                      if (showStudent) '${t['student_name']}',
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    StatusPill(t['status'] as String, styles: ticketStatusStyles, dense: true),
                    if (level > 1) Pill('With ${levelNames[level]}', color: Colors.deepPurple, icon: Icons.trending_up, dense: true),
                    if (open)
                      Pill(dueText(t['due_at'] as String), color: overdue ? cs.error : cs.outline, icon: Icons.timer_outlined, dense: true),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  int? _category;
  Uint8List? _photo;
  String? _photoName;
  bool _busy = false;

  Future<void> _pick(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 80);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() {
        _photo = bytes;
        _photoName = x.name;
      });
    } catch (e) {
      if (mounted) toast(context, 'Could not get the photo: $e');
    }
  }

  Future<void> _submit() async {
    if (_category == null) {
      toast(context, 'Choose a category');
      return;
    }
    setState(() => _busy = true);
    final ok = await run(context, () => Api.I.multipart('/tickets', {
          'category_id': '$_category',
          'title': _title.text,
          'description': _desc.text,
          'location': _location.text,
        }, fileBytes: _photo, fileName: _photoName), success: 'Issue reported. You will be notified of updates.');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SubPage(
      title: 'Report an issue',
      child: Loader(
        load: () => Api.I.get('/tickets/categories'),
        builder: (context, d, _) {
          final cats = (d['categories'] as List)
              .map((c) => {'id': c['id'], 'label': '${c['name']} (fixed within ${c['sla_hours']} h)'})
              .toList();
          return PageList(children: [
            OptionDropdown(label: 'Category', options: cats, value: _category, onChanged: (v) => setState(() => _category = v as int?)),
            const SizedBox(height: 12),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'What is wrong?', hintText: 'e.g. Fan not working')),
            const SizedBox(height: 12),
            TextField(
                controller: _location,
                decoration: const InputDecoration(
                    labelText: 'Where?', hintText: 'e.g. AL 202, or Boys Hostel B Room 214', prefixIcon: Icon(Icons.place_outlined))),
            const SizedBox(height: 12),
            TextField(controller: _desc, maxLines: 4, decoration: const InputDecoration(labelText: 'Details (optional)')),
            const SizedBox(height: 16),
            if (_photo != null)
              Stack(children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(_photo!, height: 200, width: double.infinity, fit: BoxFit.cover)),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton.filled(onPressed: () => setState(() => _photo = null), icon: const Icon(Icons.close)),
                ),
              ])
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Icon(Icons.add_a_photo_outlined, color: cs.outline, size: 32),
                  const SizedBox(height: 8),
                  const Text('Add a photo so they know what to fix'),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Camera')),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery')),
                  ]),
                ]),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
              label: const Text('Submit'),
            ),
          ]);
        },
      ),
    );
  }
}

/// Ticket detail with photo and timeline. Admins also get status and escalate actions.
class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.id});
  final int id;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _key = GlobalKey<LoaderState>();

  Future<void> _setStatus(String status) async {
    final note = await askText(context, 'Set to ${ticketStatusStyles[status]!.label}', hint: 'Note for the student (optional)');
    if (note == null || !mounted) return;
    if (await run(context, () => Api.I.post('/tickets/${widget.id}/status', {'status': status, 'note': note}),
        success: 'Updated, the student is notified')) {
      _key.currentState?.reload();
    }
  }

  Future<void> _escalate() async {
    final note = await askText(context, 'Escalate one level up', hint: 'Why? (optional)', ok: 'Escalate');
    if (note == null || !mounted) return;
    if (await run(context, () => Api.I.post('/tickets/${widget.id}/escalate', {'note': note}), success: 'Escalated')) {
      _key.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Session.I.role == 'admin';
    return SubPage(
      title: 'Ticket #${widget.id}',
      child: Loader(
        key: _key,
        load: () => Api.I.get('/tickets/${widget.id}'),
        builder: (context, d, reload) {
          final cs = Theme.of(context).colorScheme;
          final t = d['ticket'] as Json;
          final events = d['events'] as List;
          final level = (t['escalation_level'] as num).toInt();
          final open = t['status'] == 'open' || t['status'] == 'in_progress';
          return PageList(children: [
            if (t['photo_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(Api.I.absolute(t['photo_url'] as String),
                    height: 220, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(height: 60, child: Center(child: Text('Photo unavailable')))),
              ),
            const SizedBox(height: 14),
            Text(t['title'] as String, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              StatusPill(t['status'] as String, styles: ticketStatusStyles),
              Pill(t['category_name'] as String, color: cs.primary, icon: Icons.label_outline),
              Pill('Level $level · ${levelNames[level]}', color: Colors.deepPurple, icon: Icons.trending_up),
              if (open) Pill(dueText(t['due_at'] as String), color: cs.outline, icon: Icons.timer_outlined),
            ]),
            const SizedBox(height: 12),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.place_outlined), title: Text(t['location'] as String)),
            if (isAdmin)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text('${t['student_name']}'),
                  subtitle: Text('${t['roll_no'] ?? ''}')),
            if (t['description'] != null) Text(t['description'] as String),
            if (isAdmin && open) ...[
              const SectionHeader('Actions'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (t['status'] != 'in_progress')
                  FilledButton.tonalIcon(onPressed: () => _setStatus('in_progress'), icon: const Icon(Icons.timelapse), label: const Text('In progress')),
                FilledButton.icon(onPressed: () => _setStatus('resolved'), icon: const Icon(Icons.check), label: const Text('Resolved')),
                OutlinedButton.icon(onPressed: () => _setStatus('rejected'), icon: const Icon(Icons.block), label: const Text('Reject')),
                if (level < 3)
                  OutlinedButton.icon(
                      onPressed: _escalate, icon: const Icon(Icons.trending_up), label: Text('Escalate to ${levelNames[level + 1]}')),
              ]),
            ],
            if (isAdmin && !open) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: () => _setStatus('open'), icon: const Icon(Icons.replay), label: const Text('Reopen')),
            ],
            const SectionHeader('Timeline'),
            for (var i = 0; i < events.length; i++)
              _TimelineRow(e: events[i] as Json, last: i == events.length - 1),
          ]);
        },
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.e, required this.last});
  final Json e;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auto = e['type'] == 'auto_escalated';
    final color = switch (e['type']) {
      'created' => cs.primary,
      'auto_escalated' || 'escalated' => Colors.deepPurple,
      _ => Colors.teal,
    };
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          if (!last) Expanded(child: Container(width: 2, color: cs.outlineVariant)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e['note'] ?? e['type']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                [
                  auto ? 'Automatic' : (e['actor_title'] ?? e['actor_name'] ?? ''),
                  fmtDateTime(e['created_at'] as String),
                ].where((s) => '$s'.isNotEmpty).join(' · '),
                style: TextStyle(color: cs.outline, fontSize: 12),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
