import 'package:flutter/material.dart';

/// CallKit service stub — full native CallKit integration deferred.
/// To enable native incoming call UI, add `flutter_callkit_incoming` to pubspec.yaml
/// and implement the full CallKitService from theking943.
class CallKitService {
  static String? _cachedAgoraToken;
  static Map<String, dynamic>? pendingCallData;

  /// Consume a cached Agora token (for when a token was fetched before
  /// the call screen appeared, e.g. from a push notification).
  static String? consumeCachedAgoraToken() {
    final token = _cachedAgoraToken;
    _cachedAgoraToken = null;
    return token;
  }

  /// Check for and consume any pending call data from a push notification.
  static Map<String, dynamic>? consumePendingCallData() {
    final data = pendingCallData;
    if (data != null) {
      debugPrint('[CallKit] Consuming pending call data');
      pendingCallData = null;
    }
    return data;
  }
}
