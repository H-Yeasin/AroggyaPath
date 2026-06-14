import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class UserService {
  /// Get current user profile and save name/avatar to SharedPreferences
  static Future<Map<String, dynamic>> getUserProfile() async {
    debugPrint('Fetching user profile...');
    final result = await ApiService.get('/api/v1/user/profile', requiresAuth: true);

    // Save profile details for quick access
    if (result['success'] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userData = result['data'] ?? result['user'];

        if (userData != null) {
          final fullName = userData['fullName'];
          final avatarUrl = userData['avatar']?['url'];

          if (fullName != null) {
            await prefs.setString('user_full_name', fullName.toString());
            debugPrint('Profile: Saved user_full_name = $fullName');
          }
          if (avatarUrl != null && avatarUrl.toString().isNotEmpty) {
            await prefs.setString('user_avatar', avatarUrl.toString());
            debugPrint('Profile: Saved user_avatar = $avatarUrl');
          }
        }
      } catch (e) {
        debugPrint('Error saving profile to SharedPreferences: $e');
      }
    }

    return result;
  }

  /// Update user profile with image and location support
  static Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? username,
    String? phone,
    String? bio,
    String? gender,
    String? dob,
    String? address,
    String? country,
    String? language,
    int? experienceYears,
    String? specialty,
    List<String>? specialties,
    List<Map<String, dynamic>>? degrees,
    Map<String, dynamic>? fees,
    List<Map<String, dynamic>>? weeklySchedule,
    String? visitingHoursText,
    String? medicalLicenseNumber,
    File? profileImage,
    double? latitude,
    double? longitude,
    bool? isVideoCallAvailable,
    bool? isOnlineAppointmentAvailable,
  }) async {
    try {
      debugPrint('Updating user profile...');

      final Map<String, dynamic> body = {};

      // Basic fields
      if (fullName != null) body['fullName'] = fullName;
      if (username != null) body['username'] = username;
      if (phone != null) body['phone'] = phone;
      if (bio != null) body['bio'] = bio;
      if (gender != null) body['gender'] = gender;
      if (dob != null) body['dob'] = dob;
      if (address != null) body['address'] = address;
      if (country != null) body['country'] = country;
      if (language != null) body['language'] = language;
      if (experienceYears != null) body['experienceYears'] = experienceYears;

      // Doctor fields
      if (specialty != null) body['specialty'] = specialty;
      if (specialties != null) body['specialties'] = specialties;
      if (degrees != null) body['degrees'] = degrees;
      if (fees != null) body['fees'] = fees;
      if (weeklySchedule != null) body['weeklySchedule'] = weeklySchedule;
      if (visitingHoursText != null) body['visitingHoursText'] = visitingHoursText;
      if (medicalLicenseNumber != null) body['medicalLicenseNumber'] = medicalLicenseNumber;
      if (isVideoCallAvailable != null) body['isVideoCallAvailable'] = isVideoCallAvailable;
      if (isOnlineAppointmentAvailable != null) body['isOnlineAppointmentAvailable'] = isOnlineAppointmentAvailable;

      // Location fields
      if (latitude != null && longitude != null) {
        body['location'] = {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
        };
      }

      // Convert image to base64 if provided
      if (profileImage != null) {
        debugPrint('Converting image to base64...');
        final base64Image = await imageToBase64(profileImage);
        body['profileImage'] = base64Image;
      }

      final response = await ApiService.put(
        '/api/v1/user/profile',
        body,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        debugPrint('Profile updated successfully');
      } else {
        debugPrint('Profile update failed: ${response['message']}');
      }

      return response;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  /// Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    debugPrint('Changing password...');

    return await ApiService.put('/api/v1/user/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    }, requiresAuth: true);
  }

  /// Get users by role (patient | doctor | admin)
  static Future<Map<String, dynamic>> getUsersByRole(String role) async {
    debugPrint('Fetching users with role: $role');
    return await ApiService.get('/api/v1/user/role/$role', requiresAuth: true);
  }

  /// Get user details by ID
  static Future<Map<String, dynamic>> getUserDetails(String userId) async {
    debugPrint('Fetching user details for ID: $userId');
    return await ApiService.get('/api/v1/user/$userId', requiresAuth: true);
  }

  /// Get my dependents
  static Future<Map<String, dynamic>> getMyDependents() async {
    debugPrint('Fetching my dependents...');
    return await ApiService.get(
      '/api/v1/user/me/dependents',
      requiresAuth: true,
    );
  }

  /// Add dependent
  static Future<Map<String, dynamic>> addDependent({
    required String fullName,
    String? relationship,
    String? gender,
    String? dob,
    String? phone,
    String? notes,
  }) async {
    debugPrint('Adding dependent: $fullName');

    final Map<String, dynamic> body = {'fullName': fullName};

    if (relationship != null) body['relationship'] = relationship;
    if (gender != null) body['gender'] = gender;
    if (dob != null) body['dob'] = dob;
    if (phone != null) body['phone'] = phone;
    if (notes != null) body['notes'] = notes;

    return await ApiService.post(
      '/api/v1/user/me/dependents',
      body,
      requiresAuth: true,
    );
  }

  /// Update dependent
  static Future<Map<String, dynamic>> updateDependent({
    required String dependentId,
    String? fullName,
    String? relationship,
    String? gender,
    String? dob,
    String? phone,
    String? notes,
    bool? isActive,
  }) async {
    debugPrint('Updating dependent: $dependentId');

    final Map<String, dynamic> body = {};

    if (fullName != null) body['fullName'] = fullName;
    if (relationship != null) body['relationship'] = relationship;
    if (gender != null) body['gender'] = gender;
    if (dob != null) body['dob'] = dob;
    if (phone != null) body['phone'] = phone;
    if (notes != null) body['notes'] = notes;
    if (isActive != null) body['isActive'] = isActive;

    return await ApiService.patch(
      '/api/v1/user/me/dependents/$dependentId',
      body,
      requiresAuth: true,
    );
  }

  /// Delete dependent
  static Future<Map<String, dynamic>> deleteDependent(
    String dependentId,
  ) async {
    debugPrint('Deleting dependent: $dependentId');
    return await ApiService.delete(
      '/api/v1/user/me/dependents/$dependentId',
      requiresAuth: true,
    );
  }

  /// Convert image file to base64 with proper MIME type detection
  static Future<String> imageToBase64(File imageFile) async {
    try {
      debugPrint('Converting image to base64...');
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);

      // Detect image type from file extension
      String mimeType = 'image/jpeg';
      final extension = imageFile.path.split('.').last.toLowerCase();

      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      }

      final result = 'data:$mimeType;base64,$base64String';

      debugPrint('Image converted successfully');
      debugPrint('   - Size: ${bytes.length} bytes');
      debugPrint('   - Type: $mimeType');

      return result;
    } catch (e) {
      debugPrint('Error converting image to base64: $e');
      rethrow;
    }
  }
}
