import 'package:hive/hive.dart';

part 'member_model.g.dart';

@HiveType(typeId: 1)
class Member extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String groupId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late String colorHex;

  Member({
    required this.id,
    required this.groupId,
    required this.name,
    required this.colorHex,
  });
}
