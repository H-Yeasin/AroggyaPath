import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import 'package:provider/provider.dart';

import '../../../providers/dependent_provider.dart';

class AddDependentScreen extends StatefulWidget {
  const AddDependentScreen({super.key});

  @override
  State<AddDependentScreen> createState() => _AddDependentScreenState();
}

class _AddDependentScreenState extends State<AddDependentScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _relationship = 'Spouse';
  String _gender = 'Male';
  DateTime? _dob;

  final _relationships = ['Spouse', 'Child', 'Parent', 'Sibling', 'Other'];
  final _genders = ['Male', 'Female', 'Other'];

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
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Date of birth is required'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final success = await context.read<DependentProvider>().createDependent(
          fullName: _nameController.text.trim(),
          relationship: _relationship,
          gender: _gender,
          dob: _dob!,
          phone: _phoneController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Family member added!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Add Family Member',
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

          // Relationship dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: _relationship,
              decoration: const InputDecoration(
                  labelText: 'Relationship', border: InputBorder.none),
              items: _relationships
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _relationship = v!),
            ),
          ),
          const SizedBox(height: 16),

          // Gender
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                  labelText: 'Gender', border: InputBorder.none),
              items: _genders
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v!),
            ),
          ),
          const SizedBox(height: 16),

          // DOB
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_dob != null
                  ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                  : 'Select Date of Birth'),
              leading:
                  Icon(Icons.calendar_today, color: colors.primary),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dob ?? DateTime(2000),
                  firstDate: DateTime(1930),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dob = picked);
              },
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
