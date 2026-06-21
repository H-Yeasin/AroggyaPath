import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'api_user_service.dart';

class ApiAuthService {
  static Future<void> syncUserSession() async {
    try {
      if (!ApiClient.isLoggedIn) {
        debugPrint('Not logged in - skipping session sync');
        return;
      }
      debugPrint('Syncing user session...');
      final prefs = await SharedPreferences.getInstance();
      final profile = await ApiUserEndpointService.getUserProfile();
      if (profile['success'] == true) {
        final realId = profile['data']['_id']?.toString();
        if (realId != null) {
          final currentSavedId = prefs.getString('user_id');
          if (realId != currentSavedId) {
            debugPrint(
              'Session ID Mismatch! Syncing $currentSavedId -> $realId',
            );
            await prefs.setString('user_id', realId);
          } else {
            debugPrint('Session ID synced: $realId');
          }
        }
      }
    } catch (e) {
      debugPrint('Profile sync failed: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await ApiClient.post(
      '/api/v1/auth/login',
      {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    if (result['success'] == true) {
      final token = result['data']?['accessToken'] ??
          result['data']?['token'] ??
          result['token'] ??
          result['accessToken'];

      if (token != null) {
        await ApiClient.saveToken(token);
        debugPrint('Login successful - Token saved');

        final prefs = await SharedPreferences.getInstance();

        final userRole = result['data']?['user']?['role'] ??
            result['data']?['role'] ??
            result['user']?['role'] ??
            result['role'];

        if (userRole != null) {
          await prefs.setString('user_role', userRole.toString().toLowerCase());
          debugPrint('User role saved: $userRole');
        }

        final userId = result['data']?['user']?['_id'] ??
            result['data']?['user']?['id'] ??
            result['data']?['_id'] ??
            result['user']?['_id'];

        if (userId != null) {
          await prefs.setString('user_id', userId.toString());
          debugPrint('User ID saved: $userId');
        }

        final fullName = result['data']?['user']?['fullName'] ??
            result['data']?['fullName'] ??
            result['user']?['fullName'];

        if (fullName != null) {
          await prefs.setString('user_full_name', fullName.toString());
        }
      }
    }

    return result;
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? medicalLicenseNumber,
    String? specialty,
    String? experienceYears,
    String? referralCode,
  }) async {
    final body = {
      'fullName': fullName,
      'email': email,
      'password': password,
      'confirmPassword': password,
      'role': role.toLowerCase(),
    };

    if (role.toLowerCase() == 'doctor') {
      if (medicalLicenseNumber != null) {
        body['medicalLicenseNumber'] = medicalLicenseNumber;
      }
      if (specialty != null) {
        body['specialty'] = specialty;
      }
      if (experienceYears != null) {
        body['experienceYears'] = experienceYears;
      }
      if (referralCode != null && referralCode.isNotEmpty) {
        body['refferalCode'] = referralCode;
      }
    }

    return ApiClient.post('/api/v1/auth/register', body, requiresAuth: false);
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      await ApiClient.post('/api/v1/auth/logout', {}, requiresAuth: true);
    } catch (e) {
      debugPrint('Logout request failed: $e');
    }
    await ApiClient.clearToken();
    return {'success': true, 'message': 'Logged out successfully'};
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) {
    return ApiClient.post(
      '/api/v1/auth/forget',
      {'email': email},
      requiresAuth: false,
    );
  }

  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) {
    return ApiClient.post(
      '/api/v1/auth/verify-otp',
      {
        'email': email,
        'otp': otp,
      },
      requiresAuth: false,
    );
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return ApiClient.post(
      '/api/v1/auth/reset-password',
      {
        'email': email,
        'otp': otp,
        'password': newPassword,
      },
      requiresAuth: false,
    );
  }
}
