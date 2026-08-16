import 'package:hive/hive.dart';

part 'split_type.g.dart';

@HiveType(typeId: 3)
enum SplitType {
  @HiveField(0)
  equal,
  @HiveField(1)
  custom,
  @HiveField(2)
  percentage,
}
