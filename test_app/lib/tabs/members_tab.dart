import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';

class MembersTab extends StatelessWidget {
  final String groupId;

  const MembersTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    final members = groupProvider.getGroupMembers(groupId);
    final netBalances = expenseProvider.computeNetBalances(groupId);

    if (members.isEmpty) {
      return const Center(
        child: Text('No members in this group.',
            style: TextStyle(color: Colors.white38)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final balance = netBalances[member.id] ?? 0.0;
        final memberColor =
            Color(int.parse('FF${member.colorHex}', radix: 16));

        final isSettled = balance.abs() < 0.01;
        final isPositive = balance > 0;

        final balanceColor = isSettled
            ? Colors.white38
            : isPositive
                ? AppTheme.positive
                : AppTheme.negative;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.dividerDark),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: memberColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: memberColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      member.name[0].toUpperCase(),
                      style: TextStyle(
                        color: memberColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: balanceColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSettled
                              ? '✓ Settled up'
                              : isPositive
                                  ? 'Gets back ₹${balance.toStringAsFixed(2)}'
                                  : 'Owes ₹${balance.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: balanceColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Numeric balance
                Text(
                  isSettled
                      ? '₹0'
                      : '${isPositive ? '+' : '-'}₹${balance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    color: balanceColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
