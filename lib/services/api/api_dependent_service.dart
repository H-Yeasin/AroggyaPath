import 'api_client.dart';

class ApiDependentEndpointService {
  static Future<Map<String, dynamic>> getDependents() {
    return ApiClient.get('/api/v1/user/me/dependents', requiresAuth: true);
  }

  static Future<Map<String, dynamic>> addDependent({
    required Map<String, dynamic> dependentData,
  }) {
    return ApiClient.post(
      '/api/v1/user/me/dependents',
      dependentData,
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> updateDependent({
    required String dependentId,
    required Map<String, dynamic> data,
  }) {
    return ApiClient.patch(
      '/api/v1/user/me/dependents/$dependentId',
      data,
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> deleteDependent({
    required String dependentId,
  }) {
    return ApiClient.delete(
      '/api/v1/user/me/dependents/$dependentId',
      requiresAuth: true,
    );
  }
}
