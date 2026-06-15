import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../models/appointment_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/user_provider.dart';
import '../../patient/appointments/appointment_detail_screen.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  static const List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  List<DaySchedule> _schedule = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSchedule();
      context.read<AppointmentProvider>().fetchAppointments();
    });
  }

  void _initSchedule() {
    final user = context.read<UserProvider>().user;
    final existing = user?.weeklySchedule;

    setState(() {
      _schedule = _daysOfWeek.map((day) {
        DaySchedule? existingDay;
        if (existing != null) {
          for (final d in existing) {
            if (d.day.toLowerCase() == day.toLowerCase()) {
              existingDay = d;
              break;
            }
          }
        }
        return DaySchedule(
          day: day,
          isActive: existingDay?.isActive ?? false,
          slots: List<TimeSlot>.from(existingDay?.slots ?? []),
        );
      }).toList();
      _isLoading = false;
    });
  }

  void _toggleDay(int index) {
    setState(() {
      _schedule[index] = DaySchedule(
        day: _schedule[index].day,
        isActive: !_schedule[index].isActive,
        slots: _schedule[index].slots,
      );
    });
  }

  Future<void> _addTimeSlot(int dayIndex) async {
    final colors = AppTheme.of(context);

    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Select Start Time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: colors.primary),
        ),
        child: child!,
      ),
    );
    if (startTime == null || !mounted) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: startTime.hour + 1,
        minute: startTime.minute,
      ),
      helpText: 'Select End Time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: colors.primary),
        ),
        child: child!,
      ),
    );
    if (endTime == null || !mounted) return;

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check for overlap with existing slots
    for (final slot in _schedule[dayIndex].slots ?? []) {
      final sMin = _timeToMinutes(slot.start);
      final eMin = _timeToMinutes(slot.end);
      if (startMinutes < eMin && endMinutes > sMin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This time slot overlaps with an existing slot'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final startStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    setState(() {
      final updatedSlots = List<TimeSlot>.from(_schedule[dayIndex].slots ?? [])
        ..add(TimeSlot(start: startStr, end: endStr));
      _schedule[dayIndex] = DaySchedule(
        day: _schedule[dayIndex].day,
        isActive: _schedule[dayIndex].isActive,
        slots: updatedSlots,
      );
    });
  }

  void _removeTimeSlot(int dayIndex, int slotIndex) {
    setState(() {
      final updatedSlots = List<TimeSlot>.from(_schedule[dayIndex].slots ?? [])
        ..removeAt(slotIndex);
      _schedule[dayIndex] = DaySchedule(
        day: _schedule[dayIndex].day,
        isActive: _schedule[dayIndex].isActive,
        slots: updatedSlots,
      );
    });
  }

  int _timeToMinutes(String time) {
    try {
      final clean = time.trim();
      // Handle "h:mm a" or "hh:mm a" format
      if (clean.toUpperCase().contains(RegExp(r'[AP]M'))) {
        final format = DateFormat('h:mm a');
        final dt = format.parse(clean);
        return dt.hour * 60 + dt.minute;
      }
      // Handle "HH:mm" format
      final parts = clean.split(':');
      return int.parse(parts[0].trim()) * 60 +
          int.parse(parts[1].trim().split(' ')[0]);
    } catch (e) {
      return 0;
    }
  }

  String _formatTime(String time) {
    try {
      final minutes = _timeToMinutes(time);
      final hour = minutes ~/ 60;
      final min = minutes % 60;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12
          ? hour - 12
          : (hour == 0 ? 12 : hour);
      return '$displayHour:${min.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  Future<void> _saveSchedule() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.saveWeeklySchedule(
        _schedule.map((d) => d.toJson()).toList(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = userProvider.error ?? 'Failed to save schedule';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final appointmentProvider = context.watch<AppointmentProvider>();
    final upcomingAppointments = appointmentProvider.upcomingAppointments;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Schedule',
          style: TextStyle(
            color: colors.heading,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: _isSaving || _isLoading ? null : _saveSchedule,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, size: 20),
              label: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: TextStyle(color: Colors.red.shade700)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Header
                  Text(
                    'Set Your Weekly Availability',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.heading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toggle days on and add time slots when you\'re available for appointments.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Day cards
                  ...List.generate(7, (index) => _buildDayCard(index, colors)),

                  const SizedBox(height: 24),

                  // Upcoming Appointments Section
                  if (upcomingAppointments.isNotEmpty) ...[
                    _buildAppointmentsSection(upcomingAppointments, colors),
                    const SizedBox(height: 24),
                  ],

                  // View all appointments button
                  if (upcomingAppointments.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to the doctor's main navigation appointments tab
                          Navigator.pushNamed(context, '/doctor-home');
                        },
                        icon: const Icon(Icons.calendar_month, size: 20),
                        label: const Text('View All Appointments'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildDayCard(int index, AroggyaColors colors) {
    final daySchedule = _schedule[index];
    final isActive = daySchedule.isActive;
    final slots = daySchedule.slots ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Day header with toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.primaryContainer
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      daySchedule.day.substring(0, 3),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isActive ? colors.primary : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        daySchedule.day,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: colors.heading,
                        ),
                      ),
                      if (isActive && slots.isNotEmpty)
                        Text(
                          '${slots.length} time slot${slots.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        )
                      else if (isActive)
                        Text(
                          'No time slots added',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[400],
                          ),
                        )
                      else
                        Text(
                          'Unavailable',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (_) => _toggleDay(index),
                  activeTrackColor: colors.primary.withValues(alpha: 0.5),
                  activeThumbColor: colors.primary,
                ),
              ],
            ),
          ),

          // Time slots list (only when active)
          if (isActive) ...[
            if (slots.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(slots.length, (slotIndex) {
                    final slot = slots[slotIndex];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${_formatTime(slot.start)} - ${_formatTime(slot.end)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _removeTimeSlot(index, slotIndex),
                            child: Icon(Icons.close,
                                size: 16, color: Colors.red.shade400),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

            // Add time slot button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addTimeSlot(index),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Time Slot'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(
                      color: colors.primary.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentsSection(
    List<AppointmentModel> appointments,
    AroggyaColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_available, size: 22, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'Upcoming Booked Appointments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.heading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...appointments.take(5).map((apt) => _buildAppointmentCard(apt, colors)),
        if (appointments.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${appointments.length - 5} more appointments',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(AppointmentModel apt, AroggyaColors colors) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetailScreen(appointment: apt),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.primaryContainer,
              backgroundImage: apt.patientImage != null
                  ? NetworkImage(apt.patientImage!)
                  : null,
              child: apt.patientImage == null
                  ? Icon(Icons.person, size: 20, color: colors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apt.patientName ?? 'Patient',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        apt.formattedDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        apt.appointmentTime,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (apt.bookedFor != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'For: ${apt.bookedFor!.bookingLabel}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(apt.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                apt.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _statusColor(apt.status),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
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
