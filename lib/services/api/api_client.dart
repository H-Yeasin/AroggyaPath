import 'dart:convert';
import 'dart:io' show File;

import 'package:arogya_path3/core/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static String? _token;
  static String get baseUrl => ApiConfig.baseUrl;

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

  static Future<void> saveToken(String token) async {
    try {
      _token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      debugPrint(
        'Token saved: ${token.substring(0, _min(token.length, 20))}...',
      );
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

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

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static String? get token => _token;

  static Map<String, String> getHeaders({bool requiresAuth = true}) {
    final headers = {
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
        final loginError = _requireLogin(requiresAuth);
        if (loginError != null) return loginError;

        final url = '$baseUrl$endpoint';
        if (attempts == 1) {
          debugPrint('GET: $url');
        } else {
          debugPrint('Retry GET ($attempts/$retries): $url');
        }

        final response = await http
            .get(Uri.parse(url), headers: getHeaders(requiresAuth: requiresAuth))
            .timeout(const Duration(seconds: 15));

        return handleResponse(response);
      } catch (e) {
        debugPrint('GET Error (Attempt $attempts): $e');
        if (attempts > retries) {
          return {'success': false, 'message': getErrorMessage(e)};
        }
        await Future.delayed(delay * (attempts * attempts));
      }
    }
    return {'success': false, 'message': 'Request failed after retries'};
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final loginError = _requireLogin(requiresAuth);
      if (loginError != null) return loginError;

      final url = '$baseUrl$endpoint';
      debugPrint('POST: $url');
      debugPrint('Body: $body');

      final response = await http
          .post(
            Uri.parse(url),
            headers: getHeaders(requiresAuth: requiresAuth),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      return handleResponse(response);
    } catch (e) {
      debugPrint('POST Error: $e');
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    Map<String, String> fields = const {},
    Map<String, List<File>> files = const {},
    bool requiresAuth = true,
  }) async {
    return _sendMultipart(
      'POST',
      endpoint,
      fields: fields,
      files: files,
      requiresAuth: requiresAuth,
    );
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final loginError = _requireLogin(requiresAuth);
      if (loginError != null) return loginError;

      final url = '$baseUrl$endpoint';
      debugPrint('PUT: $url');
      final response = await http
          .put(
            Uri.parse(url),
            headers: getHeaders(requiresAuth: requiresAuth),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      return handleResponse(response);
    } catch (e) {
      debugPrint('PUT Error: $e');
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final loginError = _requireLogin(requiresAuth);
      if (loginError != null) return loginError;

      final url = '$baseUrl$endpoint';
      debugPrint('PATCH: $url');
      final response = await http
          .patch(
            Uri.parse(url),
            headers: getHeaders(requiresAuth: requiresAuth),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      return handleResponse(response);
    } catch (e) {
      debugPrint('PATCH Error: $e');
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> patchMultipart(
    String endpoint, {
    Map<String, String> fields = const {},
    Map<String, List<File>> files = const {},
    bool requiresAuth = true,
  }) async {
    return _sendMultipart(
      'PATCH',
      endpoint,
      fields: fields,
      files: files,
      requiresAuth: requiresAuth,
    );
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final loginError = _requireLogin(requiresAuth);
      if (loginError != null) return loginError;

      final url = '$baseUrl$endpoint';
      debugPrint('DELETE: $url');
      final response = await http
          .delete(Uri.parse(url), headers: getHeaders(requiresAuth: requiresAuth))
          .timeout(const Duration(seconds: 15));

      return handleResponse(response);
    } catch (e) {
      debugPrint('DELETE Error: $e');
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  static Map<String, dynamic> handleResponse(http.Response response) {
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
              ? body.substring(0, _min(body.length, 200))
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

  static String getErrorMessage(dynamic error) {
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

  static Future<Map<String, dynamic>> _sendMultipart(
    String method,
    String endpoint, {
    Map<String, String> fields = const {},
    Map<String, List<File>> files = const {},
    bool requiresAuth = true,
  }) async {
    try {
      final loginError = _requireLogin(requiresAuth);
      if (loginError != null) return loginError;

      final url = '$baseUrl$endpoint';
      debugPrint('$method (Multipart): $url');

      final request = http.MultipartRequest(method, Uri.parse(url));
      if (requiresAuth && _token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.headers['Accept'] = 'application/json';
      request.fields.addAll(fields);

      for (final entry in files.entries) {
        for (final file in entry.value) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, file.path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 45),
          );
      final response = await http.Response.fromStream(streamedResponse);
      return handleResponse(response);
    } catch (e) {
      debugPrint('$method multipart error: $e');
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  static Map<String, dynamic>? _requireLogin(bool requiresAuth) {
    if (requiresAuth && !isLoggedIn) {
      return {
        'success': false,
        'message': 'Token not found. Please login again.',
        'requiresLogin': true,
      };
    }
    return null;
  }

  static int _min(int a, int b) => a < b ? a : b;
}
