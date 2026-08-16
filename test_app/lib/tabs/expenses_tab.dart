import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
import '../screens/add_expense_screen.dart';

class ExpensesTab extends StatelessWidget {
  final String groupId;

  const ExpensesTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, _) {
        final expenses = expenseProvider.getGroupExpenses(groupId);

        if (expenses.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            return _ExpenseCard(
              expense: expenses[index],
              groupId: groupId,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 40, color: Colors.white24),
          ),
          const SizedBox(height: 20),
          const Text('No Expenses Yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Tap + to add the first expense',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final String groupId;

  const _ExpenseCard({required this.expense, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final paidBy = groupProvider.getMember(expense.paidByMemberId);
    final paidByName = paidBy?.name ?? 'Unknown';
    final paidByColor = paidBy != null
        ? Color(int.parse('FF${paidBy.colorHex}', radix: 16))
        : AppTheme.primary;

    final splitCount = expense.splitAmong.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppTheme.negative.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline,
              color: AppTheme.negative, size: 26),
        ),
        onDismissed: (_) {
          context.read<ExpenseProvider>().deleteExpense(expense.id);
        },
        child: InkWell(
          onTap: expense.isSettlement
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(
                        groupId: groupId,
                        existingExpense: expense,
                      ),
                    ),
                  ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: expense.isSettlement
                  ? AppTheme.settled.withOpacity(0.08)
                  : AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: expense.isSettlement
                    ? AppTheme.settled.withOpacity(0.3)
                    : AppTheme.dividerDark,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: expense.isSettlement
                        ? AppTheme.settled.withOpacity(0.15)
                        : AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    expense.isSettlement
                        ? Icons.check_circle_outline
                        : Icons.receipt_outlined,
                    color: expense.isSettlement
                        ? AppTheme.settled
                        : AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: paidByColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: paidByColor, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Paid by $paidByName',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          if (!expense.isSettlement)
                            Text(
                              '· $splitCount ${splitCount == 1 ? 'person' : 'people'}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${expense.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: expense.isSettlement
                            ? AppTheme.settled
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(expense.date),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
