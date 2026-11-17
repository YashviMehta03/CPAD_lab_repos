import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/widgets.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      toast(context, 'Enter your email and password');
      return;
    }
    setState(() => _busy = true);
    try {
      await Session.I.login(_email.text.trim(), _password.text);
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signup() async {
    final email = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => SignupScreen(email: _email.text.trim())));
    // Back from sign up without being logged in (email needs confirming): prefill the email.
    if (email != null && mounted) {
      _email.text = email;
      _password.clear();
    }
  }

  Future<void> _serverSettings() async {
    final url = await askText(context, 'Server address',
        hint: 'http://10.0.2.2:4000/api', initial: Api.I.baseUrl, ok: 'Save');
    if (url != null && url.isNotEmpty) {
      await Api.I.setBaseUrl(url);
      if (mounted) toast(context, 'Server set to ${Api.I.baseUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                      tooltip: 'Server address', onPressed: _serverSettings, icon: const Icon(Icons.dns_outlined)),
                ),
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.public, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                Text('CampusSphere',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Everything about campus, one tap away',
                    textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: _hide,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _login,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Log in'),
                ),
                const SizedBox(height: 16),
                Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('New to CampusSphere?', style: TextStyle(color: cs.onSurfaceVariant)),
                  TextButton(onPressed: _busy ? null : _signup, child: const Text('Create an account')),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
