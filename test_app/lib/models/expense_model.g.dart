// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 2;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      groupId: fields[1] as String,
      description: fields[2] as String,
      amount: fields[3] as double,
      paidByMemberId: fields[4] as String,
      date: fields[5] as DateTime,
      splitType: fields[6] as SplitType,
      splitAmong: (fields[7] as Map).cast<String, double>(),
      isSettlement: fields[8] as bool,
      category: fields[9] == null ? 'Other' : fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.paidByMemberId)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.splitType)
      ..writeByte(7)
      ..write(obj.splitAmong)
      ..writeByte(8)
      ..write(obj.isSettlement)
      ..writeByte(9)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
