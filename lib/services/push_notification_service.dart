import 'package:flutter/material.dart';

/// Push notification service stub.
/// Full FCM + local notification implementation deferred.
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  static PushNotificationService get instance => _instance;
  PushNotificationService._internal();

  static String? currentChatId;

  /// Show a local notification for an incoming chat message
  static Future<void> showLocalNotificationForChat({
    required String senderName,
    required String content,
    required String chatId,
    required String otherUserId,
    String? avatar,
  }) async {
    debugPrint('[Notification] $senderName: $content (chat: $chatId)');
    // Full local notification display deferred
  }
}
