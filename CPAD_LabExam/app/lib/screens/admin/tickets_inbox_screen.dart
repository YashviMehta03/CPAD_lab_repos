import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/widgets.dart';
import '../student/helpdesk_screen.dart';

/// Admin helpdesk: tickets in my categories, or escalated to my level.
class TicketsInboxScreen extends StatefulWidget {
  const TicketsInboxScreen({super.key});

  @override
  State<TicketsInboxScreen> createState() => _TicketsInboxScreenState();
}

class _TicketsInboxScreenState extends State<TicketsInboxScreen> {
  String _filter = 'open,in_progress';

  @override
  Widget build(BuildContext context) {
    final admin = Session.I.user!['admin'] as Json;
    final cats = (admin['categories'] as List).map((c) => c['name']).join(', ');
    final level = (admin['level'] as num).toInt();
    return Loader(
      key: ValueKey(_filter),
      load: () => Api.I.get('/tickets/inbox', query: {'status': _filter}),
      pollEvery: const Duration(seconds: 30),
      builder: (context, d, reload) {
        final cs = Theme.of(context).colorScheme;
        final tickets = d['tickets'] as List;
        final overdue = tickets.where((t) =>
            (t['status'] == 'open' || t['status'] == 'in_progress') && DateTime.parse(t['due_at'] as String).isBefore(DateTime.now()));
        return PageList(children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.admin_panel_settings_outlined, color: cs.primary),
              title: Text('${admin['title']}'),
              subtitle: Text([
                if (cats.isNotEmpty) 'Handles: $cats',
                if (level >= 2) 'Also sees tickets escalated to ${levelNames[level]}',
              ].join('\n')),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final f in const [('open,in_progress', 'Active'), ('resolved,rejected', 'Closed'), ('', 'All')])
              ChoiceChip(label: Text(f.$2), selected: _filter == f.$1, onSelected: (_) => setState(() => _filter = f.$1)),
          ]),
          if (overdue.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              color: cs.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: cs.onErrorContainer),
                title: Text('${overdue.length} past deadline', style: TextStyle(color: cs.onErrorContainer)),
                subtitle: Text('These move up a level automatically.', style: TextStyle(color: cs.onErrorContainer)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (tickets.isEmpty) const EmptyState(icon: Icons.task_alt, text: 'Nothing here'),
          for (final t in tickets) TicketCard(t: t as Json, onChanged: reload, showStudent: true),
        ]);
      },
    );
  }
}
