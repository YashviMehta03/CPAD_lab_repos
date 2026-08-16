import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/group_provider.dart';
import '../services/debt_simplifier.dart';
import '../theme/app_theme.dart';
import '../widgets/debt_graph.dart';

class BalancesTab extends StatefulWidget {
  final String groupId;

  const BalancesTab({super.key, required this.groupId});

  @override
  State<BalancesTab> createState() => _BalancesTabState();
}

class _BalancesTabState extends State<BalancesTab> {
  bool _showSimplified = false;

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    final members = groupProvider.getGroupMembers(widget.groupId);
    final netBalances = expenseProvider.computeNetBalances(widget.groupId);

    // Raw = actual pairwise debts from expense records (before any simplification)
    final rawSettlements = expenseProvider.computeRawSettlements(widget.groupId);
    // Simplified = minimum transactions via greedy algorithm on net balances
    final simplifiedSettlements = simplifyDebts(netBalances);

    final isSettled = netBalances.isNotEmpty &&
        (simplifiedSettlements.isEmpty ||
            netBalances.values.every((b) => b.abs() < 0.01));

    if (isSettled && netBalances.isNotEmpty) {
      return _buildAllSettledState();
    }

    if (members.isEmpty || netBalances.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildToggleRow(rawSettlements, simplifiedSettlements),
          ),
          const SizedBox(height: 16),

          // Debt Graph (hero)
          Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.dividerDark),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DebtGraph(
                members: members,
                netBalances: netBalances,
                showSimplified: _showSimplified,
                rawSettlements: rawSettlements,
                simplifiedSettlements: simplifiedSettlements,
              ),
            ),
          ),

          // Transaction count label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildTransactionCountLabel(
                rawSettlements, simplifiedSettlements),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: AppTheme.dividerDark),
          ),

          // Net balances
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: const Text(
              'NET BALANCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white38,
                letterSpacing: 1,
              ),
            ),
          ),
          ...members.map((m) {
            final balance = netBalances[m.id] ?? 0;
            return _BalanceCard(
              name: m.name,
              colorHex: m.colorHex,
              balance: balance,
            );
          }),

          // Settlements list
          if (!_showSimplified && rawSettlements.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: const Text(
                'ALL DEBTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ),
            ),
            ...rawSettlements.map((s) => _SettlementCard(
                  settlement: s,
                  groupId: widget.groupId,
                  members: groupProvider,
                  canMarkPaid: false,
                )),
          ],

          if (_showSimplified && simplifiedSettlements.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: const Text(
                'SUGGESTED PAYMENTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ),
            ),
            ...simplifiedSettlements.map((s) => _SettlementCard(
                  settlement: s,
                  groupId: widget.groupId,
                  members: groupProvider,
                  canMarkPaid: true,
                )),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
      List<Settlement> raw, List<Settlement> simplified) {
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            label: 'Raw Debts',
            count: raw.length,
            selected: !_showSimplified,
            color: AppTheme.negative,
            onTap: () => setState(() => _showSimplified = false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToggleChip(
            label: 'Simplified',
            count: simplified.length,
            selected: _showSimplified,
            color: AppTheme.positive,
            onTap: () => setState(() => _showSimplified = true),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCountLabel(
      List<Settlement> raw, List<Settlement> simplified) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _showSimplified
          ? RichText(
              key: const ValueKey('simplified'),
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: '${raw.length} raw debts',
                    style: const TextStyle(
                        color: AppTheme.negative,
                        fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(
                    text: ' simplified to ',
                    style: TextStyle(color: Colors.white54),
                  ),
                  TextSpan(
                    text: '${simplified.length} payments  ✨',
                    style: const TextStyle(
                        color: AppTheme.positive,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          : RichText(
              key: const ValueKey('raw'),
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: '${raw.length} transaction${raw.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(
                    text: ' needed to settle • tap Simplified to minimize',
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAllSettledState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.settled.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🎉', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('All Settled Up!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Everyone is even — no debts remaining.',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Add some expenses to see balances.',
          style: TextStyle(color: Colors.white38)),
    );
  }

}

class _ToggleChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppTheme.dividerDark,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white38,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.2) : Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? color : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String name;
  final String colorHex;
  final double balance;

  const _BalanceCard({
    required this.name,
    required this.colorHex,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final color = balance.abs() < 0.01
        ? Colors.white38
        : isPositive
            ? AppTheme.positive
            : AppTheme.negative;
    final memberColor = Color(int.parse('FF$colorHex', radix: 16));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: memberColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: memberColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                      color: memberColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    balance.abs() < 0.01
                        ? 'settled up'
                        : isPositive
                            ? 'is owed money'
                            : 'owes money',
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              balance.abs() < 0.01
                  ? '✓'
                  : '${isPositive ? '+' : '-'}₹${balance.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final Settlement settlement;
  final String groupId;
  final GroupProvider members;
  final bool canMarkPaid;

  const _SettlementCard({
    required this.settlement,
    required this.groupId,
    required this.members,
    required this.canMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final from = members.getMember(settlement.fromMemberId);
    final to = members.getMember(settlement.toMemberId);
    if (from == null || to == null) return const SizedBox.shrink();

    final fromColor = Color(int.parse('FF${from.colorHex}', radix: 16));
    final toColor = Color(int.parse('FF${to.colorHex}', radix: 16));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerDark),
        ),
        child: Row(
          children: [
            // From avatar
            _miniAvatar(from.name, fromColor),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${from.name} → ${to.name}',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${settlement.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // To avatar
            _miniAvatar(to.name, toColor),
            if (canMarkPaid) ...[
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _markAsPaid(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.positive.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.positive.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Mark Paid',
                    style: TextStyle(
                      color: AppTheme.positive,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniAvatar(String name, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _markAsPaid(BuildContext context) async {
    await context.read<ExpenseProvider>().recordSettlement(
          groupId: groupId,
          fromMemberId: settlement.fromMemberId,
          toMemberId: settlement.toMemberId,
          amount: settlement.amount,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.positive, size: 18),
              SizedBox(width: 8),
              Text('Payment marked as paid!'),
            ],
          ),
          backgroundColor: AppTheme.surfaceDark,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
