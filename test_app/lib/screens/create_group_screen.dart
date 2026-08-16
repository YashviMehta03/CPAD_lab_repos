import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final List<TextEditingController> _memberControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with the logged-in user's display name
    final authProvider = context.read<AuthProvider>();
    _memberControllers.add(
      TextEditingController(text: authProvider.displayName),
    );
    _memberControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (final c in _memberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMemberField() {
    setState(() => _memberControllers.add(TextEditingController()));
  }

  void _removeMemberField(int index) {
    if (_memberControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A group needs at least 2 members.')),
      );
      return;
    }
    setState(() {
      _memberControllers[index].dispose();
      _memberControllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final names = _memberControllers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (names.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 members.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await context.read<GroupProvider>().createGroup(
          _groupNameController.text.trim(),
          names,
        );
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
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
            // Group name section
            _sectionLabel('Group Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Goa Trip, Roommates',
                prefixIcon: Icon(Icons.group_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Group name is required'
                  : null,
            ),
            const SizedBox(height: 28),
            _sectionLabel('Members'),
            const SizedBox(height: 4),
            const Text(
              'Add the people splitting expenses in this group.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 12),
            // Member input rows
            ...List.generate(_memberControllers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _memberControllers[i],
                        decoration: InputDecoration(
                          hintText: 'Member ${i + 1} name',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (i < 2 && (v == null || v.trim().isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (i >= 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppTheme.negative),
                        onPressed: () => _removeMemberField(i),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            // Add member button
            OutlinedButton.icon(
              onPressed: _addMemberField,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Another Member'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
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
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white54,
        letterSpacing: 0.8,
      ),
    );
  }
}
