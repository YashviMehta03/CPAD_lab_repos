import 'package:hive/hive.dart';
import 'split_type.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 2)
class Expense extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String groupId;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late double amount;

  @HiveField(4)
  late String paidByMemberId;

  @HiveField(5)
  late DateTime date;

  @HiveField(6)
  late SplitType splitType;

  /// memberId -> amount owed by that member for this expense
  @HiveField(7)
  late Map<String, double> splitAmong;

  /// True if this entry is a "settle up" payment (not a real expense)
  @HiveField(8)
  late bool isSettlement;

  @HiveField(9, defaultValue: 'Other')
  late String category;

  Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidByMemberId,
    required this.date,
    required this.splitType,
    required this.splitAmong,
    this.isSettlement = false,
    this.category = 'Other',
  });
}
