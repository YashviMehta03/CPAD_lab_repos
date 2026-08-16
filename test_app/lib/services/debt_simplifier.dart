// Pure Dart debt simplification — no UI dependencies.
// Takes a map of memberId -> net balance and returns the minimum
// number of payments needed to fully settle the group.


class Settlement {
  final String fromMemberId; // who pays
  final String toMemberId;   // who receives
  final double amount;

  const Settlement({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });
}

/// Greedy sorted-list algorithm.
/// Returns the minimum set of [Settlement]s to clear all debts.
List<Settlement> simplifyDebts(Map<String, double> netBalances) {
  const double epsilon = 0.01;
  final settlements = <Settlement>[];

  // Creditors: owed money (positive balance)
  final creditors = netBalances.entries
      .where((e) => e.value > epsilon)
      .map((e) => _Balance(e.key, e.value))
      .toList();

  // Debtors: owe money (negative balance stored as positive magnitude)
  final debtors = netBalances.entries
      .where((e) => e.value < -epsilon)
      .map((e) => _Balance(e.key, -e.value))
      .toList();

  // Sort descending
  creditors.sort((a, b) => b.amount.compareTo(a.amount));
  debtors.sort((a, b) => b.amount.compareTo(a.amount));

  int ci = 0;
  int di = 0;

  while (ci < creditors.length && di < debtors.length) {
    final creditor = creditors[ci];
    final debtor = debtors[di];

    final settle = creditor.amount < debtor.amount
        ? creditor.amount
        : debtor.amount;

    if (settle > epsilon) {
      settlements.add(Settlement(
        fromMemberId: debtor.id,
        toMemberId: creditor.id,
        amount: double.parse(settle.toStringAsFixed(2)),
      ));
    }

    creditor.amount -= settle;
    debtor.amount -= settle;

    if (creditor.amount < epsilon) ci++;
    if (debtor.amount < epsilon) di++;
  }

  return settlements;
}

class _Balance {
  final String id;
  double amount;
  _Balance(this.id, this.amount);
}
