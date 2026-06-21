import 'api_client.dart';

class ApiAppointmentEndpointService {
  static Future<Map<String, dynamic>> getAppointments() {
    return ApiClient.get('/api/v1/appointment', requiresAuth: true);
  }

  static Future<Map<String, dynamic>> createAppointment({
    required Map<String, dynamic> appointmentData,
  }) {
    return ApiClient.post(
      '/api/v1/appointment',
      appointmentData,
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) {
    return ApiClient.patch(
      '/api/v1/appointment/$appointmentId',
      {'status': status},
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> cancelAppointment({
    required String appointmentId,
  }) {
    return ApiClient.patch(
      '/api/v1/appointment/$appointmentId/cancel',
      {},
      requiresAuth: true,
    );
  }
}
