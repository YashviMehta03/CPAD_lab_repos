import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../models/split_type.dart';
import '../services/debt_simplifier.dart';

class ExpenseProvider extends ChangeNotifier {
  static const String _expenseBox = 'expenseBox';

  late Box<Expense> _expenses;
  final _uuid = const Uuid();

  Future<void> init() async {
    _expenses = Hive.box<Expense>(_expenseBox);
  }

  List<Expense> getGroupExpenses(String groupId) {
    return _expenses.values
        .where((e) => e.groupId == groupId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Computes net balance for each member in the group.
  /// Positive = owed money, Negative = owes money.
  Map<String, double> computeNetBalances(String groupId) {
    final expenses = getGroupExpenses(groupId);
    final Map<String, double> balances = {};

    for (final expense in expenses) {
      // Payer gets credit for what they paid
      balances[expense.paidByMemberId] =
          (balances[expense.paidByMemberId] ?? 0) + expense.amount;

      // Each member in splitAmong owes their share
      expense.splitAmong.forEach((memberId, amount) {
        balances[memberId] = (balances[memberId] ?? 0) - amount;
      });
    }

    return balances;
  }

  /// Gets the total spend per category (excluding settlements)
  Map<String, double> getCategoryBreakdown(String groupId) {
    final expenses = getGroupExpenses(groupId).where((e) => !e.isSettlement);
    final Map<String, double> breakdown = {};
    for (final e in expenses) {
      breakdown[e.category] = (breakdown[e.category] ?? 0) + e.amount;
    }
    return breakdown;
  }

  /// Computes raw pairwise debts directly from expense records.
  /// Each expense contributes: member-in-splitAmong owes paidByMember their share.
  /// Opposing debts for the same pair are netted out.
  /// This is the "before simplification" view — typically has MORE entries than simplifyDebts().
  List<Settlement> computeRawSettlements(String groupId) {
    final expenses = getGroupExpenses(groupId);

    // Accumulate pairwise totals: 'fromId|toId' -> total owed
    final Map<String, double> pairTotals = {};

    for (final expense in expenses) {
      final payer = expense.paidByMemberId;
      expense.splitAmong.forEach((memberId, share) {
        if (memberId == payer) return; // skip self-payment
        // memberId owes payer `share`
        final key = '$memberId|$payer';
        pairTotals[key] = (pairTotals[key] ?? 0) + share;
      });
    }

    // Net out opposing pairs: A->B 100, B->A 40  →  A->B 60
    const epsilon = 0.01;
    final processed = <String>{};
    final result = <Settlement>[];

    pairTotals.forEach((key, amount) {
      if (processed.contains(key)) return;
      final parts = key.split('|');
      final from = parts[0];
      final to = parts[1];
      final reverseKey = '$to|$from';
      final reverseAmount = pairTotals[reverseKey] ?? 0;
      processed.add(key);
      processed.add(reverseKey);

      final net = amount - reverseAmount;
      if (net > epsilon) {
        result.add(Settlement(
          fromMemberId: from,
          toMemberId: to,
          amount: double.parse(net.toStringAsFixed(2)),
        ));
      } else if (net < -epsilon) {
        result.add(Settlement(
          fromMemberId: to,
          toMemberId: from,
          amount: double.parse((-net).toStringAsFixed(2)),
        ));
      }
    });

    return result;
  }

  Future<void> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidByMemberId,
    required SplitType splitType,
    required Map<String, double> splitAmong,
    bool isSettlement = false,
    String category = 'Other',
  }) async {
    final id = _uuid.v4();
    final expense = Expense(
      id: id,
      groupId: groupId,
      description: description,
      amount: amount,
      paidByMemberId: paidByMemberId,
      date: DateTime.now(),
      splitType: splitType,
      splitAmong: splitAmong,
      isSettlement: isSettlement,
      category: category,
    );
    await _expenses.put(id, expense);
    notifyListeners();
  }

  Future<void> updateExpense({
    required String expenseId,
    required String description,
    required double amount,
    required String paidByMemberId,
    required SplitType splitType,
    required Map<String, double> splitAmong,
    required String category,
  }) async {
    final expense = _expenses.get(expenseId);
    if (expense == null) return;
    expense.description = description;
    expense.amount = amount;
    expense.paidByMemberId = paidByMemberId;
    expense.splitType = splitType;
    expense.splitAmong = splitAmong;
    expense.category = category;
    await expense.save();
    notifyListeners();
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expenses.delete(expenseId);
    notifyListeners();
  }

  /// Records a "mark as paid" settlement as a special expense entry.
  Future<void> recordSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
  }) async {
    await addExpense(
      groupId: groupId,
      description: 'Settlement payment',
      amount: amount,
      paidByMemberId: fromMemberId,
      splitType: SplitType.custom,
      splitAmong: {toMemberId: amount},
      isSettlement: true,
      category: 'Settlement',
    );
  }

  Future<void> deleteGroupExpenses(String groupId) async {
    final keys = _expenses.values
        .where((e) => e.groupId == groupId)
        .map((e) => e.id)
        .toList();
    for (final key in keys) {
      await _expenses.delete(key);
    }
    notifyListeners();
  }
}
