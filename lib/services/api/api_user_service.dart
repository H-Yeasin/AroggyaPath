import 'package:arogya_path3/core/utils/api_config.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';

class ApiUserEndpointService {
  static final Map<String, Map<String, dynamic>> _profileCache = {};

  static Future<Map<String, dynamic>> getUserProfile({String? userId}) async {
    if (userId != null && _profileCache.containsKey(userId)) {
      debugPrint('Cache Hit: User profile for $userId');
      return _profileCache[userId]!;
    }

    final endpoint = userId != null
        ? '${ApiConfig.getUserById}/$userId'
        : ApiConfig.userProfile;

    final result = await ApiClient.get(endpoint, requiresAuth: true);

    if (result['success'] == true && userId != null) {
      _profileCache[userId] = result;
    }

    return result;
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required Map<String, dynamic> data,
  }) {
    return ApiClient.put('/api/v1/user/profile', data, requiresAuth: true);
  }
}
