import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

// Top-level function for isolate
List<AppointmentModel> _parseAppointments(dynamic data) {
  if (data is! List) return [];

  final List<AppointmentModel> parsed = data
      .map((json) {
        try {
          return AppointmentModel.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error parsing appointment: $e');
          return null;
        }
      })
      .whereType<AppointmentModel>()
      .toList();

  parsed.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
  return parsed;
}

class AppointmentProvider with ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();

  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  String? _error;

  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAppointments => _appointments.isNotEmpty;

  static const _cacheKey = 'cached_appointments';
  static const _cacheTimeKey = 'cached_appointments_time';
  static const _cacheDurationMinutes = 5;

  List<AppointmentModel> get pendingAppointments =>
      _appointments.where((apt) => apt.status.toLowerCase() == 'pending').toList();

  List<AppointmentModel> get acceptedAppointments =>
      _appointments.where((apt) => apt.status.toLowerCase() == 'accepted').toList();

  List<AppointmentModel> get upcomingAppointments => _appointments
      .where((apt) =>
          apt.status.toLowerCase() == 'pending' ||
          apt.status.toLowerCase() == 'accepted')
      .toList();

  List<AppointmentModel> get completedAppointments =>
      _appointments.where((apt) => apt.status.toLowerCase() == 'completed').toList();

  List<AppointmentModel> get cancelledAppointments =>
      _appointments.where((apt) => apt.status.toLowerCase() == 'cancelled').toList();

  /// Load appointments from local cache
  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final ageMinutes = (now - cacheTime) / 60000;

      if (json != null && ageMinutes < _cacheDurationMinutes) {
        final List<dynamic> data = jsonDecode(json);
        _appointments = await compute(_parseAppointments, data);
        debugPrint(
            'Appointments from cache (${_appointments.length} items, ${ageMinutes.toStringAsFixed(1)} min old)');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading appointments cache: $e');
    }
  }

  Future<void> _saveToCache(List<AppointmentModel> appointments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = appointments.map((a) => a.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('${appointments.length} appointments cached');
    } catch (e) {
      debugPrint('Error saving appointments cache: $e');
    }
  }

  /// Fetch appointments from API
  Future<bool> fetchAppointments() async {
    if (_appointments.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;

    try {
      final response = await _appointmentService.getMyAppointments();

      if (response['success'] == true) {
        final data = response['data'];

        if (data != null) {
          _appointments = await compute(_parseAppointments, data);
          _saveToCache(_appointments);
        } else {
          _appointments = [];
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch appointments';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Fetch Appointments Error: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create appointment (Patient)
  Future<bool> createAppointment({
    required String doctorId,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? symptoms,
    String? appointmentType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _appointmentService.createAppointment(
        doctorId: doctorId,
        appointmentDate: appointmentDate.toIso8601String().split('T')[0],
        appointmentTime: appointmentTime,
        symptoms: symptoms,
        appointmentType: appointmentType ?? 'physical',
      );

      if (response['success'] == true) {
        await fetchAppointments();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create appointment';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Create Appointment Error: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Accept appointment (Doctor)
  Future<bool> acceptAppointment(String appointmentId) async {
    try {
      final response = await _appointmentService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: 'accepted',
      );

      if (response['success'] == true) {
        final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
        if (index != -1) {
          _appointments[index] = _appointments[index].copyWith(status: 'accepted');
        }
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to accept appointment';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Accept Appointment Error: $e');
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      final response = await _appointmentService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: 'cancelled',
      );

      if (response['success'] == true) {
        final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
        if (index != -1) {
          _appointments[index] = _appointments[index].copyWith(status: 'cancelled');
        }
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to cancel appointment';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Cancel Appointment Error: $e');
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Complete appointment (Doctor)
  Future<bool> completeAppointment({
    required String appointmentId,
    required String patientName,
    required double price,
  }) async {
    try {
      final response = await _appointmentService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: 'completed',
        patient: patientName,
        price: price,
      );

      if (response['success'] == true) {
        final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
        if (index != -1) {
          _appointments[index] = _appointments[index].copyWith(status: 'completed');
        }
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to complete appointment';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Complete Appointment Error: $e');
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  void clearAppointments() {
    _appointments = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  AppointmentModel? getAppointmentById(String id) {
    try {
      return _appointments.firstWhere((apt) => apt.id == id);
    } catch (e) {
      return null;
    }
  }
}
