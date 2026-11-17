import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api.dart';
import 'theme.dart';

// ------------------------------------------------------------------ data loading

/// Loads data, shows loading / error states, supports pull-to-refresh and optional polling.
class Loader extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder, this.pollEvery});

  final Future<Json> Function() load;
  final Widget Function(BuildContext context, Json data, Future<void> Function() reload) builder;
  final Duration? pollEvery;

  @override
  State<Loader> createState() => LoaderState();
}

class LoaderState extends State<Loader> {
  Json? _data;
  Object? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    reload();
    if (widget.pollEvery != null) {
      _timer = Timer.periodic(widget.pollEvery!, (_) => reload(silent: true));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> reload({bool silent = false}) async {
    try {
      final d = await widget.load();
      if (mounted) {
        setState(() {
          _data = d;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && (!silent || _data == null)) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _data == null) {
      return ErrorView(message: _error.toString(), onRetry: () {
        setState(() => _error = null);
        reload();
      });
    }
    if (_data == null) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(onRefresh: reload, child: widget.builder(context, _data!, reload));
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ),
      );
}

// ------------------------------------------------------------------ feedback

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

/// Runs an API action, shows the error if it fails. Returns true on success.
Future<bool> run(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (success != null && context.mounted) toast(context, success);
    return true;
  } catch (e) {
    if (context.mounted) toast(context, e.toString());
    return false;
  }
}

Future<bool> confirm(BuildContext context, String title, String body, {String ok = 'Confirm'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Back')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(ok)),
      ],
    ),
  );
  return r ?? false;
}

/// Asks for one line of text. Returns null if dismissed.
Future<String?> askText(BuildContext context, String title,
    {String hint = '', String ok = 'OK', bool required = false, String initial = ''}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Back')),
        FilledButton(
          onPressed: () {
            if (required && ctrl.text.trim().isEmpty) return;
            Navigator.pop(c, ctrl.text.trim());
          },
          child: Text(ok),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------------ building blocks

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, required this.color, this.icon, this.dense = false});
  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 2 : 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        // A single Text (not a Row) so long labels wrap instead of overflowing, in any parent.
        child: Text.rich(
          TextSpan(children: [
            if (icon != null)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(icon, size: dense ? 12 : 14, color: color),
                ),
              ),
            TextSpan(text: label),
          ]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: dense ? 11 : 12),
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.styles = statusStyles, this.dense = false});
  final String status;
  final Map<String, StatusStyle> styles;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final s = styles[status] ?? StatusStyle(status, Colors.grey, Icons.circle_outlined);
    return Pill(s.label, color: s.color, icon: s.icon, dense: dense);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ]),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Row(children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          ?trailing,
        ]),
      );
}

/// A scrollable page body that always allows pull-to-refresh.
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 96)});
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: children,
      );
}

/// Pick from a list of {id, label} maps. Value is the id.
class OptionDropdown extends StatelessWidget {
  const OptionDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.allowNone = false,
    this.noneLabel = 'Any',
  });
  final String label;
  final List<dynamic> options;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final bool allowNone;
  final String noneLabel;

  @override
  Widget build(BuildContext context) {
    final ids = options.map((o) => o['id']).toSet();
    return DropdownButtonFormField<dynamic>(
      key: ValueKey('$label-$value-${options.length}'),
      initialValue: ids.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (allowNone) DropdownMenuItem(value: null, child: Text(noneLabel)),
        for (final o in options)
          DropdownMenuItem(value: o['id'], child: Text('${o['label']}', overflow: TextOverflow.ellipsis)),
      ],
      onChanged: onChanged,
    );
  }
}

// ------------------------------------------------------------------ formatting

DateTime parseDay(String d) => DateTime.parse(d);
String fmtDay(String d) => DateFormat('EEE, d MMM').format(parseDay(d));
String fmtDayLong(String d) => DateFormat('EEEE, d MMMM').format(parseDay(d));
String isoDay(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String timeAgo(String iso) {
  final t = DateTime.parse(iso).toLocal();
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return DateFormat('d MMM').format(t);
}

String fmtDateTime(String iso) => DateFormat('d MMM, h:mm a').format(DateTime.parse(iso).toLocal());

/// "due in 3 h" / "overdue by 2 h".
String dueText(String iso) {
  final diff = DateTime.parse(iso).toLocal().difference(DateTime.now());
  String span(Duration d) => d.inHours.abs() >= 24 ? '${d.inDays.abs()} d' : (d.inMinutes.abs() >= 60 ? '${d.inHours.abs()} h' : '${d.inMinutes.abs()} min');
  return diff.isNegative ? 'overdue by ${span(diff)}' : 'due in ${span(diff)}';
}

const dayShort = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const dayLong = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

String sectionLabel(Json s) => '${s['branch_code']} ${s['year_code']}-${s['name'] ?? s['section_name']}';

/// The next `n` weekdays starting today (dates as yyyy-MM-dd), using the server's campus date.
List<String> nextWeekdays(String today, int n) {
  final out = <String>[];
  var d = parseDay(today);
  while (out.length < n) {
    if (d.weekday <= 5) out.add(isoDay(d));
    d = d.add(const Duration(days: 1));
  }
  return out;
}
