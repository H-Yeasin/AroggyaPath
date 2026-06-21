import 'api_client.dart';

class ApiChatService {
  static Future<Map<String, dynamic>> getAgoraToken({
    required String channelName,
    String? account,
  }) {
    final encodedChannel = Uri.encodeQueryComponent(channelName);
    final encodedAccount =
        account == null ? null : Uri.encodeQueryComponent(account);
    return ApiClient.get(
      '/api/v1/call/token?channelName=$encodedChannel${encodedAccount == null ? '' : '&account=$encodedAccount'}',
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> initiateCall({
    required String chatId,
    required String receiverId,
    required bool isVideo,
  }) {
    return ApiClient.post(
      '/api/v1/call/initiate',
      {
        'chatId': chatId,
        'receiverId': receiverId,
        'isVideo': isVideo,
      },
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> acceptCall({
    required String chatId,
    required String fromUserId,
  }) {
    return ApiClient.post(
      '/api/v1/call/accept',
      {
        'chatId': chatId,
        'fromUserId': fromUserId,
      },
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> rejectCall({
    required String chatId,
    required String toUserId,
  }) {
    return ApiClient.post(
      '/api/v1/call/reject',
      {
        'chatId': chatId,
        'toUserId': toUserId,
      },
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> endCall({
    required String chatId,
    required String toUserId,
    String? uuid,
    bool isMissedCall = false,
  }) {
    return ApiClient.post(
      '/api/v1/call/end',
      {
        'chatId': chatId,
        'userId': toUserId,
        'uuid': uuid ?? '',
        'isMissedCall': isMissedCall,
      },
      requiresAuth: true,
    );
  }
}
