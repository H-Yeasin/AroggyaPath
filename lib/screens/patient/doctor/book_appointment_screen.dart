import 'dart:convert';
import 'package:arogya_path3/core/constants/app_constants.dart';
import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:arogya_path3/core/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/appointment_model.dart';
import '../../../models/dependent_model.dart';
import '../../../models/doctor_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/dependent_provider.dart';
import '../../../providers/user_provider.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Doctor doctor;
  final bool isReschedule;
  final AppointmentModel? existingAppointment;

  const BookAppointmentScreen({
    super.key,
    required this.doctor,
    this.isReschedule = false,
    this.existingAppointment,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String selectedType = 'Physical Visit';
  DateTime? selectedDate;
  TimeSlot? selectedTimeSlot;
  DependentModel? selectedDependent;
  final TextEditingController _symptomsController = TextEditingController();

  final List<XFile> _medicalDocuments = [];
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  List<TimeSlot> availableSlots = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    if (widget.isReschedule && widget.existingAppointment != null) {
      final appt = widget.existingAppointment!;
      if (appt.appointmentType?.toLowerCase() == 'video') {
        selectedType = 'Video Call';
      } else {
        selectedType = 'Physical Visit';
      }
      if (appt.symptoms != null && appt.symptoms!.isNotEmpty) {
        _symptomsController.text = appt.symptoms!;
      }
      selectedDate = appt.appointmentDate;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DependentProvider>().fetchDependents();
    });
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final colors = AppTheme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: colors.primaryLight),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = null;
        availableSlots = [];
      });
      await _fetchAvailableSlots(picked);
    }
  }

  Future<void> _fetchAvailableSlots(DateTime date) async {
    setState(() => _isLoadingSlots = true);
    try {
      final response = await _fetchFromBackend(date);
      if (response != null && response['success'] == true) {
        final slotsData = response['data']['slots'] as List;
        final unbookedSlots = slotsData
            .map((slot) => TimeSlot.fromJson(slot))
            .expand(_splitIntoThirtyMinuteSlots)
            .where((slot) => slot.isBooked != true)
            .toList()
          ..sort((a, b) => _timeToMinutes(a.start).compareTo(
                _timeToMinutes(b.start),
              ));
        if (unbookedSlots.isEmpty) {
          _loadFromWeeklySchedule(date);
        } else {
          setState(() => availableSlots = unbookedSlots);
        }
      } else {
        _loadFromWeeklySchedule(date);
      }
    } catch (e) {
      _loadFromWeeklySchedule(date);
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchFromBackend(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}${ApiConfig.appointments}/available'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'doctorId': widget.doctor.id,
              'date': DateFormat('yyyy-MM-dd').format(date),
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Backend slot error: $e');
    }
    return null;
  }

  void _loadFromWeeklySchedule(DateTime date) {
    final doctor = widget.doctor;
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      setState(() => availableSlots = []);
      return;
    }
    final dayName = _getDayName(date);
    WeeklySchedule? daySchedule;
    for (var schedule in doctor.weeklySchedule!) {
      if (schedule.day.toLowerCase() == dayName.toLowerCase() &&
          schedule.isActive) {
        daySchedule = schedule;
        break;
      }
    }
    if (daySchedule == null) {
      setState(() => availableSlots = []);
      return;
    }
    final slots = daySchedule!.slots
        .expand(_splitIntoThirtyMinuteSlots)
        .toList()
      ..sort((a, b) => _timeToMinutes(a.start).compareTo(
            _timeToMinutes(b.start),
          ));
    setState(() => availableSlots = slots);
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  String _minutesToTime(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  List<TimeSlot> _splitIntoThirtyMinuteSlots(TimeSlot slot) {
    final startMinutes = _timeToMinutes(slot.start);
    final endMinutes = _timeToMinutes(slot.end);
    if (startMinutes >= endMinutes) return [];

    final slots = <TimeSlot>[];
    for (var current = startMinutes; current + 30 <= endMinutes; current += 30) {
      slots.add(TimeSlot(
        start: _minutesToTime(current),
        end: _minutesToTime(current + 30),
        isBooked: slot.isBooked,
      ));
    }
    return slots;
  }

  String _getDayName(DateTime date) {
    const dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return dayNames[date.weekday - 1];
  }

  Future<void> _pickMedicalDocuments() async {
    final List<XFile> picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty && mounted) {
      setState(() => _medicalDocuments.addAll(picked));
    }
  }

  Future<void> _submitAppointment() async {
    if (selectedDate == null || selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final success = await _createAppointmentInternal();
      if (success && mounted) {
        if (selectedType == 'Video Call') {
          await _openVideoAppointmentSupportChat();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isReschedule
                  ? 'Reschedule request submitted!'
                  : selectedType == 'Video Call'
                      ? 'Video appointment request submitted!'
                      : 'Appointment booked successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openVideoAppointmentSupportChat() async {
    if (officialSupportWhatsAppNumber.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support WhatsApp number is not configured yet.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentUser = context.read<UserProvider>().user;
    final patientName =
        selectedDependent?.fullName ?? currentUser?.fullName ?? 'Patient';
    final doctorName = widget.doctor.fullName.isNotEmpty
        ? widget.doctor.fullName
        : widget.doctor.name;
    final message = '''
I would like to book a video call appointment.
Doctor: $doctorName
Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}
Time: ${selectedTimeSlot!.start}
Patient: $patientName
''';
    final uri = Uri.parse(
      'https://wa.me/$officialSupportWhatsAppNumber?text=${Uri.encodeComponent(message.trim())}',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp. Please contact support.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<bool> _createAppointmentInternal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final String backendType =
          selectedType == 'Physical Visit' ? 'physical' : 'video';

      Map<String, dynamic> bookedForPayload;
      if (selectedDependent == null) {
        bookedForPayload = {'type': 'self'};
      } else {
        bookedForPayload = {
          'type': 'dependent',
          'dependentId': selectedDependent!.id,
          'dependentName': selectedDependent!.fullName,
          'relationship': selectedDependent!.relationship,
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll({
        'doctorId': widget.doctor.id,
        'appointmentType': backendType,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
        'time': selectedTimeSlot!.start,
        'symptoms': _symptomsController.text.trim(),
        'bookedFor': json.encode(bookedForPayload),
      });

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamedResponse);

      final jsonResponse =
          response.body.isNotEmpty ? json.decode(response.body) : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          context.read<AppointmentProvider>().fetchAppointments();
        }
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(jsonResponse['message'] ?? 'Booking failed'),
                backgroundColor: Colors.red),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Booking error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isReschedule ? 'Reschedule Appointment' : 'Book Appointment',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            // Appointment Type Selector
            _buildTypeSelector(),
            const SizedBox(height: 16),

            // Dependent Selector
            Consumer<DependentProvider>(
              builder: (context, provider, child) {
                return _buildDependentSelector(provider);
              },
            ),
            const SizedBox(height: 16),

            // Date Selector
            _buildDateSelector(),
            const SizedBox(height: 16),

            // Time Slots
            if (selectedDate != null) _buildTimeSlotGrid(),
            const SizedBox(height: 16),

            // Symptoms
            _buildSymptomsInput(),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? () {} : _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        widget.isReschedule
                            ? 'Submit Reschedule Request'
                            : selectedType == 'Video Call'
                            ? 'Request Video Call Appointment'
                            : 'Submit Appointment',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Appointment Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _buildTypeOption('Physical Visit', Icons.person,
                  selectedType == 'Physical Visit'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(
                  'Video Call', Icons.videocam, selectedType == 'Video Call'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildTypeOption(String label, IconData icon, bool isSelected) {
    final colors = AppTheme.of(context);
    return GestureDetector(
      onTap: () => setState(() => selectedType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryContainer : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.primaryDark : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(children: [
          Icon(icon, color: isSelected ? colors.primaryDark : Colors.grey),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? colors.primaryDark : Colors.grey)),
        ]),
      ),
    );
  }

  Widget _buildDependentSelector(DependentProvider provider) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Book For',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Myself'),
                selected: selectedDependent == null,
                selectedColor: colors.primaryContainer,
                onSelected: (_) => setState(() => selectedDependent = null),
              ),
              ...provider.activeDependents.map((dep) => ChoiceChip(
                    label: Text(dep.displayName),
                    selected: selectedDependent?.id == dep.id,
                    selectedColor: colors.primaryContainer,
                    onSelected: (_) => setState(() => selectedDependent = dep),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.calendar_today, color: colors.primaryDark),
        title: Text(
          selectedDate != null
              ? DateFormat('EEE, MMM d, yyyy').format(selectedDate!)
              : 'Select Date',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _selectDate,
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Time Slots',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_isLoadingSlots)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (availableSlots.isEmpty)
            const Text('No slots available for this date',
                style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableSlots.map((slot) {
                final isSelected = selectedTimeSlot?.start == slot.start;
                return ChoiceChip(
                  label: Text(slot.displayTime,
                      style: const TextStyle(fontSize: 13)),
                  selected: isSelected,
                  selectedColor: colors.primaryContainer,
                  onSelected: (_) => setState(() => selectedTimeSlot = slot),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSymptomsInput() {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Symptoms / Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _symptomsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe your symptoms or reason for visit...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.primaryDark)),
            ),
          ),
        ],
      ),
    );
  }
}
