import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
import '../tabs/expenses_tab.dart';
import '../tabs/balances_tab.dart';
import '../tabs/members_tab.dart';
import '../tabs/stats_tab.dart';
import 'add_expense_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../services/debt_simplifier.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final groups = groupProvider.groups;
    final group = groups.firstWhere(
      (g) => g.id == widget.groupId,
      orElse: () => groups.isNotEmpty ? groups.first : throw Exception('Group not found'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'Members'),
            Tab(text: 'Stats'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Summary',
            onPressed: () => _shareSummary(context, group.name),
          ),
          PopupMenuButton<String>(
            color: AppTheme.surfaceDark,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDeleteGroup(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        color: AppTheme.negative, size: 18),
                    SizedBox(width: 8),
                    Text('Delete Group',
                        style: TextStyle(color: AppTheme.negative)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AddExpenseScreen(groupId: widget.groupId),
              ),
            ),
            child: const Icon(Icons.add),
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExpensesTab(groupId: widget.groupId),
          BalancesTab(groupId: widget.groupId),
          MembersTab(groupId: widget.groupId),
          StatsTab(groupId: widget.groupId),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteGroup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Group'),
        content: const Text(
            'This will delete all expenses and members. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.negative)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<GroupProvider>().deleteGroup(widget.groupId);
      context.read<ExpenseProvider>().deleteGroupExpenses(widget.groupId);
      Navigator.of(context).pop();
    }
  }

  void _shareSummary(BuildContext context, String groupName) {
    final expenseProvider = context.read<ExpenseProvider>();
    final groupProvider = context.read<GroupProvider>();
    final members = groupProvider.getGroupMembers(widget.groupId);
    final netBalances = expenseProvider.computeNetBalances(widget.groupId);
    final simplifiedDebts = simplifyDebts(netBalances);

    if (netBalances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses to share yet.')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('📊 $groupName - SplitLedger Summary');
    buffer.writeln('-----------------------------------');
    
    // Member balances
    for (final member in members) {
      final balance = netBalances[member.id] ?? 0.0;
      if (balance.abs() < 0.01) continue;
      if (balance > 0) {
        buffer.writeln('${member.name} gets back ₹${balance.toStringAsFixed(2)}');
      } else {
        buffer.writeln('${member.name} owes ₹${(-balance).toStringAsFixed(2)}');
      }
    }
    
    buffer.writeln('\n💸 How to Settle Up:');
    buffer.writeln('-----------------------------------');
    if (simplifiedDebts.isEmpty) {
      buffer.writeln('All settled up! 🎉');
    } else {
      for (final debt in simplifiedDebts) {
        final from = members.firstWhere((m) => m.id == debt.fromMemberId).name;
        final to = members.firstWhere((m) => m.id == debt.toMemberId).name;
        buffer.writeln('$from owes $to ₹${debt.amount.toStringAsFixed(2)}');
      }
    }
    
    Share.share(buffer.toString());
  }
}
