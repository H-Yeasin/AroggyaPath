import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/appointment_model.dart';
import '../../../../providers/appointment_provider.dart';

class UpcomingAppointmentSection extends StatelessWidget {
  const UpcomingAppointmentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        final appointment = _nextAppointment(
          appointmentProvider.upcomingAppointments,
        );

        if (appointment == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upcoming Appointment',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: colors.heading,
                ),
              ),
              const SizedBox(height: 15),
              UpcomingAppointmentCard(appointment: appointment),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }

  AppointmentModel? _nextAppointment(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming = appointments.where((appointment) {
      final appointmentDay = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
      );

      return appointmentDay.isAtSameMomentAs(today) ||
          appointmentDay.isAfter(today);
    }).toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    return upcoming.isEmpty ? null : upcoming.first;
  }
}

class UpcomingAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const UpcomingAppointmentCard({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today, color: colors.success, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName ?? 'Doctor',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colors.heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.specialty ?? '',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      appointment.formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _AppointmentStatusBadge(status: appointment.status),
        ],
      ),
    );
  }
}

class _AppointmentStatusBadge extends StatelessWidget {
  final String status;

  const _AppointmentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    late final Color bgColor;
    late final Color textColor;
    late final String label;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = colors.statusPendingBg;
        textColor = Colors.orange;
        label = 'Pending';
        break;
      case 'accepted':
        bgColor = colors.statusAcceptedBg;
        textColor = Colors.green;
        label = 'Accepted';
        break;
      case 'completed':
        bgColor = colors.primaryContainer;
        textColor = Colors.blue;
        label = 'Completed';
        break;
      case 'cancelled':
        bgColor = colors.statusCancelledBg;
        textColor = Colors.red;
        label = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
