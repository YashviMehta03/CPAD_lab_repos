import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../models/split_type.dart';
import '../providers/expense_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  final Expense? existingExpense;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    this.existingExpense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  SplitType _splitType = SplitType.equal;
  String _category = 'Other';
  String? _paidByMemberId;
  Set<String> _selectedMemberIds = {};
  final Map<String, TextEditingController> _customControllers = {};

  static const List<String> _categories = ['Food', 'Travel', 'Stay', 'Entertainment', 'Other'];

  bool get _isEditing => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingExpense;
    if (existing != null) {
      _descController.text = existing.description;
      _amountController.text = existing.amount.toStringAsFixed(2);
      _splitType = existing.splitType;
      _category = existing.category;
      _paidByMemberId = existing.paidByMemberId;
      _selectedMemberIds = existing.splitAmong.keys.toSet();
    } else {
      // Default: select all members
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final members = context.read<GroupProvider>().getGroupMembers(widget.groupId);
        setState(() {
          _selectedMemberIds = members.map((m) => m.id).toSet();
          if (members.isNotEmpty) _paidByMemberId = members.first.id;
        });
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getCustomController(String memberId) {
    _customControllers.putIfAbsent(memberId, () {
      final existing = widget.existingExpense;
      final initialValue = existing?.splitAmong[memberId];
      return TextEditingController(
        text: initialValue?.toStringAsFixed(2) ?? '',
      );
    });
    return _customControllers[memberId]!;
  }

  Map<String, double> _computeSplitAmong(double totalAmount) {
    final selectedIds = _selectedMemberIds.toList();
    if (selectedIds.isEmpty) return {};

    switch (_splitType) {
      case SplitType.equal:
        final share = totalAmount / selectedIds.length;
        return {for (final id in selectedIds) id: share};

      case SplitType.custom:
        final result = <String, double>{};
        for (final id in selectedIds) {
          result[id] = double.tryParse(
                  _customControllers[id]?.text ?? '0') ??
              0;
        }
        return result;

      case SplitType.percentage:
        final result = <String, double>{};
        for (final id in selectedIds) {
          final pct =
              double.tryParse(_customControllers[id]?.text ?? '0') ?? 0;
          result[id] = totalAmount * pct / 100;
        }
        return result;
    }
  }

  String? _validateCustomSplit(double totalAmount) {
    if (_splitType == SplitType.equal) return null;
    final selectedIds = _selectedMemberIds.toList();

    if (_splitType == SplitType.custom) {
      double sum = 0;
      for (final id in selectedIds) {
        sum += double.tryParse(_customControllers[id]?.text ?? '0') ?? 0;
      }
      if ((sum - totalAmount).abs() > 0.01) {
        return 'Amounts must sum to ₹${totalAmount.toStringAsFixed(2)} (currently ₹${sum.toStringAsFixed(2)})';
      }
    }

    if (_splitType == SplitType.percentage) {
      double sum = 0;
      for (final id in selectedIds) {
        sum += double.tryParse(_customControllers[id]?.text ?? '0') ?? 0;
      }
      if ((sum - 100).abs() > 0.01) {
        return 'Percentages must sum to 100% (currently ${sum.toStringAsFixed(1)}%)';
      }
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paidByMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select who paid.')),
      );
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one member.')),
      );
      return;
    }

    final totalAmount = double.parse(_amountController.text);
    final validationError = _validateCustomSplit(totalAmount);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final splitAmong = _computeSplitAmong(totalAmount);

    if (_isEditing) {
      await context.read<ExpenseProvider>().updateExpense(
            expenseId: widget.existingExpense!.id,
            description: _descController.text.trim(),
            amount: totalAmount,
            paidByMemberId: _paidByMemberId!,
            splitType: _splitType,
            splitAmong: splitAmong,
            category: _category,
          );
    } else {
      await context.read<ExpenseProvider>().addExpense(
            groupId: widget.groupId,
            description: _descController.text.trim(),
            amount: totalAmount,
            paidByMemberId: _paidByMemberId!,
            splitType: _splitType,
            splitAmong: splitAmong,
            category: _category,
          );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final members =
        context.watch<GroupProvider>().getGroupMembers(widget.groupId);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Description
            _sectionLabel('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'e.g. Dinner, Hotel, Taxi',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description required'
                  : null,
            ),
            const SizedBox(height: 20),
            
            // Category
            _sectionLabel('Category'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 20),

            // Amount
            _sectionLabel('Amount (₹)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Amount required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Paid By
            _sectionLabel('Paid By'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _paidByMemberId,
              dropdownColor: AppTheme.surfaceDark,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outlined),
              ),
              hint: const Text('Who paid?'),
              items: members.map((m) {
                final color =
                    Color(int.parse('FF${m.colorHex}', radix: 16));
                return DropdownMenuItem(
                  value: m.id,
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(m.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _paidByMemberId = v),
              validator: (v) => v == null ? 'Select who paid' : null,
            ),
            const SizedBox(height: 20),

            // Split Type
            _sectionLabel('Split Type'),
            const SizedBox(height: 8),
            Row(
              children: SplitType.values.map((type) {
                final label = type.name[0].toUpperCase() +
                    type.name.substring(1);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _splitType == type,
                    onSelected: (_) =>
                        setState(() => _splitType = type),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Members selection
            _sectionLabel('Split Among'),
            const SizedBox(height: 8),
            ...members.map((m) {
              final color = Color(int.parse('FF${m.colorHex}', radix: 16));
              final isSelected = _selectedMemberIds.contains(m.id);

              return Column(
                children: [
                  CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 0),
                    activeColor: AppTheme.primary,
                    secondary: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          m.name[0].toUpperCase(),
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ),
                    ),
                    title: Text(m.name,
                        style: const TextStyle(color: Colors.white)),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedMemberIds.add(m.id);
                        } else {
                          _selectedMemberIds.remove(m.id);
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  // Custom/percentage input per member
                  if (isSelected && _splitType != SplitType.equal) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextFormField(
                        controller: _getCustomController(m.id),
                        decoration: InputDecoration(
                          hintText: _splitType == SplitType.percentage
                              ? 'e.g. 33.33 %'
                              : 'Amount for ${m.name}',
                          prefixIcon: Icon(
                            _splitType == SplitType.percentage
                                ? Icons.percent
                                : Icons.currency_rupee,
                            size: 18,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ],
              );
            }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white54,
        letterSpacing: 0.8,
      ),
    );
  }
}
