import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group_model.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/group_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'login_screen.dart';

class GroupListScreen extends StatelessWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SplitLedger',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface)),
            Text('Hi, ${auth.displayName}',
                style: TextStyle(
                    fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode),
                tooltip: 'Toggle Theme',
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, _) {
          final groups = groupProvider.groups;
          if (groups.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return _GroupCard(group: groups[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.group_outlined,
                size: 48, color: Colors.white24),
          ),
          const SizedBox(height: 24),
          const Text('No Groups Yet',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Create a group to start splitting bills',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create Group'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 48)),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final members = groupProvider.getGroupMembers(group.id);
    final balances = expenseProvider.computeNetBalances(group.id);

    final totalExpenses = expenseProvider
        .getGroupExpenses(group.id)
        .where((e) => !e.isSettlement)
        .fold(0.0, (sum, e) => sum + e.amount);

    final isSettled = balances.isNotEmpty && balances.values.every((b) => b.abs() < 0.01);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(group.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppTheme.negative.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline,
              color: AppTheme.negative, size: 28),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.cardDark,
              title: const Text('Delete Group'),
              content: Text(
                  'Delete "${group.name}"? All expenses will be lost.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete',
                        style: TextStyle(color: AppTheme.negative))),
              ],
            ),
          );
        },
        onDismissed: (_) {
          context.read<GroupProvider>().deleteGroup(group.id);
          context.read<ExpenseProvider>().deleteGroupExpenses(group.id);
        },
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupDetailScreen(groupId: group.id),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isSettled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.settled.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Settled',
                            style: TextStyle(
                                color: AppTheme.settled,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Member avatars
                    SizedBox(
                      height: 28,
                      width: (members.length.clamp(0, 4) * 20.0) + 28 +
                          (members.length > 4 ? 28 : 0),
                      child: Stack(
                        children: [
                          for (int i = 0;
                              i < members.length.clamp(0, 4);
                              i++)
                            Positioned(
                              left: i * 20.0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(
                                      'FF${members[i].colorHex}',
                                      radix: 16)),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppTheme.cardDark, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    members[i].name[0].toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          if (members.length > 4)
                            Positioned(
                              left: 4 * 20.0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppTheme.dividerDark,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppTheme.cardDark, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${members.length - 4}',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white60),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${members.length} member${members.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13),
                    ),

                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${totalExpenses.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Text('total',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

