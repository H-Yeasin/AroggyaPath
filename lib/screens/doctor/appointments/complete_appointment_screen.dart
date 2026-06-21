import 'dart:io';

import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/appointment_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/user_provider.dart';
import '../../shared/appointment_chat_screen.dart';

class CompleteAppointmentScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const CompleteAppointmentScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<CompleteAppointmentScreen> createState() =>
      _CompleteAppointmentScreenState();
}

class _CompleteAppointmentScreenState extends State<CompleteAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _picker = ImagePicker();

  String _recordType = 'prescription';
  final List<File> _files = [];
  bool _isSubmitting = false;

  static const _recordTypes = {
    'prescription': 'Prescription',
    'summary': 'Summary',
    'lab_report': 'Lab Report',
    'follow_up': 'Follow-up',
    'other': 'Other',
  };

  @override
  void dispose() {
    _priceCtrl.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    setState(() {
      _files
        ..clear()
        ..addAll(picked.take(5).map((file) => File(file.path)));
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medical record image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<AppointmentProvider>();
    final success = await provider.completeAppointment(
      appointmentId: widget.appointment.id,
      patientName: widget.appointment.patientName ?? 'Patient',
      price: double.parse(_priceCtrl.text.trim()),
      files: _files,
      recordType: _recordType,
      title: _titleCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment completed')),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Could not complete')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Complete Appointment',
          style: TextStyle(color: colors.heading, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_canOpenChat(widget.appointment))
            IconButton(
              tooltip: 'Chat',
              icon: Icon(Icons.chat_bubble_outline, color: colors.primaryDark),
              onPressed: _openChat,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildPatientSummary(colors),
              const SizedBox(height: 18),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Consultation Fee',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount < 0) {
                    return 'Enter a valid fee';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _recordType,
                decoration: const InputDecoration(
                  labelText: 'Record Type',
                  border: OutlineInputBorder(),
                ),
                items: _recordTypes.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _recordType = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickImages,
                icon: const Icon(Icons.attach_file),
                label: Text(_files.isEmpty ? 'Attach Image' : 'Change Images'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (_files.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _files.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _files[index],
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle, color: Colors.white),
                label: Text(_isSubmitting ? 'Completing...' : 'Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canOpenChat(AppointmentModel appointment) {
    final status = appointment.status.toLowerCase();
    return status == 'accepted' || status == 'confirmed';
  }

  void _openChat() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = (userProvider.user?.role ?? 'doctor').toLowerCase();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentChatScreen(
          appointmentId: widget.appointment.id,
          title: widget.appointment.patientName ?? 'Patient Chat',
          receiverId: widget.appointment.patientId,
          receiverAvatar: widget.appointment.patientImage,
          userRole: userRole,
        ),
      ),
    );
  }

  Widget _buildPatientSummary(AroggyaColors colors) {
    final appointment = widget.appointment;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.primaryContainer,
            child: Text(
              appointment.patientName?.isNotEmpty == true
                  ? appointment.patientName![0].toUpperCase()
                  : 'P',
              style: TextStyle(color: colors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName ?? 'Patient',
                  style: TextStyle(
                    color: colors.heading,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${appointment.formattedDate} at ${appointment.appointmentTime}',
                  style: TextStyle(color: colors.bodyText, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
