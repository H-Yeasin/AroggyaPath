import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_config.dart';

class ApiService {
  static String? _token;
  static String get _baseUrl => ApiConfig.baseUrl;
  static final Map<String, Map<String, dynamic>> _profileCache = {};

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      debugPrint(
        'ApiService initialized. Token: ${_token != null ? "Found" : "Not found"}',
      );
    } catch (e) {
      debugPrint('Error initializing ApiService: $e');
    }
  }

  /// Sync user session — Call AFTER app launch to verify user_id
  static Future<void> syncUserSession() async {
    try {
      if (!isLoggedIn) {
        debugPrint('Not logged in - skipping session sync');
        return;
      }
      debugPrint('Syncing user session...');
      final prefs = await SharedPreferences.getInstance();
      final profile = await getUserProfile();
      if (profile['success'] == true) {
        final realId = profile['data']['_id']?.toString();
        if (realId != null) {
          final currentSavedId = prefs.getString('user_id');
          if (realId != currentSavedId) {
            debugPrint(
                'Session ID Mismatch! Syncing $currentSavedId -> $realId');
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

  /// Save auth token
  static Future<void> saveToken(String token) async {
    try {
      _token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      debugPrint(
          'Token saved: ${token.substring(0, min(token.length, 20))}...');
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  /// Clear auth token
  static Future<void> clearToken() async {
    try {
      _token = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      debugPrint('Token cleared');
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }

  /// Check if logged in
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// Get current token
  static String? get token => _token;

  /// Headers with optional auth
  static Map<String, String> _getHeaders({bool requiresAuth = true}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    } else if (requiresAuth && (_token == null || _token!.isEmpty)) {
      debugPrint('WARNING: Auth required but no token available!');
    }

    return headers;
  }

  /// GET Request with retry logic
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
    int retries = 2,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (attempts <= retries) {
      attempts++;
      try {
        if (requiresAuth && !isLoggedIn) {
          return {
            'success': false,
            'message': 'Token not found. Please login again.',
            'requiresLogin': true,
          };
        }

        final url = '$_baseUrl$endpoint';
        if (attempts == 1) {
          debugPrint('GET: $url');
        } else {
          debugPrint('Retry GET ($attempts/$retries): $url');
        }

        final headers = _getHeaders(requiresAuth: requiresAuth);
        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 15));

        return _handleResponse(response);
      } catch (e) {
        debugPrint('GET Error (Attempt $attempts): $e');
        if (attempts > retries) {
          return {'success': false, 'message': _getErrorMessage(e)};
        }
        await Future.delayed(delay * (attempts * attempts));
      }
    }
    return {'success': false, 'message': 'Request failed after retries'};
  }

  /// POST Request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      if (requiresAuth && !isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl$endpoint';
      debugPrint('POST: $url');
      debugPrint('Body: $body');

      final headers = _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .post(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  /// PUT Request
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      if (requiresAuth && !isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl$endpoint';
      debugPrint('PUT: $url');
      final headers = _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .put(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  /// PATCH Request
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      if (requiresAuth && !isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl$endpoint';
      debugPrint('PATCH: $url');
      final headers = _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .patch(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('PATCH Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  /// DELETE Request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      if (requiresAuth && !isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl$endpoint';
      debugPrint('DELETE: $url');
      final headers = _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  // ========================================
  // AUTH APIs
  // ========================================

  /// Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await post(
        '/api/v1/auth/login',
        {
          'email': email,
          'password': password,
        },
        requiresAuth: false);

    if (result['success'] == true) {
      final token = result['data']?['accessToken'] ??
          result['data']?['token'] ??
          result['token'] ??
          result['accessToken'];

      if (token != null) {
        await saveToken(token);
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

  /// Register
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
    final Map<String, dynamic> body = {
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

    return await post('/api/v1/auth/register', body, requiresAuth: false);
  }

  /// Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      await post('/api/v1/auth/logout', {}, requiresAuth: true);
    } catch (e) {
      debugPrint('Logout request failed: $e');
    }
    await clearToken();
    return {'success': true, 'message': 'Logged out successfully'};
  }

  /// Forgot Password
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return await post(
        '/api/v1/auth/forget',
        {
          'email': email,
        },
        requiresAuth: false);
  }

  /// Verify OTP
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    return await post(
        '/api/v1/auth/verify-otp',
        {
          'email': email,
          'otp': otp,
        },
        requiresAuth: false);
  }

  /// Reset Password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return await post(
        '/api/v1/auth/reset-password',
        {
          'email': email,
          'otp': otp,
          'password': newPassword,
        },
        requiresAuth: false);
  }

  // ========================================
  // USER APIs
  // ========================================

  /// Get User Profile
  static Future<Map<String, dynamic>> getUserProfile({String? userId}) async {
    if (userId != null && _profileCache.containsKey(userId)) {
      debugPrint('Cache Hit: User profile for $userId');
      return _profileCache[userId]!;
    }

    final endpoint = userId != null
        ? '${ApiConfig.getUserById}/$userId'
        : ApiConfig.userProfile;

    final result = await get(endpoint, requiresAuth: true);

    if (result['success'] == true && userId != null) {
      _profileCache[userId] = result;
    }

    return result;
  }

  /// Update User Profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required Map<String, dynamic> data,
  }) async {
    return await put('/api/v1/user/profile', data, requiresAuth: true);
  }

  // ========================================
  // DOCTOR APIs
  // ========================================

  /// Get All Doctors
  static Future<Map<String, dynamic>> getAllDoctors({
    int page = 1,
    int limit = 20,
    String? specialty,
  }) async {
    String endpoint = '/api/v1/user/role/doctor?page=$page&limit=$limit';
    if (specialty != null && specialty.isNotEmpty) {
      endpoint += '&specialty=$specialty';
    }
    return await get(endpoint, requiresAuth: false);
  }

  /// Get Doctor Details
  static Future<Map<String, dynamic>> getDoctorDetails({
    required String doctorId,
  }) async {
    return await get('/api/v1/user/$doctorId', requiresAuth: false);
  }

  /// Search Doctors
  static Future<Map<String, dynamic>> searchDoctors({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '/api/v1/user/find-doctors?q=$query&page=$page&limit=$limit',
      requiresAuth: false,
    );
  }

  /// Get All Categories (specialties)
  static Future<Map<String, dynamic>> getAllCategories() async {
    return await get('/api/v1/category', requiresAuth: false);
  }

  // ========================================
  // APPOINTMENT APIs
  // ========================================

  /// Get Appointments
  static Future<Map<String, dynamic>> getAppointments() async {
    return await get('/api/v1/appointment', requiresAuth: true);
  }

  /// Create Appointment
  static Future<Map<String, dynamic>> createAppointment({
    required Map<String, dynamic> appointmentData,
  }) async {
    return await post('/api/v1/appointment', appointmentData,
        requiresAuth: true);
  }

  /// Update Appointment Status
  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    return await patch(
        '/api/v1/appointment/$appointmentId',
        {
          'status': status,
        },
        requiresAuth: true);
  }

  /// Cancel Appointment
  static Future<Map<String, dynamic>> cancelAppointment({
    required String appointmentId,
  }) async {
    return await patch(
      '/api/v1/appointment/$appointmentId/cancel',
      {},
      requiresAuth: true,
    );
  }

  // ========================================
  // DEPENDENTS APIs
  // ========================================

  /// Get Dependents
  static Future<Map<String, dynamic>> getDependents() async {
    return await get('/api/v1/user/me/dependents', requiresAuth: true);
  }

  /// Add Dependent
  static Future<Map<String, dynamic>> addDependent({
    required Map<String, dynamic> dependentData,
  }) async {
    return await post(
      '/api/v1/user/me/dependents',
      dependentData,
      requiresAuth: true,
    );
  }

  /// Update Dependent
  static Future<Map<String, dynamic>> updateDependent({
    required String dependentId,
    required Map<String, dynamic> data,
  }) async {
    return await patch(
      '/api/v1/user/me/dependents/$dependentId',
      data,
      requiresAuth: true,
    );
  }

  /// Delete Dependent
  static Future<Map<String, dynamic>> deleteDependent({
    required String dependentId,
  }) async {
    return await delete(
      '/api/v1/user/me/dependents/$dependentId',
      requiresAuth: true,
    );
  }

  // ========================================
  // UPLOAD APIs
  // ========================================

  /// Upload Single File
  static Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fieldName,
  }) async {
    try {
      if (!isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl/api/v1/upload';
      debugPrint('Uploading file: $filePath');

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_getHeaders(requiresAuth: true));
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('File upload error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  // ========================================
  // CHAT METHODS
  // ========================================

  /// Get Agora Chat Token
  static Future<Map<String, dynamic>> getAgoraChatToken() async {
    debugPrint('Fetching Agora Chat Token');
    return await get('/api/v1/chat/token', requiresAuth: true);
  }

  /// Get My Chats
  static Future<Map<String, dynamic>> getMyChats() async {
    debugPrint('Getting my chats');
    return await get('/api/v1/chat', requiresAuth: true);
  }

  /// Get Chat Messages
  static Future<Map<String, dynamic>> getChatMessages({
    required String chatId,
    required int page,
    required int limit,
  }) async {
    debugPrint('Getting messages for chatId: $chatId');
    return await get(
      '/api/v1/chat/$chatId/messages?page=$page&limit=$limit',
      requiresAuth: true,
    );
  }

  /// Create or Get Chat
  static Future<Map<String, dynamic>> createOrGetChat({
    required String userId,
  }) async {
    final cleanUserId = userId.split('/').first;
    debugPrint('Creating/Getting chat with: $cleanUserId');
    return await post('/api/v1/chat', {'userId': cleanUserId}, requiresAuth: true);
  }

  /// Mark Chat as Read
  static Future<Map<String, dynamic>> markChatAsRead({
    required String chatId,
  }) async {
    debugPrint('Marking chat as read: $chatId');
    return await patch('/api/v1/chat/$chatId/read', {}, requiresAuth: true);
  }

  /// Get Agora RTC Token for a channel
  static Future<Map<String, dynamic>> getAgoraToken({
    required String channelName,
  }) async {
    return await get(
      '/api/v1/call/token?channelName=$channelName',
      requiresAuth: true,
    );
  }

  /// End a call
  static Future<Map<String, dynamic>> endCall({
    required String chatId,
    required String toUserId,
    String? uuid,
  }) async {
    return await post('/api/v1/call/end', {
      'chatId': chatId,
      'userId': toUserId,
      'uuid': uuid ?? '',
    }, requiresAuth: true);
  }

  /// Send message via multipart (supports files)
  static Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    String? content,
    List<File>? files,
    String? contentType,
  }) async {
    try {
      final url = '$_baseUrl/api/v1/chat/$chatId/messages';
      debugPrint('POST (Multipart): $url');

      final request = http.MultipartRequest('POST', Uri.parse(url));

      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (content != null && content.isNotEmpty) {
        request.fields['content'] = content;
      }
      if (contentType != null) {
        request.fields['contentType'] = contentType;
      }
      if (files != null) {
        for (var file in files) {
          request.files.add(await http.MultipartFile.fromPath(
            'files',
            file.path,
          ));
        }
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Send message error: $e');
      return {'success': false, 'message': 'Failed to send message: $e'};
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Response handler
  static Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('Status: ${response.statusCode}');

    try {
      final body = response.body;
      dynamic data;
      try {
        data = json.decode(body);
      } catch (e) {
        debugPrint('JSON Decode Error: $e');

        if (body.contains('<html>') || body.contains('nginx')) {
          return {
            'success': false,
            'message':
                'Server is currently unavailable. Please try again later.',
            'statusCode': response.statusCode,
          };
        }

        return {
          'success': false,
          'message': body.isNotEmpty
              ? body.substring(0, min(body.length, 200))
              : 'Unknown server error',
          'statusCode': response.statusCode,
        };
      }

      if (data is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': 'Invalid response format',
          'statusCode': response.statusCode,
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'statusCode': response.statusCode, ...data};
      }

      String errorMessage = data['message'] ?? 'Request failed';
      if (data['error'] != null && data['error'] is String) {
        errorMessage = data['error'];
      }

      if (response.statusCode == 401) {
        debugPrint('401 Unauthorized - Clearing token');
        clearToken();
        return {
          'success': false,
          'message': errorMessage,
          'requiresLogin': true,
          'statusCode': response.statusCode,
        };
      }

      return {
        'success': false,
        'message': errorMessage,
        'statusCode': response.statusCode,
        'errors': data['errors'] ?? [],
        'data': data,
      };
    } catch (e) {
      debugPrint('Response handling error: $e');
      return {
        'success': false,
        'message': 'Failed to process server response',
        'statusCode': response.statusCode,
      };
    }
  }

  /// Error message generator
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup')) {
      return 'Cannot connect to server. Please check your internet connection.';
    } else if (errorString.contains('connection refused')) {
      return 'Server is not responding. Please try again later.';
    } else if (errorString.contains('timeout')) {
      return 'Request timeout. Please check your connection and try again.';
    } else if (errorString.contains('format')) {
      return 'Invalid data format received from server.';
    } else {
      return 'An error occurred: ${error.toString()}';
    }
  }

  /// Helper for min function
  static int min(int a, int b) => a < b ? a : b;
}
