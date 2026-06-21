import '../core/utils/api_config.dart';
import '../models/appointment_message_model.dart';
import 'api_service.dart';

class AppointmentMessageService {
  Future<Map<String, dynamic>> getMessages(String appointmentId) async {
    final response = await ApiService.get(
      '${ApiConfig.appointments}/$appointmentId/messages',
      requiresAuth: true,
    );

    if (response['success'] == true) {
      final items = response['data']?['items'];
      return {
        ...response,
        'messages': items is List
            ? items
                .whereType<Map<String, dynamic>>()
                .map(AppointmentMessageModel.fromJson)
                .toList()
            : <AppointmentMessageModel>[],
      };
    }

    return response;
  }

  Future<Map<String, dynamic>> sendMessage({
    required String appointmentId,
    required String content,
  }) async {
    final response = await ApiService.post(
      '${ApiConfig.appointments}/$appointmentId/messages',
      {'content': content},
      requiresAuth: true,
    );

    if (response['success'] == true && response['data'] is Map<String, dynamic>) {
      return {
        ...response,
        'messageModel': AppointmentMessageModel.fromJson(response['data']),
      };
    }

    return response;
  }
}
