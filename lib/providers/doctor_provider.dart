import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorService _doctorService = DoctorService();

  List<Doctor> _allDoctors = [];
  List<Doctor> _nearbyDoctors = [];
  bool _isLoading = false;
  String? _error;

  List<Doctor> get allDoctors => _allDoctors;
  List<Doctor> get nearbyDoctors => _nearbyDoctors;
  List<Doctor> get onlineDoctors {
    final doctors = _allDoctors
        .where((doctor) => doctor.isVideoCallAvailable)
        .toList();

    doctors.sort((a, b) {
      final availability = (_hasSchedule(b) ? 1 : 0)
          .compareTo(_hasSchedule(a) ? 1 : 0);
      if (availability != 0) return availability;
      return b.rating.compareTo(a.rating);
    });

    return doctors;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  static const _cacheKey = 'cached_nearby_doctors';
  static const _cacheTimeKey = 'cached_nearby_doctors_time';
  static const _cacheDurationMinutes = 10;

  /// Load doctors from local cache
  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final ageMinutes = (now - cacheTime) / 60000;

      if (json != null && ageMinutes < _cacheDurationMinutes) {
        final List<dynamic> data = jsonDecode(json);
        _nearbyDoctors = data.map((d) => Doctor.fromJson(d)).toList();
        if (_allDoctors.isEmpty) {
          _allDoctors = List<Doctor>.from(_nearbyDoctors);
        }
        debugPrint(
            'Doctors loaded from cache (${_nearbyDoctors.length} doctors, ${ageMinutes.toStringAsFixed(1)} min old)');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading doctors cache: $e');
    }
  }

  Future<void> _saveToCache(List<Doctor> doctors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = doctors.map((d) => d.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('${doctors.length} doctors cached');
    } catch (e) {
      debugPrint('Error saving doctors cache: $e');
    }
  }

  List<dynamic> _extractDoctorsData(Map<String, dynamic> response) {
    if (response['data'] is List) {
      return response['data'];
    }

    if (response['data'] is Map<String, dynamic>) {
      final mapData = response['data'] as Map<String, dynamic>;
      if (mapData.containsKey('docs')) return mapData['docs'];
      if (mapData.containsKey('items')) return mapData['items'];
      if (mapData.containsKey('doctors')) return mapData['doctors'];
    }

    return [];
  }

  bool _hasSchedule(Doctor doctor) {
    final schedule = doctor.weeklySchedule;
    if (schedule == null || schedule.isEmpty) return false;
    return schedule.any((day) => day.isActive && day.slots.isNotEmpty);
  }

  Future<bool> fetchAllDoctors() async {
    _error = null;

    try {
      debugPrint('Fetching all doctors from API...');
      final response = await _doctorService.getAllDoctors();

      if (response['success'] == true) {
        final data = _extractDoctorsData(response);
        _allDoctors = data.map((json) => Doctor.fromJson(json)).toList();
        debugPrint('Fetched ${_allDoctors.length} all doctors');

        notifyListeners();
        return true;
      }

      _error = response['message'] ?? 'Failed to fetch doctors';
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      _error = 'Error: $e';
      debugPrint('Exception in fetchAllDoctors: $e');
      debugPrint('  StackTrace: $stackTrace');
      notifyListeners();
      return false;
    }
  }

  /// Fetch nearby doctors from API
  Future<bool> fetchNearbyDoctors({double? lat, double? lng}) async {
    if (_nearbyDoctors.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;

    try {
      debugPrint('Fetching doctors from API...');
      final response = await _doctorService.getNearbyDoctors(lat: lat, lng: lng);

      if (response['success'] == true) {
        final data = _extractDoctorsData(response);
        _nearbyDoctors = data.map((json) => Doctor.fromJson(json)).toList();
        if (_allDoctors.isEmpty && lat == null && lng == null) {
          _allDoctors = List<Doctor>.from(_nearbyDoctors);
        }
        debugPrint('Fetched ${_nearbyDoctors.length} doctors');

        _saveToCache(_nearbyDoctors);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch doctors';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _error = 'Error: $e';
      debugPrint('Exception in fetchNearbyDoctors: $e');
      debugPrint('  StackTrace: $stackTrace');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearDoctors() {
    _allDoctors = [];
    _nearbyDoctors = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
