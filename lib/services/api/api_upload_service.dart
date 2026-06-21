import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

class ApiUploadService {
  static Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fieldName,
  }) async {
    try {
      if (!ApiClient.isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '${ApiClient.baseUrl}/api/v1/upload';
      debugPrint('Uploading file: $filePath');

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(ApiClient.getHeaders(requiresAuth: true));
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return ApiClient.handleResponse(response);
    } catch (e) {
      debugPrint('File upload error: $e');
      return {'success': false, 'message': ApiClient.getErrorMessage(e)};
    }
  }
}
