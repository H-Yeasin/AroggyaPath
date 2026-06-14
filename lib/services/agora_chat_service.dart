import 'dart:io';

import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arogya_path3/config/agora_config.dart';
import 'package:arogya_path3/services/api_service.dart';
import 'package:arogya_path3/services/push_notification_service.dart';

class AgoraChatService {
  static final AgoraChatService _instance = AgoraChatService._internal();
  static AgoraChatService get instance => _instance;

  AgoraChatService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    ChatOptions options = ChatOptions(
      appKey: AgoraConfig.chatAppKey,
      autoLogin: false,
      enableDNSConfig: true,
    );

    await ChatClient.getInstance.init(options);

    // Listen for connection events
    _addConnectionListener();

    // CRITICAL: Notify the SDK that the UI is ready to receive callbacks
    await ChatClient.getInstance.startCallback();

    _isInitialized = true;
    debugPrint('Agora Chat SDK Initialized');

    // Add a global listener for debugging
    _setupGlobalDebugListener();
  }

  void _addConnectionListener() {
    ChatClient.getInstance.addConnectionEventHandler(
      "GLOBAL_CONNECTION",
      ConnectionEventHandler(
        onConnected: () {
          debugPrint(' [AGORA] Connected to server');
        },
        onDisconnected: () {
          debugPrint(' [AGORA] Disconnected from server');
        },
        onTokenWillExpire: () {
          debugPrint(' [AGORA] Token will expire soon');
        },
        onTokenDidExpire: () {
          debugPrint(' [AGORA] Token expired');
        },
      ),
    );
  }

  Future<bool> checkConnection() async {
    final status = await ChatClient.getInstance.isConnected();
    debugPrint('🌐 [AGORA] Connection Status: $status');
    return status;
  }

  bool get isConnected => _isInitialized;

  Future<void> login(String userId, {String? token}) async {
    try {
      if (await ChatClient.getInstance.isLoginBefore()) {
        final currentId = await ChatClient.getInstance.getCurrentUserId();
        if (currentId == userId) {
          debugPrint('✅ Already logged in as $userId');
          // ✅ Still sync from server in case of reinstall
          _syncAllConversationsFromServer();
          return;
        }
        await ChatClient.getInstance.logout();
      }

      String? loginToken = token;
      if (loginToken == null) {
        debugPrint('🔍 Fetching Agora Chat token for login...');
        final response = await ApiService.getAgoraChatToken();
        if (response['success'] == true) {
          loginToken = response['data']?['token'];
        }
      }

      if (loginToken != null && loginToken.isNotEmpty) {
        debugPrint('✅ Logging into Agora with token');
        await ChatClient.getInstance.loginWithToken(userId, loginToken);
      } else {
        // Fallback or error - using userId as password (original insecure way)
        debugPrint('⚠️ No token found, falling back to insecure login');
        await ChatClient.getInstance.loginWithPassword(userId, userId);
      }
      debugPrint('✅ Agora Chat Login Success: $userId');

      // ✅ Sync conversations from server after login (handles reinstall case)
      _syncAllConversationsFromServer();
    } on ChatError catch (e) {
      if (e.code == 200) {
        // ✅ Error 200 means "User already logged in"
        debugPrint('ℹ️ User already logged in (Code 200)');
        _syncAllConversationsFromServer();
      } else if (e.code == 204) {
        // ✅ Error 204 means "User does not exist" - Try to register
        debugPrint(
          '⚠️ User $userId does not exist on Agora. Attempting auto-registration...',
        );
        try {
          // Note: createAccount requires password. We use userId as password for simplicity if token is not used.
          // In a production app, this should be handled server-side.
          await ChatClient.getInstance.createAccount(userId, userId);
          debugPrint(
            '✅ Agora Auto-Registration Success for $userId. Retrying login...',
          );
          // Retry login after successful registration
          await login(userId, token: token);
        } on ChatError catch (regError) {
          debugPrint(
            '❌ Agora Auto-Registration Failed: ${regError.description} (Code: ${regError.code})',
          );
        }
      } else {
        debugPrint(
          '❌ Agora Chat Login Failed: ${e.description} (Code: ${e.code})',
        );
      }
    }
  }

  /// ✅ Sync all conversations and recent messages from Agora server
  /// This ensures chat history is available after app reinstall
  void _syncAllConversationsFromServer() async {
    try {
      debugPrint('🔄 [Agora] Syncing conversations from server...');

      // First, try to get conversation list from local
      List<ChatConversation> conversations = await ChatClient
          .getInstance
          .chatManager
          .loadAllConversations();

      // If no local conversations (e.g., after reinstall), try to get chat list from backend
      if (conversations.isEmpty) {
        debugPrint(
          '📋 [Agora] No local conversations, fetching from backend...',
        );
        try {
          final response = await ApiService.getMyChats();
          if (response['success'] == true && response['data'] != null) {
            final chatList = response['data'] as List? ?? [];
            debugPrint(
              '📋 [Agora] Found ${chatList.length} chats from backend',
            );

            // For each chat, fetch history messages from Agora server using the other user's ID
            for (final chat in chatList) {
              final participants = chat['participants'] as List? ?? [];
              for (final participant in participants) {
                final participantId = participant['_id']?.toString();
                if (participantId != null) {
                  try {
                    await ChatClient.getInstance.chatManager
                        .fetchHistoryMessagesByOption(
                          participantId,
                          ChatConversationType.Chat,
                          cursor: '',
                          pageSize: 20,
                        );
                    debugPrint('  ✅ Synced messages for $participantId');
                  } catch (e) {
                    debugPrint(
                      '  ⚠️ Failed to sync messages for $participantId: $e',
                    );
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [Agora] Backend chat list fetch failed: $e');
        }
      } else {
        debugPrint(
          '📋 [Agora] Found ${conversations.length} local conversations',
        );

        // For each conversation, fetch recent messages from server to ensure they're up to date
        for (final conv in conversations) {
          try {
            final messages = await ChatClient.getInstance.chatManager
                .fetchHistoryMessagesByOption(
                  conv.id,
                  ChatConversationType.Chat,
                  cursor: '',
                  pageSize: 20,
                );
            debugPrint(
              '  ✅ Synced ${messages.data.length} messages for ${conv.id}',
            );
          } catch (e) {
            debugPrint('  ⚠️ Failed to sync messages for ${conv.id}: $e');
          }
        }
      }

      debugPrint('✅ [Agora] Server sync complete');
    } catch (e) {
      debugPrint('⚠️ [Agora] Server sync failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await ChatClient.getInstance.logout();
      debugPrint('✅ Agora Chat Logout Success');
    } on ChatError catch (e) {
      debugPrint('❌ Agora Chat Logout Failed: ${e.description}');
    }
  }

  Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String content,
    String? backendChatId, // ✅ Added for backend sync (notifications)
    ChatType type = ChatType.Chat,
    List<File>? files,
    Map<String, dynamic>? attributes, // ✅ Added attributes support
  }) async {
    try {
      // 0. Get our own profile for attributes
      final prefs = await SharedPreferences.getInstance();
      final myName = prefs.getString('user_full_name') ?? 'User';
      final myAvatar = prefs.getString('user_avatar') ?? '';

      debugPrint('📝 [SendMessage] Sender Info:');
      debugPrint('   - Name: $myName');
      debugPrint('   - Avatar: $myAvatar');
      debugPrint('   - Backend Chat ID: $backendChatId');

      final Map<String, dynamic> msgAttributes = {
        'senderName': myName,
        'senderAvatar': myAvatar,
        'chatId': backendChatId ?? conversationId,
        ...?attributes,
      };

      ChatMessage? lastMessage;

      // 1. Send via Agora SDK (Real-time & Data)
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          final message = ChatMessage.createImageSendMessage(
            targetId: conversationId,
            filePath: file.path,
            chatType: type,
          );
          message.attributes = msgAttributes;

          // Add status listener for better debugging — use fixed key to prevent duplicates
          ChatClient.getInstance.chatManager.removeMessageEvent(
            "SEND_FILE_HANDLER",
          );
          ChatClient.getInstance.chatManager.addMessageEvent(
            "SEND_FILE_HANDLER",
            ChatMessageEvent(
              onSuccess: (msgId, msg) =>
                  debugPrint("✅ File sent via Agora: $msgId"),
              onError: (msgId, msg, err) =>
                  debugPrint("❌ File send failed (Agora): ${err.description}"),
            ),
          );

          await ChatClient.getInstance.chatManager.sendMessage(message);
          lastMessage = message;
        }

        if (content.isNotEmpty) {
          final message = ChatMessage.createTxtSendMessage(
            targetId: conversationId,
            content: content,
            chatType: type,
          );
          message.attributes = msgAttributes;
          await ChatClient.getInstance.chatManager.sendMessage(message);
          lastMessage = message;
        }
      } else {
        final message = ChatMessage.createTxtSendMessage(
          targetId: conversationId,
          content: content,
          chatType: type,
        );
        message.attributes = msgAttributes;

        // Use fixed key to prevent stacking duplicate handlers
        ChatClient.getInstance.chatManager.removeMessageEvent(
          "SEND_MSG_HANDLER",
        );
        ChatClient.getInstance.chatManager.addMessageEvent(
          "SEND_MSG_HANDLER",
          ChatMessageEvent(
            onSuccess: (msgId, msg) =>
                debugPrint("✅ Message sent via Agora: $msgId"),
            onError: (msgId, msg, err) =>
                debugPrint("❌ Message send failed (Agora): ${err.description}"),
          ),
        );

        await ChatClient.getInstance.chatManager.sendMessage(message);
        lastMessage = message;
      }

      // 2. Sync with Backend to trigger Notification (Fire & Forget)
      if (backendChatId != null) {
        debugPrint('🔔 Syncing message to backend for notification...');

        String notifContent = content;
        String notifType = 'text';

        if (files != null && files.isNotEmpty) {
          // Determine type from first file extension or specific logic
          // Ideally should match the actual file type sent
          final path = files.first.path.toLowerCase();
          if (path.endsWith('.jpg') ||
              path.endsWith('.png') ||
              path.endsWith('.jpeg')) {
            notifType = 'image';
            notifContent = content.isNotEmpty ? content : '[Image]';
          } else if (path.endsWith('.mp4') || path.endsWith('.mov')) {
            notifType = 'video';
            notifContent = content.isNotEmpty ? content : '[Video]';
          } else {
            notifType = 'file';
            notifContent = content.isNotEmpty ? content : '[File]';
          }
        }

        // We do NOT await this to avoid blocking UI (Fire and Forget)
        // But we catch errors to ensure app stability
        ApiService.sendMessage(
              chatId: backendChatId,
              content: notifContent,
              contentType: notifType,
              // We do NOT pass 'files' here to avoid double-upload. Backend creates a "ghost" message for notification.
            )
            .then((res) {
              if (res['success'] == true) {
                debugPrint('✅ Backend notified successfully');
              } else {
                debugPrint('⚠️ Backend notification failed: ${res['message']}');
              }
            })
            .catchError((e) {
              debugPrint('❌ Backend notification error: $e');
            });
      }

      return lastMessage;
    } on ChatError catch (e) {
      debugPrint('❌ Send Message Failed: ${e.description}');
      rethrow;
    }
  }

  void addMessageListener(String identifier, ChatEventHandler handler) {
    debugPrint('📌 Adding Agora Message Listener: $identifier');
    ChatClient.getInstance.chatManager.addEventHandler(identifier, handler);
    // Ensure callbacks are active
    ChatClient.getInstance.startCallback();
  }

  void removeMessageListener(String identifier) {
    ChatClient.getInstance.chatManager.removeEventHandler(identifier);
  }

  Future<List<ChatMessage>> fetchHistoryMessages({
    required String conversationId,
    ChatConversationType type = ChatConversationType.Chat,
    String? startMsgId,
    int pageSize = 20,
  }) async {
    try {
      final result = await ChatClient.getInstance.chatManager
          .fetchHistoryMessagesByOption(
            conversationId,
            type,
            cursor: startMsgId ?? '',
            pageSize: pageSize,
          );
      return result.data;
    } on ChatError catch (e) {
      debugPrint('❌ Fetch History Failed: ${e.description}');
      return [];
    }
  }

  Future<List<ChatMessage>> loadMessagesFromLocal({
    required String conversationId,
    int pageSize = 20,
  }) async {
    try {
      ChatConversation? conv = await ChatClient.getInstance.chatManager
          .getConversation(conversationId);
      if (conv == null) return [];

      final messages = await conv.loadMessages();
      return messages;
    } on ChatError catch (e) {
      debugPrint('❌ Load Local Messages Failed: ${e.description}');
      return [];
    }
  }

  Future<List<ChatConversation>> fetchConversations() async {
    try {
      final List<ChatConversation> list = await ChatClient
          .getInstance
          .chatManager
          .loadAllConversations();
      return list;
    } on ChatError catch (e) {
      debugPrint('❌ Fetch Conversations Failed: ${e.description}');
      return [];
    }
  }

  Future<ChatMessage?> sendCallLog({
    required String conversationId,
    required String callType, // 'audio' or 'video'
    required String status, // 'missed', 'declined', 'ended', 'cancelled'
    String duration = '',
    String? backendChatId, // ✅ Added for notification sync
    String? uuid, // ✅ Added for CallKit sync
  }) async {
    final attributes = {
      'type': 'call_log',
      'call_type': callType,
      'status': status,
      'duration': duration,
      'uuid': uuid, // ✅ New parameter for CallKit sync
    };

    String content = '';
    switch (status) {
      case 'missed':
        content = 'Missed ${callType == 'video' ? 'video' : 'voice'} call';
        break;
      case 'declined':
        content = 'Declined ${callType == 'video' ? 'video' : 'voice'} call';
        break;
      case 'cancelled':
        content = 'Cancelled ${callType == 'video' ? 'video' : 'voice'} call';
        break;
      case 'ended':
        // Clean content for UI bubble handling
        content = '${callType == 'video' ? 'Video' : 'Voice'} call ended';
        break;
      default:
        content = '${callType == 'video' ? 'Video' : 'Voice'} call';
    }

    return sendMessage(
      conversationId: conversationId,
      content: content,
      attributes: attributes,
      backendChatId: backendChatId, // ✅ Trigger notification
    );
  }

  Future<void> markAllMessagesAsRead(String conversationId) async {
    try {
      debugPrint(
        '📖 [Agora] Marking all messages as read for: $conversationId',
      );
      ChatConversation? conv = await ChatClient.getInstance.chatManager
          .getConversation(conversationId);

      if (conv != null) {
        await conv.markAllMessagesAsRead();
        debugPrint(
          '✅ [Agora] Successfully marked all messages as read for $conversationId',
        );
      } else {
        debugPrint('⚠️ [Agora] Conversation not found for $conversationId');
      }
    } catch (e) {
      debugPrint('❌ Mark as Read Failed: $e');
    }
  }

  Future<void> deleteMessages({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    try {
      ChatConversation? conv = await ChatClient.getInstance.chatManager
          .getConversation(conversationId);
      if (conv == null) return;

      await conv.deleteMessageByIds(messageIds);

      // ✅ Server-side deletion
      await ChatClient.getInstance.chatManager.deleteRemoteMessagesWithIds(
        conversationId: conversationId,
        type: ChatConversationType.Chat,
        msgIds: messageIds,
      );

      debugPrint(
        '✅ Deleted ${messageIds.length} messages from $conversationId (Local & Server)',
      );
    } catch (e) {
      debugPrint('❌ Delete Messages Failed: $e');
      rethrow;
    }
  }

  Future<void> deleteConversation({
    required String conversationId,
    bool deleteMessages = true,
  }) async {
    try {
      await ChatClient.getInstance.chatManager.deleteConversation(
        conversationId,
        deleteMessages: deleteMessages,
      );

      // ✅ Server-side deletion
      await ChatClient.getInstance.chatManager.deleteRemoteConversation(
        conversationId,
        conversationType: ChatConversationType.Chat,
        isDeleteMessage: deleteMessages,
      );

      debugPrint('✅ Deleted conversation: $conversationId (Local & Server)');
    } catch (e) {
      debugPrint('❌ Delete Conversation Failed: $e');
      rethrow;
    }
  }

  void _setupGlobalDebugListener() {
    ChatClient.getInstance.chatManager.addEventHandler(
      "GLOBAL_DEBUG",
      ChatEventHandler(
        onMessagesReceived: (messages) {
          debugPrint('🌏 [GLOBAL AGORA] Received ${messages.length} messages');
          for (var msg in messages) {
            debugPrint(
              '🌏 [GLOBAL AGORA] MsgID: ${msg.msgId} | From: ${msg.from} | To: ${msg.to}',
            );
            debugPrint('   - Body: ${msg.body.toString()}');
            debugPrint('   - Attributes: ${msg.attributes}');

            // ✅ Trigger local notification if not in this chat
            _triggerLocalNotification(msg);

            // ✅ SMART SIGNALING: Intercept call_log messages to stop ringing
            if (msg.attributes?['type'] == 'call_log') {
              final status = msg.attributes?['status'];
              if (status == 'cancelled' || status == 'ended' || status == 'declined') {
                debugPrint(' 📴 [AGORA LOG] Call cancel signal matched via chat log');
                final uuid = msg.attributes?['uuid'];
                // CallKit stub — requires flutter_callkit_incoming package
                // if (uuid != null && uuid.toString().isNotEmpty) {
                //   FlutterCallkitIncoming.endCall(uuid.toString());
                // } else {
                //   FlutterCallkitIncoming.endAllCalls();
                // }
              }
            }
          }
        },
      ),
    );
  }

  void _triggerLocalNotification(ChatMessage msg) async {
    try {
      // 1. Get current logged in user ID to ensure we are the receiver
      final currentUserId = await ChatClient.getInstance.getCurrentUserId();
      if (msg.from == currentUserId) {
        return; // Don't notify for our own messages
      }

      // 2. Extract content
      String content = '';
      if (msg.body is ChatTextMessageBody) {
        content = (msg.body as ChatTextMessageBody).content;
      } else if (msg.body is ChatImageMessageBody) {
        content = '[Image]';
      } else if (msg.body is ChatFileMessageBody) {
        content = '[File]';
      }

      // 3. Extract metadata from attributes if possible
      final String senderName =
          msg.attributes?['senderName']?.toString() ?? msg.from ?? 'User';
      final String? avatar = msg.attributes?['senderAvatar']?.toString();
      final String? backendChatId =
          msg.attributes?['chatId']?.toString() ??
          msg.conversationId; // Fallback to conversation ID (Agora ID)

      if (backendChatId != null) {
        debugPrint(
          '🔔 Triggering Local Notification for $senderName in chat $backendChatId',
        );
        PushNotificationService.showLocalNotificationForChat(
          senderName: senderName,
          content: content,
          chatId: backendChatId,
          otherUserId: msg.from ?? '',
          avatar: avatar,
        );
      } else {
        debugPrint('⚠️ Skipping local notification: backendChatId is NULL');
      }
    } catch (e) {
      debugPrint('⚠️ Error triggering local notification: $e');
    }
  }
}
