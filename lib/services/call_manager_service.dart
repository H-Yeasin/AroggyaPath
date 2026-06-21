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
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<void>? _reconnectSubscription;

  void initialize(BuildContext context) {
    _context = context;
    if (_isListening) {
      debugPrint('CallManager already listening - updating context');
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

    socket.off('call:incoming');
    socket.off('call:accepted');
    socket.off('call:rejected');

    socket.on('call:incoming', (data) {
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
    });
  }

  void _handleIncomingCall(Map<String, dynamic> callData) async {
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

    if (_context == null || !_context!.mounted) return;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (ctx) => IncomingCallDialog(
        callerName: fromUserName,
        callerAvatar: fromUserAvatar,
        isVideo: isVideo,
        onAccept: () async {
          Navigator.pop(ctx);
          final accepted = await ApiService.acceptCall(
            chatId: chatId,
            fromUserId: fromUserId,
          );
          if (accepted['success'] != true) {
            await SocketService.instance.emit('call:accepted', {
              'chatId': chatId,
              'fromUserId': fromUserId,
            });
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
          Navigator.pop(ctx);
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
        },
      ),
    );

    // Auto-reject after 60s
    Future.delayed(const Duration(seconds: 60), () {
      if (_context != null && _context!.mounted) {
        try {
          Navigator.of(_context!).popUntil((route) => route.isFirst);
        } catch (_) {}
      }
    });
  }

  void dispose() {
    _connectionSubscription?.cancel();
    _reconnectSubscription?.cancel();
    _context = null;
    _isListening = false;
    debugPrint('CallManager disposed');
  }
}

class IncomingCallDialog extends StatelessWidget {
  final String callerName;
  final String? callerAvatar;
  final bool isVideo;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallDialog({
    super.key,
    required this.callerName,
    this.callerAvatar,
    required this.isVideo,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
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
