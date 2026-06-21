import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:arogya_path3/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/appointment_model.dart';
import '../../../models/doctor_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/user_provider.dart';
import '../../shared/appointment_chat_screen.dart';
import '../doctor/book_appointment_screen.dart';
import '../medical_records/medical_records_screen.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final provider = context.read<AppointmentProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Appointment Details',
            style:
                TextStyle(color: colors.heading, fontWeight: FontWeight.bold)),
        actions: [
          if (_canOpenChat(appointment))
            IconButton(
              tooltip: 'Chat',
              icon: Icon(Icons.chat_bubble_outline, color: colors.primaryDark),
              onPressed: () => _openChat(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Doctor info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: appointment.doctorImage != null &&
                          appointment.doctorImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(appointment.doctorImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.person, color: colors.primary)))
                      : Icon(Icons.person, color: colors.primary),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.doctorName ?? 'Doctor',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.heading)),
                      const SizedBox(height: 4),
                      Text(appointment.specialty ?? '',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                      Icons.calendar_today, 'Date', appointment.formattedDate),
                  const Divider(height: 24),
                  _buildDetailRow(
                      Icons.access_time, 'Time', appointment.appointmentTime),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.medical_services, 'Type',
                      appointment.appointmentTypeLabel),
                  if (appointment.symptoms != null &&
                      appointment.symptoms!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                        Icons.description, 'Symptoms', appointment.symptoms!),
                  ],
                  const Divider(height: 24),
                  Row(children: [
                    const Icon(Icons.info, size: 18, color: Colors.grey),
                    const SizedBox(width: 12),
                    const Text('Status: ',
                        style: TextStyle(color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.status)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(appointment.patientStatusLabel,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(appointment.status))),
                    ),
                  ]),
                  if (appointment.reason != null &&
                      appointment.reason!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                        Icons.report_problem, 'Reason', appointment.reason!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (appointment.isVideoCall) ...[
              _buildVideoSupportCard(context),
              const SizedBox(height: 24),
            ],

            if (appointment.status.toLowerCase() == 'completed') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MedicalRecordsScreen(),
                    ),
                  ),
                  icon: Icon(Icons.folder_open, color: colors.primary),
                  label: const Text('View Medical Record'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Actions
            if (appointment.status.toLowerCase() == 'accepted' ||
                appointment.status.toLowerCase() == 'confirmed') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openReschedule(context),
                  icon: const Icon(Icons.event_repeat, color: Colors.white),
                  label: const Text('Reschedule Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else if (appointment.status.toLowerCase() == 'pending') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel Appointment'),
                        content: const Text(
                            'Are you sure you want to cancel this appointment?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('No')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Yes, Cancel',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await provider.cancelAppointment(appointment.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel Appointment',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canOpenChat(AppointmentModel appointment) {
    final status = appointment.status.toLowerCase();
    return status == 'accepted' || status == 'confirmed';
  }

  void _openChat(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.user?.role ?? 'patient';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentChatScreen(
          appointmentId: appointment.id,
          title: appointment.doctorName ?? 'Doctor Chat',
          receiverId: appointment.doctorId,
          receiverAvatar: appointment.doctorImage,
          userRole: userRole,
        ),
      ),
    );
  }

  Future<void> _openReschedule(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(
          doctor: _doctorFromAppointment(),
          isReschedule: true,
          existingAppointment: appointment,
        ),
      ),
    );

    if (context.mounted) {
      context.read<AppointmentProvider>().fetchAppointments();
    }
  }

  Doctor _doctorFromAppointment() {
    return Doctor(
      id: appointment.doctorId,
      name: appointment.doctorName ?? 'Doctor',
      fullName: appointment.doctorName ?? 'Doctor',
      specialty: appointment.specialty ?? '',
      image: appointment.doctorImage ?? 'assets/images/doctor_booking.png',
      rating: 0,
      reviews: 0,
      experience: '0',
      location: '',
    );
  }

  Widget _buildVideoSupportCard(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.support_agent, color: colors.primaryDark),
            const SizedBox(width: 10),
            Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.heading,
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openWhatsAppSupport(context),
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openMessengerSupport(context),
                icon: const Icon(Icons.message),
                label: const Text('Messenger'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0084FF),
                  side: const BorderSide(color: Color(0xFF0084FF)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  String _supportMessage() {
    return '''
I would like to book a video call appointment.
Doctor: ${appointment.doctorName ?? 'Doctor'}
Date: ${appointment.formattedDate}
Time: ${appointment.appointmentTime}
Patient: ${appointment.patientName ?? 'Patient'}
''';
  }

  Future<void> _openWhatsAppSupport(BuildContext context) async {
    if (officialSupportWhatsAppNumber.trim().isEmpty) {
      _showLaunchError(context, 'Support WhatsApp number is not configured.');
      return;
    }

    final uri = Uri.parse(
      'https://wa.me/$officialSupportWhatsAppNumber?text=${Uri.encodeComponent(_supportMessage().trim())}',
    );
    await _launchSupportUri(context, uri);
  }

  Future<void> _openMessengerSupport(BuildContext context) async {
    if (officialMessengerUrl.trim().isEmpty ||
        officialMessengerUrl.contains('yourPageUsername')) {
      _showLaunchError(context, 'Messenger page URL is not configured.');
      return;
    }

    await _launchSupportUri(context, Uri.parse(officialMessengerUrl));
  }

  Future<void> _launchSupportUri(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showLaunchError(context, 'Could not open support chat.');
    }
  }

  void _showLaunchError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading)),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
