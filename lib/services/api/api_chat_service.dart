import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

class ApiChatService {
  static Future<Map<String, dynamic>> getAgoraChatToken() {
    debugPrint('Fetching Agora Chat Token');
    return ApiClient.get('/api/v1/chat/token', requiresAuth: true);
  }

  static Future<Map<String, dynamic>> getMyChats() {
    debugPrint('Getting my chats');
    return ApiClient.get('/api/v1/chat', requiresAuth: true);
  }

  static Future<Map<String, dynamic>> getChatMessages({
    required String chatId,
    required int page,
    required int limit,
  }) {
    debugPrint('Getting messages for chatId: $chatId');
    return ApiClient.get(
      '/api/v1/chat/$chatId/messages?page=$page&limit=$limit',
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> createOrGetChat({
    required String userId,
  }) {
    final cleanUserId = userId.split('/').first;
    debugPrint('Creating/Getting chat with: $cleanUserId');
    return ApiClient.post(
      '/api/v1/chat',
      {'userId': cleanUserId},
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> markChatAsRead({
    required String chatId,
  }) {
    debugPrint('Marking chat as read: $chatId');
    return ApiClient.patch('/api/v1/chat/$chatId/read', {}, requiresAuth: true);
  }

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
  }) {
    return ApiClient.post(
      '/api/v1/call/end',
      {
        'chatId': chatId,
        'userId': toUserId,
        'uuid': uuid ?? '',
      },
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    String? content,
    List<File>? files,
    String? contentType,
  }) async {
    try {
      final url = '${ApiClient.baseUrl}/api/v1/chat/$chatId/messages';
      debugPrint('POST (Multipart): $url');

      final request = http.MultipartRequest('POST', Uri.parse(url));

      if (ApiClient.token != null) {
        request.headers['Authorization'] = 'Bearer ${ApiClient.token}';
      }

      if (content != null && content.isNotEmpty) {
        request.fields['content'] = content;
      }
      if (contentType != null) {
        request.fields['contentType'] = contentType;
      }
      if (files != null) {
        for (final file in files) {
          request.files.add(
            await http.MultipartFile.fromPath('files', file.path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 30),
          );
      final response = await http.Response.fromStream(streamedResponse);
      return ApiClient.handleResponse(response);
    } catch (e) {
      debugPrint('Send message error: $e');
      return {'success': false, 'message': 'Failed to send message: $e'};
    }
  }
}
