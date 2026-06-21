import 'dart:async';

import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import '../screens/common/calls/audio_call_screen.dart';
import '../screens/common/calls/video_call_screen.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class CallManager {
  static final CallManager _instance = CallManager._internal();
  static CallManager get instance => _instance;
  CallManager._internal();

  BuildContext? _context;
  bool _isListening = false;
  bool _isIncomingDialogShowing = false;
  String? _activeIncomingCallKey;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<void>? _reconnectSubscription;
  Timer? _incomingTimeout;
  Function(dynamic)? _incomingCallHandler;

  void initialize(BuildContext context) {
    _context = context;
    if (_isListening) {
      debugPrint('CallManager already listening - updating context');
      _setupCallListeners();
      return;
    }
    _setupCallListeners();
    _isListening = true;

    _connectionSubscription?.cancel();
    _connectionSubscription =
        SocketService.instance.connectionStream.listen((connected) {
      if (connected) {
        debugPrint('CallManager: Socket connected - ensuring listeners');
        _setupCallListeners();
      }
    });

    _reconnectSubscription?.cancel();
    _reconnectSubscription = SocketService.instance.reconnectStream.listen((_) {
      debugPrint('CallManager: Socket reconnected - ensuring listeners');
      _setupCallListeners();
    });

    debugPrint('CallManager initialized');
  }

  void _setupCallListeners() {
    final socket = SocketService.instance.socket;
    if (socket == null) return;

    if (_incomingCallHandler != null) {
      socket.off('call:incoming', _incomingCallHandler);
    }

    _incomingCallHandler = (data) {
      debugPrint('Incoming call: $data');
      Map<String, dynamic> callData;
      if (data is Map<String, dynamic>) {
        callData = data;
      } else if (data is Map) {
        callData = Map<String, dynamic>.from(data);
      } else {
        return;
      }
      if (_context != null && _context!.mounted) {
        _handleIncomingCall(callData);
      }
    };
    socket.on('call:incoming', _incomingCallHandler!);
  }

  Future<void> _handleIncomingCall(Map<String, dynamic> callData) async {
    final isVideo = callData['isVideo'] == true;
    final chatId = callData['chatId']?.toString() ?? '';
    final fromUserId = callData['fromUserId']?.toString() ?? '';
    final fromUserName =
        callData['fromUserName']?.toString() ??
        callData['callerName']?.toString() ??
        'Caller';
    final fromUserAvatar =
        callData['fromUserAvatar']?.toString() ??
        callData['callerAvatar']?.toString();
    final uuid = callData['uuid']?.toString();
    final callKey = uuid != null && uuid.isNotEmpty ? uuid : chatId;

    if (_context == null || !_context!.mounted) return;
    if (_isIncomingDialogShowing) {
      if (_activeIncomingCallKey == callKey) {
        debugPrint('Ignoring duplicate incoming call: $callKey');
        return;
      }
      await _rejectIncomingCall(
        chatId: chatId,
        fromUserId: fromUserId,
        uuid: uuid,
      );
      return;
    }

    _isIncomingDialogShowing = true;
    _activeIncomingCallKey = callKey;
    _incomingTimeout?.cancel();
    BuildContext? dialogContext;

    _incomingTimeout = Timer(const Duration(seconds: 30), () async {
      await _rejectIncomingCall(chatId: chatId, fromUserId: fromUserId, uuid: uuid);
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
    });

    await showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (ctx) => IncomingCallDialog(
        onDialogReady: (readyContext) => dialogContext = readyContext,
        callerName: fromUserName,
        callerAvatar: fromUserAvatar,
        isVideo: isVideo,
        onAccept: () async {
          _incomingTimeout?.cancel();
          Navigator.pop(ctx);
          final accepted = await ApiService.acceptCall(
            chatId: chatId,
            fromUserId: fromUserId,
          );
          final acceptPayload = {
            'chatId': chatId,
            'fromUserId': fromUserId,
          };
          await SocketService.instance.emit('call:accept', acceptPayload);
          Future.delayed(const Duration(milliseconds: 600), () {
            SocketService.instance.emit('call:accept', acceptPayload);
          });
          if (accepted['success'] != true) {
            debugPrint('REST accept failed, socket accept fallback emitted');
          }
          if (isVideo) {
            Navigator.push(
                _context!,
                MaterialPageRoute(
                  builder: (_) => VideoCallScreen(
                    chatId: chatId,
                    userName: fromUserName,
                    userAvatar: fromUserAvatar,
                    otherUserId: fromUserId,
                    isInitiator: false,
                    uuid: uuid,
                  ),
                ));
          } else {
            Navigator.push(
                _context!,
                MaterialPageRoute(
                  builder: (_) => AudioCallScreen(
                    chatId: chatId,
                    userName: fromUserName,
                    userAvatar: fromUserAvatar,
                    otherUserId: fromUserId,
                    isInitiator: false,
                    uuid: uuid,
                  ),
                ));
          }
        },
        onReject: () async {
          _incomingTimeout?.cancel();
          Navigator.pop(ctx);
          await _rejectIncomingCall(
            chatId: chatId,
            fromUserId: fromUserId,
            uuid: uuid,
          );
        },
      ),
    );
    _incomingTimeout?.cancel();
    _isIncomingDialogShowing = false;
    _activeIncomingCallKey = null;
  }

  Future<void> handleIncomingCallFromPush(Map<String, dynamic> callData) async {
    await _handleIncomingCall(callData);
  }

  Future<void> _rejectIncomingCall({
    required String chatId,
    required String fromUserId,
    required String? uuid,
  }) async {
    final rejected = await ApiService.rejectCall(
      chatId: chatId,
      toUserId: fromUserId,
    );
    if (rejected['success'] != true) {
      await SocketService.instance.emit('call:reject', {
        'toUserId': fromUserId,
        'chatId': chatId,
        'uuid': uuid,
      });
    }
  }

  void dispose() {
    _incomingTimeout?.cancel();
    if (_incomingCallHandler != null) {
      SocketService.instance.socket?.off('call:incoming', _incomingCallHandler);
      _incomingCallHandler = null;
    }
    _connectionSubscription?.cancel();
    _reconnectSubscription?.cancel();
    _context = null;
    _isListening = false;
    _isIncomingDialogShowing = false;
    _activeIncomingCallKey = null;
    debugPrint('CallManager disposed');
  }
}

class IncomingCallDialog extends StatelessWidget {
  final String callerName;
  final String? callerAvatar;
  final bool isVideo;
  final ValueChanged<BuildContext> onDialogReady;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const IncomingCallDialog({
    super.key,
    required this.callerName,
    this.callerAvatar,
    required this.isVideo,
    required this.onDialogReady,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) onDialogReady(context);
    });
    final colors = AppTheme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.heading,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white24,
              backgroundImage:
                  callerAvatar != null ? NetworkImage(callerAvatar!) : null,
              child: callerAvatar == null
                  ? const Icon(Icons.person, color: Colors.white70, size: 40)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(callerName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              isVideo ? 'Incoming Video Call...' : 'Incoming Audio Call...',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: onReject,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.call_end,
                        color: Colors.white, size: 32),
                  ),
                ),
                GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                    child: Icon(isVideo ? Icons.videocam : Icons.call,
                        color: Colors.white, size: 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
