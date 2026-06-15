import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/dependent_provider.dart';
import '../../../models/dependent_model.dart';

class EditDependentScreen extends StatefulWidget {
  final DependentModel dependent;
  const EditDependentScreen({super.key, required this.dependent});

  @override
  State<EditDependentScreen> createState() => _EditDependentScreenState();
}

class _EditDependentScreenState extends State<EditDependentScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late String _relationship;
  late String _gender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dependent.fullName);
    _phoneController =
        TextEditingController(text: widget.dependent.phone ?? '');
    _relationship = widget.dependent.relationship ?? 'Other';
    _gender = widget.dependent.gender ?? 'Other';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name is required'), backgroundColor: Colors.red),
      );
      return;
    }
    final success = await context.read<DependentProvider>().updateDependent(
          dependentId: widget.dependent.id,
          fullName: _nameController.text.trim(),
          relationship: _relationship,
          gender: _gender,
          phone: _phoneController.text.trim(),
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Updated!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final relationships = ['Spouse', 'Child', 'Parent', 'Sibling', 'Other'];
    final genders = ['Male', 'Female', 'Other'];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Edit ${widget.dependent.fullName}',
            style: TextStyle(color: colors.heading)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Save',
                style: TextStyle(
                    color: colors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _buildTextField('Full Name', _nameController),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonFormField<String>(
              value: _relationship,
              decoration: const InputDecoration(
                  labelText: 'Relationship', border: InputBorder.none),
              items: relationships
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _relationship = v!),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                  labelText: 'Gender', border: InputBorder.none),
              items: genders
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v!),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
              'Phone (optional)', _phoneController, TextInputType.phone),
        ]),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      [TextInputType? keyboardType]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none),
      ),
    );
  }
}
