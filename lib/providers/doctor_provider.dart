import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorService _doctorService = DoctorService();

  List<Doctor> _nearbyDoctors = [];
  bool _isLoading = false;
  String? _error;

  List<Doctor> get nearbyDoctors => _nearbyDoctors;
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
        List<dynamic> data = [];

        if (response['data'] is List) {
          data = response['data'];
        } else if (response['data'] is Map<String, dynamic>) {
          final mapData = response['data'] as Map<String, dynamic>;
          if (mapData.containsKey('docs')) {
            data = mapData['docs'];
          } else if (mapData.containsKey('items')) {
            data = mapData['items'];
          } else if (mapData.containsKey('doctors')) {
            data = mapData['doctors'];
          }
        }

        _nearbyDoctors = data.map((json) => Doctor.fromJson(json)).toList();
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
    _nearbyDoctors = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
