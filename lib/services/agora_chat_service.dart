import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:flutter/foundation.dart';
import '../config/agora_config.dart';
import '../services/api_service.dart';
import 'dart:io';

class AgoraChatService {
  static final AgoraChatService _instance = AgoraChatService._internal();
  static AgoraChatService get instance => _instance;
  AgoraChatService._internal();

  bool _isInitialized = false;
  bool get isConnected => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    ChatOptions options = ChatOptions(
      appKey: AgoraConfig.chatAppKey,
      autoLogin: false,
      enableDNSConfig: true,
    );
    await ChatClient.getInstance.init(options);
    _addConnectionListener();
    await ChatClient.getInstance.startCallback();
    _isInitialized = true;
    debugPrint('Agora Chat SDK Initialized');
  }

  void _addConnectionListener() {
    ChatClient.getInstance.addConnectionEventHandler(
      "GLOBAL_CONNECTION",
      ConnectionEventHandler(
        onConnected: () => debugPrint('[Agora] Connected to server'),
        onDisconnected: () => debugPrint('[Agora] Disconnected'),
        onTokenWillExpire: () => debugPrint('[Agora] Token will expire'),
        onTokenDidExpire: () => debugPrint('[Agora] Token expired'),
      ),
    );
  }

  Future<bool> checkConnection() async =>
      await ChatClient.getInstance.isConnected();

  Future<void> login(String userId, {String? token}) async {
    try {
      if (await ChatClient.getInstance.isLoginBefore()) {
        final currentId = await ChatClient.getInstance.getCurrentUserId();
        if (currentId == userId) {
          debugPrint('Already logged in as $userId');
          _syncAllConversationsFromServer();
          return;
        }
        await ChatClient.getInstance.logout();
      }

      String? loginToken = token;
      if (loginToken == null) {
        final response = await ApiService.getAgoraChatToken();
        if (response['success'] == true) {
          loginToken = response['data']?['token'];
        }
      }

      if (loginToken != null && loginToken.isNotEmpty) {
        await ChatClient.getInstance.loginWithToken(userId, loginToken);
      } else {
        await ChatClient.getInstance.loginWithPassword(userId, userId);
      }
      debugPrint('Agora Chat login success: $userId');
      _syncAllConversationsFromServer();
    } catch (e) {
      debugPrint('Agora Chat login error: $e');
    }
  }

  Future<void> _syncAllConversationsFromServer() async {
    try {
      await ChatClient.getInstance.chatManager.loadAllConversations();
      debugPrint('Conversations synced from server');
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<List<ChatConversation>> getAllConversations() async {
    try {
      return await ChatClient.getInstance.chatManager
          .getAllConversations();
    } catch (e) {
      debugPrint('Get conversations error: $e');
      return [];
    }
  }

  Future<ChatMessage?> sendTextMessage({
    required String conversationId,
    required String text,
    String targetType = 'user',
  }) async {
    try {
      final msg = ChatMessage.createTxtSendMessage(
        targetId: conversationId,
        content: text,
        targetType: targetType,
      );
      await ChatClient.getInstance.chatManager.sendMessage(msg);
      return msg;
    } catch (e) {
      debugPrint('Send message error: $e');
      return null;
    }
  }

  Future<ChatMessage?> sendImageMessage({
    required String conversationId,
    required String imagePath,
    String targetType = 'user',
  }) async {
    try {
      final msg = ChatMessage.createImageSendMessage(
        targetId: conversationId,
        filePath: imagePath,
        targetType: targetType,
      );
      await ChatClient.getInstance.chatManager.sendMessage(msg);
      return msg;
    } catch (e) {
      debugPrint('Send image error: $e');
      return null;
    }
  }

  Future<void> deleteMessages({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    try {
      await ChatClient.getInstance.chatManager
          .deleteRemoteMessagesBeforeTimestamp(conversationId, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Delete messages error: $e');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await ChatClient.getInstance.chatManager
          .deleteConversation(conversationId);
    } catch (e) {
      debugPrint('Delete conversation error: $e');
    }
  }

  Future<void> markAllMessagesAsRead(String conversationId) async {
    try {
      await ChatClient.getInstance.chatManager
          .markAllMessagesAsRead(conversationId);
    } catch (e) {
      debugPrint('Mark read error: $e');
    }
  }

  Future<List<ChatMessage>> loadMessages({
    required String conversationId,
    int pageSize = 50,
    String? startMessageId,
  }) async {
    try {
      final cursor = await ChatClient.getInstance.chatManager
          .fetchHistoryMessages(
        conversationId: conversationId,
        pageSize: pageSize,
        startMessageId: startMessageId ?? '',
      );
      return cursor?.messages ?? [];
    } catch (e) {
      debugPrint('Load messages error: $e');
      return [];
    }
  }

  void addMessageListener(String name, ChatEventHandler handler) {
    ChatClient.getInstance.chatManager.addMessageEventHandler(name, handler);
  }

  void removeMessageListener(String name) {
    ChatClient.getInstance.chatManager.removeMessageEventHandler(name);
  }

  Future<void> logout() async {
    try {
      await ChatClient.getInstance.logout();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await ChatClient.getInstance.logout();
    } catch (_) {}
  }
}
