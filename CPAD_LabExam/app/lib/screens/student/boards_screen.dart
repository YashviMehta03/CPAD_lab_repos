import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/widgets.dart';
import '../shell.dart';

const _formIcons = {
  'bonafide': Icons.verified_outlined,
  'nodues': Icons.receipt_long_outlined,
  'buspass': Icons.train_outlined,
  'scholarship': Icons.school_outlined,
  'idcard': Icons.badge_outlined,
};

/// One help board per form type.
class BoardsScreen extends StatelessWidget {
  const BoardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Paperwork help',
      actions: [
        IconButton(
            tooltip: 'Chats', onPressed: () => push(context, const ChatsScreen()), icon: const Icon(Icons.chat_bubble_outline)),
      ],
      child: Loader(
        load: () => Api.I.get('/boards'),
        builder: (context, d, reload) {
          final cs = Theme.of(context).colorScheme;
          return PageList(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
              child: Text('Ask students who have already done it. Tap "I\'ve done this" to help others.',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            for (final b in d['boards'] as List)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                        backgroundColor: Colors.purple.withValues(alpha: 0.12),
                        child: Icon(_formIcons[b['code']] ?? Icons.description_outlined, color: Colors.purple)),
                    title: Text(b['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${b['helpers']} helpers · ${b['questions']} questions'
                        '${b['am_helper'] == true ? ' · you help here' : ''}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                          context, MaterialPageRoute(builder: (_) => BoardDetailScreen(id: b['id'] as int, name: b['name'] as String)));
                      reload();
                    },
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class BoardDetailScreen extends StatefulWidget {
  const BoardDetailScreen({super.key, required this.id, required this.name});
  final int id;
  final String name;

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  final _key = GlobalKey<LoaderState>();
  final _question = TextEditingController();

  void _reload() => _key.currentState?.reload();

  Future<void> _ask() async {
    if (_question.text.trim().length < 2) return;
    if (await run(context, () => Api.I.post('/boards/${widget.id}/posts', {'body': _question.text}), success: 'Question posted')) {
      _question.clear();
      _reload();
    }
  }

  Future<void> _reply(int parentId) async {
    final text = await askText(context, 'Reply', hint: 'Share what worked for you', ok: 'Reply', required: true);
    if (text == null || !mounted) return;
    if (await run(context, () => Api.I.post('/boards/${widget.id}/posts', {'body': text, 'parent_id': parentId}))) _reload();
  }

  Future<void> _needHelp() async {
    final msg = await askText(context, 'Ping all helpers', hint: 'What do you need? (optional)', ok: 'Send ping');
    if (msg == null || !mounted) return;
    var n = 0;
    if (await run(context, () async {
      n = ((await Api.I.post('/boards/${widget.id}/need-help', {'message': msg}))['pinged'] as num).toInt();
    })) {
      if (mounted) toast(context, 'Pinged $n helper(s). They can chat with you.');
    }
  }

  Future<void> _chat(Json helper) async {
    await run(context, () async {
      final c = await Api.I.post('/chats', {'user_id': helper['id'], 'form_type_id': widget.id});
      if (!mounted) return;
      push(context, ChatScreen(id: c['conversation']['id'] as int, title: helper['name'] as String));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: widget.name,
      child: Loader(
        key: _key,
        load: () => Api.I.get('/boards/${widget.id}'),
        builder: (context, d, reload) {
          final cs = Theme.of(context).colorScheme;
          final board = d['board'] as Json;
          final helpers = d['helpers'] as List;
          final threads = d['threads'] as List;
          final amHelper = d['am_helper'] == true;
          final me = Session.I.userId;
          return PageList(children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (board['description'] != null) Text(board['description'] as String),
                  if (board['office'] != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.place_outlined, size: 16, color: cs.outline),
                      const SizedBox(width: 4),
                      Expanded(child: Text(board['office'] as String, style: TextStyle(color: cs.onSurfaceVariant))),
                    ]),
                  ],
                  const SizedBox(height: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(
                      child: amHelper
                          ? OutlinedButton.icon(
                              onPressed: () async {
                                if (await run(context, () => Api.I.delete('/boards/${widget.id}/helper'))) reload();
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text("You're a helper"))
                          : FilledButton.tonalIcon(
                              onPressed: () async {
                                if (await run(context, () => Api.I.post('/boards/${widget.id}/helper'),
                                    success: 'Thanks! Others can now reach you')) {
                                  reload();
                                }
                              },
                              icon: const Icon(Icons.task_alt),
                              label: const Text("I've done this")),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                        onPressed: _needHelp,
                        icon: const Icon(Icons.front_hand_outlined),
                        label: const Text('Need help? Ping all helpers')),
                  ]),
                ]),
              ),
            ),
            SectionHeader('Helpers (${helpers.length})'),
            if (helpers.isEmpty) Text('Nobody yet. Be the first after you finish this form.', style: TextStyle(color: cs.outline)),
            if (helpers.isNotEmpty)
              SizedBox(
                height: 96,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final h in helpers)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: h['id'] == me ? null : () => _chat(h as Json),
                        child: SizedBox(
                          width: 84,
                          child: Column(children: [
                            CircleAvatar(radius: 24, child: Text((h['name'] as String)[0])),
                            const SizedBox(height: 4),
                            Text((h['name'] as String).split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(h['id'] == me ? 'You' : 'Chat', style: TextStyle(fontSize: 11, color: cs.primary)),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
            const SectionHeader('Questions'),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _question,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Ask a question about this form'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _ask, icon: const Icon(Icons.send)),
            ]),
            const SizedBox(height: 12),
            if (threads.isEmpty) const EmptyState(icon: Icons.forum_outlined, text: 'No questions yet'),
            for (final t in threads)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _postHeader(context, t as Json),
                      const SizedBox(height: 6),
                      Text(t['body'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                      for (final r in t['replies'] as List)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _postHeader(context, r as Json),
                            const SizedBox(height: 4),
                            Text(r['body'] as String),
                          ]),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                            onPressed: () => _reply(t['id'] as int), icon: const Icon(Icons.reply, size: 18), label: const Text('Reply')),
                      ),
                    ]),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }

  Widget _postHeader(BuildContext context, Json p) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Flexible(
        child: Text(p['author_name'] as String,
            overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
      if (p['author_is_helper'] == true) ...[
        const SizedBox(width: 6),
        const Pill('Done it', color: Colors.green, dense: true),
      ],
      const Spacer(),
      Text(timeAgo(p['created_at'] as String), style: TextStyle(color: cs.outline, fontSize: 12)),
    ]);
  }
}

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Chats',
      child: Loader(
        load: () => Api.I.get('/chats'),
        pollEvery: const Duration(seconds: 15),
        builder: (context, d, reload) {
          final list = d['conversations'] as List;
          return PageList(children: [
            if (list.isEmpty)
              const EmptyState(icon: Icons.chat_bubble_outline, text: 'No chats yet. Open a paperwork board and tap a helper.'),
            for (final c in list)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text((c['other_name'] as String)[0])),
                  title: Text(c['other_name'] as String),
                  subtitle: Text(
                    [if (c['form_name'] != null) c['form_name'], c['last_body'] ?? 'Say hi'].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: c['last_at'] != null ? Text(timeAgo(c['last_at'] as String), style: const TextStyle(fontSize: 11)) : null,
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ChatScreen(id: c['id'] as int, title: c['other_name'] as String)));
                    reload();
                  },
                ),
              ),
          ]);
        },
      ),
    );
  }
}

/// 1:1 chat. Polls for new messages every few seconds.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.id, this.title});
  final int id;
  final String? title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <Json>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = true;
  bool _alive = true;
  String? _otherName;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  Future<void> _poll() async {
    while (_alive) {
      await _fetch();
      await Future.delayed(const Duration(seconds: 4));
    }
  }

  Future<void> _fetch() async {
    try {
      final after = _messages.isEmpty ? 0 : _messages.last['id'];
      final r = await Api.I.get('/chats/${widget.id}/messages', query: {'after': after});
      final fresh = (r['messages'] as List).cast<Json>();
      if (!mounted) return;
      setState(() {
        _otherName = (r['conversation']?['other']?['name'] as String?) ?? _otherName;
        _messages.addAll(fresh);
        _loading = false;
      });
      if (fresh.isNotEmpty) _toBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await run(context, () => Api.I.post('/chats/${widget.id}/messages', {'body': text}));
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = Session.I.userId;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? _otherName ?? 'Chat')),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? const EmptyState(icon: Icons.waving_hand_outlined, text: 'Say hi and ask your question')
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final m = _messages[i];
                        final mine = m['sender_id'] == me;
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: mine ? cs.primary : cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(m['body'] as String, style: TextStyle(color: mine ? cs.onPrimary : cs.onSurface)),
                              Text(timeAgo(m['created_at'] as String),
                                  style: TextStyle(fontSize: 10, color: mine ? cs.onPrimary.withValues(alpha: 0.7) : cs.outline)),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'Message'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}
