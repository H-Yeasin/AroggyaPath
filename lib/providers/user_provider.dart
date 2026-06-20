import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/doctor_schedule_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  /// Load user from local cache immediately on app start
  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('cached_user_profile');
      if (userJson != null) {
        debugPrint('Loading user profile from CACHE...');
        final Map<String, dynamic> data = jsonDecode(userJson);
        _user = UserModel.fromJson(data);
        notifyListeners(); // Update UI immediately
      }
    } catch (e) {
      debugPrint('Error loading cached profile: $e');
    }
  }

  /// Save user to local cache
  Future<void> _saveToCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_profile', jsonEncode(data));
      debugPrint('User profile cached locally');
    } catch (e) {
      debugPrint('Error caching profile: $e');
    }
  }

  /// Fetch user profile with Caching & Silent Refresh
  Future<bool> fetchUserProfile({bool forceRefresh = false}) async {
    if (_user == null || forceRefresh) {
      _isLoading = true;
      notifyListeners();
    }

    _error = null;

    try {
      debugPrint('Fetching user profile...');
      final response = await UserService.getUserProfile();

      if (response['success'] == true && response['data'] != null) {
        _user = UserModel.fromJson(response['data']);

        // Cache the fresh data
        _saveToCache(response['data']);

        debugPrint('User profile loaded: ${_user?.fullName}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch profile';
        if (_isLoading) {
          _isLoading = false;
          notifyListeners();
        }
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
      return false;
    }
  }

  /// Update video call availability
  Future<bool> updateVideoCallAvailability(bool isAvailable) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final scheduleService = DoctorScheduleService();

      final currentFees = _user?.fees ?? {'amount': 0, 'currency': 'USD'};
      final currentSchedule =
          _user?.weeklySchedule?.map((d) => d.toJson()).toList() ?? [];

      final response = await scheduleService.saveWeeklySchedule(
        weeklySchedule: currentSchedule,
        fees: currentFees,
        isVideoCallAvailable: isAvailable,
      );

      if (response['success'] == true) {
        if (_user != null) {
          _user = _user!.copyWith(isVideoCallAvailable: isAvailable);
          notifyListeners();
        }

        await fetchUserProfile();

        if (_user != null && _user!.isVideoCallAvailable != isAvailable) {
          _user = _user!.copyWith(isVideoCallAvailable: isAvailable);
          notifyListeners();
        }

        _isLoading = false;
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update availability';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile (with image and location support)
  Future<bool> updateUserProfile({
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
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentFees =
          fees ?? (_user?.role == 'doctor' ? _user?.fees : null);
      final currentSchedule =
          weeklySchedule ??
          (_user?.role == 'doctor'
              ? _user?.weeklySchedule?.map((d) => d.toJson()).toList()
              : null);
      final currentSpecialty =
          specialty ?? (_user?.role == 'doctor' ? _user?.specialty : null);
      final currentExperience =
          experienceYears ??
          (_user?.role == 'doctor' ? _user?.experienceYears : null);
      final currentBio = bio ?? (_user?.role == 'doctor' ? _user?.bio : null);
      final currentLicense =
          medicalLicenseNumber ??
          (_user?.role == 'doctor' ? _user?.medicalLicenseNumber : null);
      final currentLat = latitude ?? (_user?.latitude);
      final currentLng = longitude ?? (_user?.longitude);

      final response = await UserService.updateUserProfile(
        fullName: fullName,
        username: username,
        phone: phone,
        bio: currentBio,
        gender: gender,
        dob: dob,
        address: address,
        country: country,
        language: language,
        experienceYears: currentExperience,
        specialty: currentSpecialty,
        specialties: specialties,
        degrees: degrees,
        fees: currentFees,
        weeklySchedule: currentSchedule,
        visitingHoursText: visitingHoursText,
        medicalLicenseNumber: currentLicense,
        profileImage: profileImage,
        latitude: currentLat,
        longitude: currentLng,
        isVideoCallAvailable: isVideoCallAvailable,
      );

      if (response['success'] == true && response['data'] != null) {
        var updatedUser = UserModel.fromJson(response['data']);

        if (isVideoCallAvailable != null &&
            updatedUser.isVideoCallAvailable != isVideoCallAvailable) {
          updatedUser = updatedUser.copyWith(
            isVideoCallAvailable: isVideoCallAvailable,
          );
        }

        _user = updatedUser;
        debugPrint('Profile updated successfully!');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Save weekly schedule (for doctors)
  Future<bool> saveWeeklySchedule(List<Map<String, dynamic>> weeklySchedule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final scheduleService = DoctorScheduleService();

      final currentFees = _user?.fees ?? {'amount': 0, 'currency': 'USD'};

      final response = await scheduleService.saveWeeklySchedule(
        weeklySchedule: weeklySchedule,
        fees: currentFees,
        isVideoCallAvailable: _user?.isVideoCallAvailable ?? true,
      );

      if (response['success'] == true) {
        if (_user != null) {
          final parsed = weeklySchedule
              .map((d) => DaySchedule.fromJson(d))
              .toList();
          _user = _user!.copyWith(weeklySchedule: parsed);
          notifyListeners();
        }

        // Refresh from backend to ensure consistency
        await fetchUserProfile();

        _isLoading = false;
        return true;
      } else {
        _error = response['message'] ?? 'Failed to save schedule';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await UserService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response['success'] == true) {
        debugPrint('Password changed successfully');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to change password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set user (for login)
  void setUser(UserModel user) {
    _user = user;
    _error = null;
    debugPrint('User set: ${user.fullName}');
    notifyListeners();
  }

  /// Clear user (for logout)
  void clearUser() {
    _user = null;
    _error = null;
    _isLoading = false;
    debugPrint('User cleared (logged out)');
    notifyListeners();
  }

  /// Update local user data without API call
  void updateLocalUser(UserModel updatedUser) {
    _user = updatedUser;
    debugPrint('Local user updated: ${updatedUser.fullName}');
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh user profile (pull-to-refresh)
  Future<void> refreshProfile() async {
    await fetchUserProfile();
  }
}
