import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/appointment_model.dart';
import '../../../providers/appointment_provider.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  String _selectedTab = 'Pending';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AppointmentProvider>().fetchAppointments());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Appointment Management',
            style: TextStyle(
                color: Color(0xFF1B2C49),
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<AppointmentModel> appointments;
          switch (_selectedTab) {
            case 'Pending':
              appointments = provider.pendingAppointments;
              break;
            case 'Accepted':
              appointments = provider.acceptedAppointments;
              break;
            case 'Completed':
              appointments = provider.completedAppointments;
              break;
            default:
              appointments = [];
          }

          return Column(children: [
            // Tab bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                  children: ['Pending', 'Accepted', 'Completed'].map((tab) {
                final isSelected = _selectedTab == tab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF1664CD) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(tab,
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ),
                );
              }).toList()),
            ),

            // List
            Expanded(
              child: appointments.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No $_selectedTab appointments',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey)),
                          ]),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchAppointments(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) => _buildAppointmentCard(
                            appointments[index], provider),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(
      AppointmentModel apt, AppointmentProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
          ]),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE3F2FD),
              child: Text(
                  apt.patientName?.isNotEmpty == true
                      ? apt.patientName![0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF1664CD)))),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(apt.patientName ?? 'Patient',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(apt.formattedDate,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              if (apt.symptoms != null && apt.symptoms!.isNotEmpty)
                Text(apt.symptoms!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(apt.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(apt.status.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(apt.status))),
          ),
        ]),
        if (apt.status.toLowerCase() == 'pending') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => provider.acceptAppointment(apt.id),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child:
                    const Text('Accept', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => provider.cancelAppointment(apt.id),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('Reject'),
              ),
            ),
          ]),
        ],
        if (apt.status.toLowerCase() == 'accepted') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCompleteDialog(apt, provider),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1664CD),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Complete Appointment',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ]),
    );
  }

  Future<void> _showCompleteDialog(
      AppointmentModel apt, AppointmentProvider provider) async {
    final priceCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Appointment'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Patient: ${apt.patientName ?? "Unknown"}'),
          const SizedBox(height: 16),
          TextField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Consultation Fee', border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Complete')),
        ],
      ),
    );
    if (result == true && mounted) {
      final price = double.tryParse(priceCtrl.text) ?? 0;
      await provider.completeAppointment(
        appointmentId: apt.id,
        patientName: apt.patientName ?? 'Patient',
        price: price,
      );
    }
  }

  Color _statusColor(String status) {
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
