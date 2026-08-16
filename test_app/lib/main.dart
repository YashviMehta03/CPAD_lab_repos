import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/auth_data.dart';
import 'models/expense_model.dart';
import 'models/group_model.dart';
import 'models/member_model.dart';
import 'models/split_type.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/group_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/group_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(GroupAdapter());
  Hive.registerAdapter(MemberAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(AuthDataAdapter());
  Hive.registerAdapter(SplitTypeAdapter());

  // Open boxes
  await Hive.openBox<Group>('groupBox');
  await Hive.openBox<Member>('memberBox');
  await Hive.openBox<Expense>('expenseBox');
  await Hive.openBox<AuthData>('authBox');

  // Initialize providers
  final authProvider = AuthProvider();
  await authProvider.init();

  final groupProvider = GroupProvider();
  await groupProvider.init();

  final expenseProvider = ExpenseProvider();
  await expenseProvider.init();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: groupProvider),
        ChangeNotifierProvider.value(value: expenseProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const SplitLedgerApp(),
    ),
  );
}

class SplitLedgerApp extends StatelessWidget {
  const SplitLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return MaterialApp(
      title: 'SplitLedger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _resolveHome(),
    );
  }

  /// Determine the starting screen based on stored auth state.
  Widget _resolveHome() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.hasAccount) {
          if (auth.isLoggedIn) {
            return const GroupListScreen();
          }
          return const LoginScreen();
        }
        return const SignUpScreen();
      },
    );
  }
}
