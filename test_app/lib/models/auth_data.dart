import 'package:hive/hive.dart';

part 'auth_data.g.dart';

@HiveType(typeId: 4)
class AuthData extends HiveObject {
  @HiveField(0)
  late String displayName;

  @HiveField(1)
  late String username;

  @HiveField(2)
  late String passwordHash;

  @HiveField(3)
  late bool isLoggedIn;

  AuthData({
    required this.displayName,
    required this.username,
    required this.passwordHash,
    this.isLoggedIn = false,
  });
}
