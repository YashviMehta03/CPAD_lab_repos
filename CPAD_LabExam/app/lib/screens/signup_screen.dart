import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/widgets.dart';

/// Self sign-up for students and professors. The account itself lives in Supabase Auth;
/// the backend stores the campus profile (section and roll number, or faculty code and department).
/// Pops with the email when the user still has to confirm it, so the login screen can prefill it.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.email = ''});
  final String email;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _roll = TextEditingController();
  final _code = TextEditingController();
  final _cabin = TextEditingController();

  String _role = 'student';
  int? _branchId, _yearId, _sectionId, _departmentId;
  bool _hide = true;
  bool _busy = false;
  Json? _options;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    for (final c in [_email, _name, _phone, _password, _confirm, _roll, _code, _cabin]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _loadError = null);
    try {
      final o = await Api.I.get('/auth/options');
      if (mounted) setState(() => _options = o);
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  List<Json> _list(String key) => ((_options?[key] as List?) ?? const []).cast<Json>();

  List<Json> get _sections => _list('sections')
      .where((s) => s['branch_id'] == _branchId && s['year_id'] == _yearId)
      .toList();

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final student = _role == 'student';
      final message = await Session.I.signup({
        'role': _role,
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'phone': _phone.text.trim(),
        if (student) 'section_id': _sectionId,
        if (student) 'roll_no': _roll.text.trim(),
        if (!student) 'code': _code.text.trim(),
        if (!student) 'department_id': _departmentId,
        if (!student) 'cabin': _cabin.text.trim(),
      });
      if (!mounted) return;
      if (message == null) {
        // Logged in: the app switches to the home shell underneath, so close this page.
        Navigator.of(context).pop();
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_outlined),
          title: const Text('Confirm your email'),
          content: Text(message),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );
      if (mounted) Navigator.of(context).pop(_email.text.trim());
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v, String what) => (v == null || v.trim().isEmpty) ? 'Enter $what' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: _options == null
            ? Center(
                child: _loadError == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.tonal(onPressed: _loadOptions, child: const Text('Retry')),
                        ]),
                      ),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(key: _form, child: _fields(context)),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _fields(BuildContext context) {
    final student = _role == 'student';
    const gap = SizedBox(height: 12);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'student', icon: Icon(Icons.school_outlined), label: Text('Student')),
          ButtonSegment(value: 'professor', icon: Icon(Icons.person_outline), label: Text('Professor')),
        ],
        selected: {_role},
        onSelectionChanged: (s) => setState(() => _role = s.first),
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.badge_outlined)),
        validator: (v) => _required(v, 'your name'),
      ),
      gap,
      TextFormField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
        validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '') ? null : 'Enter a valid email',
      ),
      gap,
      TextFormField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
      ),
      gap,
      TextFormField(
        controller: _password,
        obscureText: _hide,
        autofillHints: const [AutofillHints.newPassword],
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _hide = !_hide),
          ),
        ),
        validator: (v) => (v ?? '').length < 6 ? 'At least 6 characters' : null,
      ),
      gap,
      TextFormField(
        controller: _confirm,
        obscureText: _hide,
        decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline)),
        validator: (v) => v != _password.text ? 'Passwords do not match' : null,
      ),
      const SizedBox(height: 24),
      Text(student ? 'Your class' : 'Your faculty details', style: Theme.of(context).textTheme.titleMedium),
      gap,
      if (student) ...[
        DropdownButtonFormField<int>(
          initialValue: _branchId,
          decoration: const InputDecoration(labelText: 'Branch'),
          items: [
            for (final b in _list('branches')) DropdownMenuItem(value: b['id'] as int, child: Text('${b['name']}')),
          ],
          onChanged: (v) => setState(() {
            _branchId = v;
            _sectionId = null;
          }),
          validator: (v) => v == null ? 'Pick your branch' : null,
        ),
        gap,
        DropdownButtonFormField<int>(
          initialValue: _yearId,
          decoration: const InputDecoration(labelText: 'Year'),
          items: [
            for (final y in _list('years')) DropdownMenuItem(value: y['id'] as int, child: Text('${y['name']}')),
          ],
          onChanged: (v) => setState(() {
            _yearId = v;
            _sectionId = null;
          }),
          validator: (v) => v == null ? 'Pick your year' : null,
        ),
        gap,
        DropdownButtonFormField<int>(
          // Keyed so the field resets when branch / year change the list of sections.
          key: ValueKey('sec-$_branchId-$_yearId'),
          initialValue: _sectionId,
          decoration: InputDecoration(
            labelText: 'Section',
            helperText: _branchId != null && _yearId != null && _sections.isEmpty ? 'No sections for this branch and year' : null,
          ),
          items: [
            for (final s in _sections) DropdownMenuItem(value: s['id'] as int, child: Text('Section ${s['name']}')),
          ],
          onChanged: (v) => setState(() => _sectionId = v),
          validator: (v) => v == null ? 'Pick your section' : null,
        ),
        gap,
        TextFormField(
          controller: _roll,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Roll number', prefixIcon: Icon(Icons.numbers)),
          validator: (v) => _required(v, 'your roll number'),
        ),
      ] else ...[
        TextFormField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
              labelText: 'Faculty short code', hintText: 'e.g. PV', prefixIcon: Icon(Icons.tag)),
          validator: (v) => _required(v, 'your faculty code'),
        ),
        gap,
        DropdownButtonFormField<int>(
          initialValue: _departmentId,
          decoration: const InputDecoration(labelText: 'Department'),
          items: [
            for (final b in _list('branches')) DropdownMenuItem(value: b['id'] as int, child: Text('${b['name']}')),
          ],
          onChanged: (v) => setState(() => _departmentId = v),
          validator: (v) => v == null ? 'Pick your department' : null,
        ),
        gap,
        TextFormField(
          controller: _cabin,
          decoration: const InputDecoration(
              labelText: 'Cabin (optional)', hintText: 'e.g. CE Dept, Cabin 104', prefixIcon: Icon(Icons.meeting_room_outlined)),
        ),
      ],
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _busy ? null : _submit,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        child: _busy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Sign up'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
        child: const Text('Already have an account? Log in'),
      ),
    ]);
  }
}
