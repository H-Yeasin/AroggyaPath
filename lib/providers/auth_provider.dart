import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => ApiService.isLoggedIn;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.login(email: email, password: password);

    _isLoading = false;
    if (result['success'] == true) {
      _user = result['data']?['user'] ?? result['data'];
      notifyListeners();
      return true;
    } else {
      _error = result['message'] ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? medicalLicenseNumber,
    String? specialty,
    String? experienceYears,
    String? referralCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      medicalLicenseNumber: medicalLicenseNumber,
      specialty: specialty,
      experienceYears: experienceYears,
      referralCode: referralCode,
    );

    _isLoading = false;
    if (result['success'] == true) {
      notifyListeners();
      return true;
    } else {
      _error = result['message'] ?? 'Registration failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.forgotPassword(email: email);

    _isLoading = false;
    if (result['success'] == true) {
      notifyListeners();
      return true;
    } else {
      _error = result['message'] ?? 'Failed to send OTP';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.verifyOTP(email: email, otp: otp);

    _isLoading = false;
    if (result['success'] == true) {
      notifyListeners();
      return true;
    } else {
      _error = result['message'] ?? 'Invalid OTP';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );

    _isLoading = false;
    if (result['success'] == true) {
      notifyListeners();
      return true;
    } else {
      _error = result['message'] ?? 'Password reset failed';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
