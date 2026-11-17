import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/widgets.dart';
import '../student/boards_screen.dart';

IconData notificationIcon(String type) => switch (type) {
      'broadcast' => Icons.campaign_outlined,
      'class_change' => Icons.event_repeat,
      'ticket' => Icons.confirmation_number_outlined,
      'meeting' => Icons.groups_outlined,
      'queue' => Icons.confirmation_num_outlined,
      'help_ping' => Icons.front_hand_outlined,
      'chat' => Icons.chat_bubble_outline,
      'board' => Icons.forum_outlined,
      _ => Icons.notifications_outlined,
    };

/// The bell: every in-app notification. Also used (filtered) as the student announcements page.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, this.types, this.title = 'Notifications'});
  final String? types;
  final String title;

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<LoaderState>();
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        if (types == null)
          TextButton(
            onPressed: () async {
              await run(context, () => Api.I.post('/notifications/read-all'));
              key.currentState?.reload();
            },
            child: const Text('Mark all read'),
          ),
      ]),
      body: Loader(
        key: key,
        load: () => Api.I.get('/notifications', query: {'type': types}),
        builder: (context, data, reload) {
          final items = data['notifications'] as List;
          if (items.isEmpty) {
            return PageList(children: [
              EmptyState(icon: Icons.notifications_none, text: types == null ? 'Nothing yet' : 'No announcements yet'),
            ]);
          }
          return PageList(padding: const EdgeInsets.fromLTRB(12, 8, 12, 24), children: [
            for (final n in items) _NotificationTile(n: n as Json, onRead: reload),
          ]);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onRead});
  final Json n;
  final Future<void> Function() onRead;

  /// Help pings and chat messages open the chat, so a helper can reply to the student who asked.
  Future<void> _open(BuildContext context) async {
    final data = (n['data'] as Map?) ?? {};
    int? chatId = (data['conversation_id'] as num?)?.toInt();
    if (chatId == null && n['type'] == 'help_ping' && data['user_id'] != null) {
      await run(context, () async {
        final c = await Api.I.post('/chats', {'user_id': data['user_id'], 'form_type_id': data['form_type_id']});
        chatId = (c['conversation']['id'] as num).toInt();
      });
    }
    if (chatId == null || !context.mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(id: chatId!)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unread = n['read_at'] == null;
    final data = (n['data'] as Map?) ?? {};
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: unread ? cs.primaryContainer.withValues(alpha: 0.35) : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (unread) {
              await Api.I.post('/notifications/${n['id']}/read');
              onRead();
            }
            if (context.mounted) await _open(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                child: Icon(notificationIcon(n['type'] as String), size: 19, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n['title'] as String,
                      style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w600)),
                  if (n['body'] != null) ...[
                    const SizedBox(height: 4),
                    Text(n['body'] as String, style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                  if (n['type'] == 'help_ping' || n['type'] == 'chat') ...[
                    const SizedBox(height: 4),
                    Text('Tap to reply', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (data['from'] != null) 'From ${data['from']}',
                      if (data['to'] != null) 'to ${data['to']}',
                      timeAgo(n['created_at'] as String),
                    ].join(' · '),
                    style: TextStyle(color: cs.outline, fontSize: 12),
                  ),
                ]),
              ),
              if (unread) Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
            ]),
          ),
        ),
      ),
    );
  }
}
