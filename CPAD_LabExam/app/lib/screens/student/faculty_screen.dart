import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Professor availability with a virtual queue. Refreshes on pull and every 20 s (not live).
class FacultyScreen extends StatefulWidget {
  const FacultyScreen({super.key});

  @override
  State<FacultyScreen> createState() => _FacultyScreenState();
}

class _FacultyScreenState extends State<FacultyScreen> {
  String _q = '';
  String? _status;

  Future<Json> _load() async {
    final r = await Future.wait([Api.I.get('/professors'), Api.I.get('/queue/mine')]);
    return {'professors': r[0]['professors'], 'tokens': r[1]['tokens']};
  }

  Future<void> _join(Json p, Future<void> Function() reload) async {
    final purpose = await askText(context, 'Join ${p['name']}\'s queue',
        hint: 'What is it about? (optional)', ok: 'Get token');
    if (purpose == null || !mounted) return;
    var msg = '';
    final ok = await run(context, () async {
      final r = await Api.I.post('/queue/${p['id']}/join', {'purpose': purpose});
      final t = r['token'];
      msg = 'Token #${t['token_no']} · you are number ${t['position']} in line';
    });
    if (ok && mounted) {
      toast(context, msg);
      reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Loader(
      load: _load,
      pollEvery: const Duration(seconds: 20),
      builder: (context, d, reload) {
        final tokens = d['tokens'] as List;
        final tokenFor = {for (final t in tokens) t['professor_id']: t};
        var list = (d['professors'] as List).cast<Json>();
        if (_q.isNotEmpty) {
          list = list
              .where((p) => '${p['name']} ${p['code']} ${p['department']}'.toLowerCase().contains(_q.toLowerCase()))
              .toList();
        }
        if (_status != null) list = list.where((p) => p['status'] == _status).toList();

        return PageList(children: [
          TextField(
            decoration: const InputDecoration(hintText: 'Search professors', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: const Text('All'), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
              ),
              for (final e in statusStyles.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(e.value.icon, size: 16, color: e.value.color),
                    label: Text(e.value.label),
                    selected: _status == e.key,
                    onSelected: (_) => setState(() => _status = _status == e.key ? null : e.key),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty) const EmptyState(icon: Icons.person_search, text: 'No professors match'),
          for (final p in list)
            _ProfessorCard(p: p, token: tokenFor[p['id']], onJoin: () => _join(p, reload), onLeave: () async {
              final t = tokenFor[p['id']];
              if (await run(context, () => Api.I.delete('/queue/tokens/${t['id']}'), success: 'Left the queue')) reload();
            }),
        ]);
      },
    );
  }
}

class _ProfessorCard extends StatelessWidget {
  const _ProfessorCard({required this.p, required this.token, required this.onJoin, required this.onLeave});
  final Json p;
  final dynamic token;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = p['status'] as String;
    final style = statusStyles[status]!;
    final cur = p['current_class'];
    final next = p['next_class'];
    final waiting = (p['queue_waiting'] as num).toInt();
    final line = cur != null
        ? 'Teaching ${cur['label']} in ${cur['room'] ?? '-'} till ${cur['end_time']}'
        : (p['status_note'] as String?) ?? (next != null ? 'Next: ${next['label']} at ${next['start_time']}' : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Stack(children: [
                CircleAvatar(radius: 22, child: Text(p['code'] as String, style: const TextStyle(fontSize: 12))),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                        color: style.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('${p['department'] ?? ''} · ${p['cabin'] ?? ''}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ]),
              ),
              StatusPill(status),
            ]),
            if (line != null) ...[
              const SizedBox(height: 10),
              Text(line, style: TextStyle(color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.people_outline, size: 16, color: cs.outline),
              const SizedBox(width: 4),
              Expanded(
                child: Text(waiting == 0 ? 'No one waiting' : '$waiting waiting',
                    overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.outline, fontSize: 13)),
              ),
              if (token != null) ...[
                Pill(
                    token['status'] == 'serving' ? 'Your turn #${token['token_no']}' : '#${token['token_no']} · ${token['ahead']} ahead',
                    color: token['status'] == 'serving' ? Colors.green : cs.primary),
                TextButton(onPressed: onLeave, child: const Text('Leave')),
              ] else
                FilledButton.tonalIcon(
                  onPressed: status == 'on_leave' ? null : onJoin,
                  icon: const Icon(Icons.confirmation_num_outlined, size: 18),
                  label: const Text('Join queue'),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
