import 'package:arogya_path3/core/utils/api_config.dart';

import 'api_client.dart';

class ApiDoctorEndpointService {
  static Future<Map<String, dynamic>> getAllDoctors({
    int page = 1,
    int limit = 20,
    String? specialty,
  }) {
    var endpoint = '/api/v1/user/role/doctor?page=$page&limit=$limit';
    if (specialty != null && specialty.isNotEmpty) {
      endpoint += '&specialty=$specialty';
    }
    return ApiClient.get(endpoint, requiresAuth: false);
  }

  static Future<Map<String, dynamic>> getDoctorDetails({
    required String doctorId,
  }) {
    return ApiClient.get('/api/v1/user/$doctorId', requiresAuth: false);
  }

  static Future<Map<String, dynamic>> searchDoctors({
    required String query,
    int page = 1,
    int limit = 20,
  }) {
    return ApiClient.get(
      '/api/v1/user/find-doctors?q=$query&page=$page&limit=$limit',
      requiresAuth: false,
    );
  }

  static Future<Map<String, dynamic>> getAllCategories() {
    return ApiClient.get(ApiConfig.categories, requiresAuth: false);
  }

  static Future<Map<String, dynamic>> getReferralSetting() {
    return ApiClient.get(
      '/api/v1/app-setting/get-referral-setting',
      requiresAuth: false,
    );
  }
}
