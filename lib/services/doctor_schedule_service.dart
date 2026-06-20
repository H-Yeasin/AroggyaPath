import 'package:flutter/material.dart';

import 'api_service.dart';

class DoctorScheduleService {
  /// Save doctor's weekly schedule with video call availability
  Future<Map<String, dynamic>> saveWeeklySchedule({
    required List<Map<String, dynamic>> weeklySchedule,
    required Map<String, dynamic> fees,
    required bool isVideoCallAvailable,
  }) async {
    try {
      final body = {
        'weeklySchedule': weeklySchedule,
        'fees': fees,
        'isVideoCallAvailable': isVideoCallAvailable,
      };

      debugPrint('Sending to backend:');
      debugPrint('   - weeklySchedule: ${weeklySchedule.length} days');
      debugPrint('   - fees: $fees');
      debugPrint('   - isVideoCallAvailable: $isVideoCallAvailable');

      final response = await ApiService.put(
        '/api/v1/user/profile',
        body,
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      debugPrint('Save Schedule Error: $e');
      return {'success': false, 'message': 'Failed to save schedule: $e'};
    }
  }

  /// Get doctor's current schedule
  Future<Map<String, dynamic>> getMySchedule() async {
    try {
      final response = await ApiService.get(
        '/api/v1/user/profile',
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      debugPrint('Get Schedule Error: $e');
      return {'success': false, 'message': 'Failed to fetch schedule: $e'};
    }
  }
}
