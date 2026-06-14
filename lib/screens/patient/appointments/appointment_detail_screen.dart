import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/appointment_model.dart';
import '../../../providers/appointment_provider.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppointmentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3267)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Appointment Details',
            style: TextStyle(
                color: Color(0xFF1B2C49), fontWeight: FontWeight.bold)),
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
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: appointment.doctorImage != null &&
                          appointment.doctorImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                              appointment.doctorImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.person,
                                      color: Color(0xFF1664CD))))
                      : const Icon(Icons.person,
                          color: Color(0xFF1664CD)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.doctorName ?? 'Doctor',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2C49))),
                      const SizedBox(height: 4),
                      Text(appointment.specialty ?? '',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600])),
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
                      Icons.calendar_today, 'Date',
                      appointment.formattedDate),
                  const Divider(height: 24),
                  _buildDetailRow(
                      Icons.access_time, 'Time',
                      appointment.appointmentTime ?? 'N/A'),
                  const Divider(height: 24),
                  _buildDetailRow(
                      Icons.medical_services, 'Type',
                      appointment.appointmentType ?? 'Physical Visit'),
                  if (appointment.symptoms != null &&
                      appointment.symptoms!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                        Icons.description, 'Symptoms',
                        appointment.symptoms!),
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
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(appointment.status.toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  _getStatusColor(appointment.status))),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            if (appointment.status.toLowerCase() == 'pending' ||
                appointment.status.toLowerCase() == 'accepted') ...[
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
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: const Text('No')),
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: const Text('Yes, Cancel',
                                  style:
                                      TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await provider
                          .cancelAppointment(appointment.id);
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
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: Color(0xFF1B2C49))),
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
