import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import '../models/member_model.dart';

const _memberColors = [
  'FF6B6B', 'FFD93D', '6BCB77', '4D96FF', 'C77DFF',
  'FF9F1C', '2EC4B6', 'E71D36', 'FF9F43', '5F27CD',
];

class GroupProvider extends ChangeNotifier {
  static const String _groupBox = 'groupBox';
  static const String _memberBox = 'memberBox';

  late Box<Group> _groups;
  late Box<Member> _members;

  final _uuid = const Uuid();

  List<Group> get groups => _groups.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> init() async {
    _groups = Hive.box<Group>(_groupBox);
    _members = Hive.box<Member>(_memberBox);
  }

  List<Member> getGroupMembers(String groupId) {
    return _members.values
        .where((m) => m.groupId == groupId)
        .toList();
  }

  Member? getMember(String memberId) {
    try {
      return _members.values.firstWhere((m) => m.id == memberId);
    } catch (_) {
      return null;
    }
  }

  Future<Group> createGroup(String name, List<String> memberNames) async {
    final groupId = _uuid.v4();
    final now = DateTime.now();
    final group = Group(
      id: groupId,
      name: name,
      createdAt: now,
      memberIds: [],
    );
    await _groups.put(groupId, group);

    final List<String> memberIds = [];
    for (int i = 0; i < memberNames.length; i++) {
      final memberId = _uuid.v4();
      final colorHex = _memberColors[i % _memberColors.length];
      final member = Member(
        id: memberId,
        groupId: groupId,
        name: memberNames[i].trim(),
        colorHex: colorHex,
      );
      await _members.put(memberId, member);
      memberIds.add(memberId);
    }

    group.memberIds = memberIds;
    await group.save();
    notifyListeners();
    return group;
  }

  Future<void> updateGroup(String groupId, String newName) async {
    final group = _groups.get(groupId);
    if (group != null) {
      group.name = newName;
      await group.save();
      notifyListeners();
    }
  }

  Future<void> addMember(String groupId, String memberName) async {
    final group = _groups.get(groupId);
    if (group == null) return;
    final existingCount = getGroupMembers(groupId).length;
    final memberId = _uuid.v4();
    final colorHex = _memberColors[existingCount % _memberColors.length];
    final member = Member(
      id: memberId,
      groupId: groupId,
      name: memberName.trim(),
      colorHex: colorHex,
    );
    await _members.put(memberId, member);
    group.memberIds = [...group.memberIds, memberId];
    await group.save();
    notifyListeners();
  }

  Future<void> deleteGroup(String groupId) async {
    // Delete all members of the group
    final memberIds = _members.values
        .where((m) => m.groupId == groupId)
        .map((m) => m.id)
        .toList();
    for (final id in memberIds) {
      await _members.delete(id);
    }
    await _groups.delete(groupId);
    notifyListeners();
  }
}
