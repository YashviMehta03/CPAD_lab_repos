import 'package:flutter/material.dart';

import 'core/session.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CampusSphereApp());
  await Session.I.restore();
}

class CampusSphereApp extends StatelessWidget {
  const CampusSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Session.I,
      builder: (context, _) {
        final s = Session.I;
        final seed = s.user == null ? AppColors.brand : roleColor(s.role);
        return MaterialApp(
          title: 'CampusSphere',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(seed, Brightness.light),
          darkTheme: buildTheme(seed, Brightness.dark),
          home: s.restoring
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : s.user == null
                  ? const LoginScreen()
                  // Keyed by user so switching accounts rebuilds the whole role shell.
                  : HomeShell(key: ValueKey('${s.userId}-${s.role}')),
        );
      },
    );
  }
}
