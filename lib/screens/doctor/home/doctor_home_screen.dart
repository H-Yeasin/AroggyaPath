import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/appointment_provider.dart';
import '../../../providers/user_provider.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().fetchAppointments();
      context.read<UserProvider>().fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final user = context.watch<UserProvider>().user;
    final appointments = context.watch<AppointmentProvider>();

    final pending = appointments.pendingAppointments.length;
    final accepted = appointments.acceptedAppointments.length;
    final completed = appointments.completedAppointments.length;
    final todayTotal = appointments.upcomingAppointments.where((a) {
      final now = DateTime.now();
      return a.appointmentDate.year == now.year &&
          a.appointmentDate.month == now.month &&
          a.appointmentDate.day == now.day;
    }).length;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.primaryContainer,
                child: user?.profileImage != null
                    ? ClipOval(
                        child: Image.network(user!.profileImage!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.person, color: colors.primary)))
                    : Icon(Icons.person, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. ${user?.fullName ?? "Doctor"}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colors.heading)),
                      Text(user?.specialty ?? 'Specialist',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                    ]),
              ),
            ]),
            const SizedBox(height: 28),

            // Stats cards
            Text('Today\'s Overview',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.heading)),
            const SizedBox(height: 16),
            Row(children: [
              _buildStatCard('Pending', '$pending', Colors.orange),
              const SizedBox(width: 12),
              _buildStatCard('Today', '$todayTotal', colors.primary),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildStatCard('Accepted', '$accepted', Colors.green),
              const SizedBox(width: 12),
              _buildStatCard('Completed', '$completed', Colors.blue),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildStatCard('Video Points', '${user?.points ?? 0}',
                  Colors.deepPurple),
              const SizedBox(width: 12),
              _buildStatCard(
                  'Video Calls',
                  '${appointments.completedAppointments.where((a) => a.isVideoCall).length}',
                  Colors.indigo),
            ]),
            const SizedBox(height: 28),

            // Upcoming appointments
            Text('Upcoming Appointments',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.heading)),
            const SizedBox(height: 16),
            if (appointments.upcomingAppointments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: const Column(children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No upcoming appointments',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ]),
              )
            else
              ...appointments.upcomingAppointments.take(5).map(
                    (apt) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8)
                          ]),
                      child: Row(children: [
                        CircleAvatar(
                            radius: 24,
                            backgroundColor: colors.primaryContainer,
                            child: Text(
                                apt.patientName?.isNotEmpty == true
                                    ? apt.patientName![0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary))),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(apt.patientName ?? 'Patient',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(apt.formattedDate,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text(apt.appointmentTypeLabel,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: apt.isVideoCall
                                            ? Colors.indigo
                                            : Colors.teal)),
                              ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: apt.status == 'pending'
                                ? Colors.orange.withValues(alpha: 0.15)
                                : Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(apt.status.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: apt.status == 'pending'
                                      ? Colors.orange
                                      : Colors.green)),
                        ),
                      ]),
                    ),
                  ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(count,
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ]),
      ),
    );
  }
}
