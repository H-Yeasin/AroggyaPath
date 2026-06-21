import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/navigation/app_navigator.dart';
import '../screens/common/calls/audio_call_screen.dart';
import '../screens/common/calls/video_call_screen.dart';
import 'api_service.dart';
import 'call_manager_service.dart';
import 'callkit_service.dart';
import 'socket_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  static PushNotificationService get instance => _instance;
  PushNotificationService._internal();

  static String? currentChatId;

  static const _defaultChannel = AndroidNotificationChannel(
    'aroggyapath_notifications',
    'AroggyaPath Notifications',
    description: 'Appointment, chat, and account notifications',
    importance: Importance.high,
  );

  static const _callChannel = AndroidNotificationChannel(
    'aroggyapath_calls',
    'Incoming Calls',
    description: 'Incoming audio and video calls',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final data = _decodePayload(payload);
        if (data != null) handleNotificationTap(data);
      },
    );

    await _createAndroidChannels();
    await requestPermissions();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotificationTap(message.data);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await handleNotificationTap(initialMessage.data);
    }

    _messaging.onTokenRefresh.listen((token) {
      syncDeviceToken(token: token);
    });

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestFullScreenIntentPermission();
    }
  }

  Future<void> syncDeviceToken({String? token}) async {
    try {
      if (!ApiService.isLoggedIn) return;

      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final role = prefs.getString('user_role');
      if (userId == null || userId.isEmpty) return;

      final response = await ApiService.registerDeviceToken(
        token: fcmToken,
        platform: _platformName,
        userId: userId,
        role: role,
      );

      if (response['success'] == true) {
        await prefs.setString('fcm_token', fcmToken);
        debugPrint('FCM token synced');
      } else {
        debugPrint('FCM token sync failed: ${response['message']}');
      }
    } catch (e) {
      debugPrint('FCM token sync error: $e');
    }
  }

  Future<void> unregisterDeviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token') ?? await _messaging.getToken();
      if (token == null || token.isEmpty || !ApiService.isLoggedIn) return;
      await ApiService.unregisterDeviceToken(token: token);
      await prefs.remove('fcm_token');
    } catch (e) {
      debugPrint('FCM token unregister error: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    final type = _notificationType(data);

    if (type == 'call_incoming') {
      await _showIncomingCallNotification(data, message: message);
      await _handleIncomingCallData(data, showInAppDialog: true);
      return;
    }

    if (type == 'chat_message' && data['chatId']?.toString() == currentChatId) {
      return;
    }

    await showNotificationFromRemoteMessage(message);
  }

  static Future<void> showLocalNotificationForChat({
    required String senderName,
    required String content,
    required String chatId,
    required String otherUserId,
    String? avatar,
  }) async {
    await instance.showLocalNotification(
      title: senderName,
      body: content,
      data: {
        'type': 'chat_message',
        'chatId': chatId,
        'otherUserId': otherUserId,
        if (avatar != null) 'avatar': avatar,
      },
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    await initialize();

    final isCall = _notificationType(data) == 'call_incoming';
    final android = AndroidNotificationDetails(
      isCall ? _callChannel.id : _defaultChannel.id,
      isCall ? _callChannel.name : _defaultChannel.name,
      channelDescription:
          isCall ? _callChannel.description : _defaultChannel.description,
      importance: isCall ? Importance.max : Importance.high,
      priority: isCall ? Priority.max : Priority.high,
      category:
          isCall ? AndroidNotificationCategory.call : AndroidNotificationCategory.message,
      fullScreenIntent: isCall,
      ongoing: isCall,
      autoCancel: !isCall,
      icon: '@mipmap/launcher_icon',
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      _notificationId(data),
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: jsonEncode(data),
    );
  }

  Future<void> showNotificationFromRemoteMessage(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    final notification = message.notification;
    final title = notification?.title ??
        data['title']?.toString() ??
        _titleForType(_notificationType(data));
    final body = notification?.body ??
        data['body']?.toString() ??
        data['message']?.toString() ??
        'Open AroggyaPath for details';

    if (_notificationType(data) == 'call_incoming') {
      await _showIncomingCallNotification(data, message: message);
      return;
    }

    await showLocalNotification(title: title, body: body, data: data);
  }

  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    final type = _notificationType(data);

    if (type == 'call_incoming') {
      await _handleIncomingCallData(data, showInAppDialog: true);
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (type == 'appointment_created' ||
        type == 'appointment_accepted' ||
        type == 'appointment_cancelled' ||
        type == 'call_missed' ||
        type == 'chat_message') {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role')?.toLowerCase();
      navigator.pushNamed(role == 'doctor' ? '/doctor-home' : '/patient-home');
      return;
    }

    navigator.pushNamed('/splash');
  }

  Future<void> _showIncomingCallNotification(
    Map<String, dynamic> data, {
    RemoteMessage? message,
  }) async {
    final callerName = data['fromUserName']?.toString() ??
        data['callerName']?.toString() ??
        message?.notification?.title ??
        'Incoming call';
    final isVideo = _isTruthy(data['isVideo']);
    await showLocalNotification(
      title: callerName,
      body: isVideo ? 'Incoming video call' : 'Incoming audio call',
      data: data,
    );
  }

  Future<void> _handleIncomingCallData(
    Map<String, dynamic> data, {
    required bool showInAppDialog,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null && userId.isNotEmpty && !SocketService.instance.isConnected) {
      await SocketService.instance.connect(userId);
    }

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted && showInAppDialog) {
      CallManager.instance.initialize(context);
      await CallManager.instance.handleIncomingCallFromPush(data);
      return;
    }

    CallKitService.pendingCallData = data;
  }

  Future<void> openPendingCallIfAny() async {
    final data = CallKitService.consumePendingCallData();
    if (data == null) return;
    await _openCallScreen(data);
  }

  Future<void> _openCallScreen(Map<String, dynamic> data) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      CallKitService.pendingCallData = data;
      return;
    }

    final chatId = data['chatId']?.toString() ?? '';
    final otherUserId =
        data['fromUserId']?.toString() ?? data['callerId']?.toString() ?? '';
    if (chatId.isEmpty || otherUserId.isEmpty) return;

    final userName = data['fromUserName']?.toString() ??
        data['callerName']?.toString() ??
        'Caller';
    final userAvatar =
        data['fromUserAvatar']?.toString() ?? data['callerAvatar']?.toString();
    final uuid = data['uuid']?.toString();
    final isVideo = _isTruthy(data['isVideo']);

    final accepted = await ApiService.acceptCall(
      chatId: chatId,
      fromUserId: otherUserId,
    );
    await SocketService.instance.emit('call:accept', {
      'chatId': chatId,
      'fromUserId': otherUserId,
    });
    if (accepted['success'] != true) {
      debugPrint('Accept from notification failed: ${accepted['message']}');
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => isVideo
            ? VideoCallScreen(
                chatId: chatId,
                userName: userName,
                userAvatar: userAvatar,
                otherUserId: otherUserId,
                isInitiator: false,
                uuid: uuid,
              )
            : AudioCallScreen(
                chatId: chatId,
                userName: userName,
                userAvatar: userAvatar,
                otherUserId: otherUserId,
                isInitiator: false,
                uuid: uuid,
              ),
      ),
    );
  }

  Future<void> _createAndroidChannels() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_defaultChannel);
    await androidPlugin?.createNotificationChannel(_callChannel);
  }

  static Map<String, dynamic>? _decodePayload(String payload) {
    try {
      return Map<String, dynamic>.from(jsonDecode(payload) as Map);
    } catch (_) {
      return null;
    }
  }

  static String _notificationType(Map<String, dynamic> data) {
    return (data['type'] ?? data['notificationType'] ?? '').toString();
  }

  static bool _isTruthy(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'video';
  }

  static int _notificationId(Map<String, dynamic> data) {
    final raw = data['uuid']?.toString() ??
        data['notificationId']?.toString() ??
        data['chatId']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    return raw.hashCode & 0x7fffffff;
  }

  static String _titleForType(String type) {
    switch (type) {
      case 'appointment_created':
        return 'New appointment';
      case 'appointment_accepted':
        return 'Appointment accepted';
      case 'appointment_cancelled':
        return 'Appointment cancelled';
      case 'call_missed':
        return 'Missed call';
      case 'chat_message':
        return 'New message';
      default:
        return 'AroggyaPath';
    }
  }

  static String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return Platform.operatingSystem;
  }
}
