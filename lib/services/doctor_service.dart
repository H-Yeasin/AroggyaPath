import 'package:arogya_path3/core/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class DoctorService {
  Future<Map<String, dynamic>> getAllDoctors() async {
    try {
      final response = await ApiService.get(ApiConfig.doctors, requiresAuth: true);
      return response;
    } catch (e) {
      debugPrint('Get All Doctors Error: $e');
      return {'success': false, 'message': 'Failed to fetch doctors: $e'};
    }
  }

  Future<Map<String, dynamic>> getNearbyDoctors({
    double? lat,
    double? lng,
    double radiusKm = 50,
  }) async {
    try {
      String endpoint = ApiConfig.doctors;

      // Use optimized endpoint if location is available
      if (lat != null && lng != null) {
        endpoint =
            '${ApiConfig.nearbyDoctors}?lat=$lat&lng=$lng&radiusKm=$radiusKm';
      }

      final response = await ApiService.get(endpoint, requiresAuth: true);
      return response;
    } catch (e) {
      debugPrint('Get Nearby Doctors Error: $e');
      return {'success': false, 'message': 'Failed to fetch doctors: $e'};
    }
  }

  Future<Map<String, dynamic>> getDoctorById(String id) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.doctorById}/$id',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      debugPrint('Get Doctor By ID Error: $e');
      return {'success': false, 'message': 'Failed to fetch doctor: $e'};
    }
  }

  Future<Map<String, dynamic>> searchDoctors(String query) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.searchDoctors}?search=$query',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      debugPrint('Search Doctors Error: $e');
      return {'success': false, 'message': 'Failed to search doctors: $e'};
    }
  }
}
