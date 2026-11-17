import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/widgets.dart';

/// Professor's virtual queue: call next, complete or skip. Refreshes on pull and every 15 s.
class QueueManageScreen extends StatefulWidget {
  const QueueManageScreen({super.key});

  @override
  State<QueueManageScreen> createState() => _QueueManageScreenState();
}

class _QueueManageScreenState extends State<QueueManageScreen> {
  final _key = GlobalKey<LoaderState>();
  bool _busy = false;

  Future<void> _act(Future<void> Function() fn, {String? success}) async {
    setState(() => _busy = true);
    await run(context, fn, success: success);
    await _key.currentState?.reload();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Loader(
      key: _key,
      load: () => Api.I.get('/queue/manage'),
      pollEvery: const Duration(seconds: 15),
      builder: (context, d, reload) {
        final cs = Theme.of(context).colorScheme;
        final serving = d['serving'] as Json?;
        final waiting = d['waiting'] as List;
        final finished = d['finished'] as List;

        return PageList(children: [
          Card(
            color: serving != null ? Colors.green.withValues(alpha: 0.1) : null,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                Text(serving != null ? 'Now with you' : 'No one with you', style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                if (serving != null) ...[
                  Text('#${serving['token_no']}', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.green)),
                  Text(serving['student_name'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('${serving['roll_no']} · ${serving['branch_code']} ${serving['year_code']}-${serving['section_name']}',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  if (serving['purpose'] != null && '${serving['purpose']}'.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('"${serving['purpose']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _act(() => Api.I.post('/queue/manage/tokens/${serving['id']}/skip')),
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : () => _act(() => Api.I.post('/queue/manage/tokens/${serving['id']}/complete')),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ]),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy || waiting.isEmpty ? null : () => _act(() => Api.I.post('/queue/manage/next')),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: const Icon(Icons.campaign_outlined),
                  label: Text(waiting.isEmpty
                      ? 'Queue is empty'
                      : serving != null
                          ? 'Done, call next (#${waiting.first['token_no']})'
                          : 'Call next (#${waiting.first['token_no']})'),
                ),
              ]),
            ),
          ),
          SectionHeader('Waiting (${waiting.length})'),
          if (waiting.isEmpty) const EmptyState(icon: Icons.event_seat_outlined, text: 'Nobody is waiting'),
          for (final t in waiting)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text('#${t['token_no']}', style: const TextStyle(fontSize: 13))),
                title: Text(t['student_name'] as String),
                subtitle: Text([
                  '${t['branch_code']} ${t['year_code']}-${t['section_name']}',
                  if (t['purpose'] != null && '${t['purpose']}'.isNotEmpty) t['purpose'],
                  'joined ${timeAgo(t['created_at'] as String)}',
                ].join(' · ')),
                trailing: IconButton(
                  tooltip: 'Skip',
                  onPressed: _busy ? null : () => _act(() => Api.I.post('/queue/manage/tokens/${t['id']}/skip')),
                  icon: const Icon(Icons.skip_next),
                ),
              ),
            ),
          if (finished.isNotEmpty) ...[
            SectionHeader('Seen today (${finished.length})'),
            for (final t in finished)
              ListTile(
                dense: true,
                leading: Icon(
                  t['status'] == 'done' ? Icons.check_circle : (t['status'] == 'skipped' ? Icons.skip_next : Icons.logout),
                  color: t['status'] == 'done' ? Colors.green : cs.outline,
                ),
                title: Text('#${t['token_no']} ${t['student_name']}'),
                trailing: Text(t['status'] as String, style: TextStyle(color: cs.outline)),
              ),
          ],
        ]);
      },
    );
  }
}
