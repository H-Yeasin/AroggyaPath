import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../services/active_call_state.dart';
import '../../../services/agora_chat_service.dart';
import '../../../services/agora_service.dart';
import '../../../services/api_service.dart';
import '../../../services/callkit_service.dart';
import '../../../services/socket_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String otherUserId;
  final bool isInitiator;
  final String? uuid;

  const VideoCallScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.userAvatar,
    required this.otherUserId,
    required this.isInitiator,
    this.uuid,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final AgoraService _agoraService = AgoraService.instance;

  int? _remoteUid;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isCallConnected = false;
  bool _isInitializing = true;
  String _callStatus = 'Connecting...';
  String? _currentUserId;
  bool _isDisposed = false;
  bool _channelJoined = false;

  Timer? _callTimer;
  int _callDurationSeconds = 0;
  String _callDuration = '00:00';
  Timer? _unansweredTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _loadCurrentUserIdAndInitialize();
  }

  Future<void> _loadCurrentUserIdAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id');

      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        await _initializeCall();
      } else {
        final profileResult = await ApiService.getUserProfile();
        if (profileResult['success'] == true) {
          _currentUserId = profileResult['data']['_id']?.toString();
          if (_currentUserId != null)
            await prefs.setString('user_id', _currentUserId!);
          await _initializeCall();
        } else {
          throw Exception('Failed to load user profile');
        }
      }
    } catch (e) {
      if (mounted) _showError('Failed to initialize: $e');
    }
  }

  Future<void> _initializeCall() async {
    if (_isDisposed) return;
    try {
      setState(() => _callStatus = 'Setting up video...');

      await ActiveCallState.saveActiveCall(
        chatId: widget.chatId,
        userName: widget.userName,
        userAvatar: widget.userAvatar,
        otherUserId: widget.otherUserId,
        isInitiator: widget.isInitiator,
        callType: 'video',
      );

      await _agoraService.initialize();
      _agoraService.onUserJoined = (uid, elapsed) {
        if (mounted) {
          setState(() {
            _remoteUid = uid;
            _isCallConnected = true;
            _callStatus = 'Connected';
          });
          _startCallTimer();
        }
      };
      _agoraService.onUserOffline = (uid, reason) {
        if (mounted)
          setState(() {
            _remoteUid = null;
            _callStatus = 'User Offline';
          });
      };

      if (_agoraService.remoteUids.isNotEmpty) {
        final existingUid = _agoraService.remoteUids.first;
        if (mounted) {
          setState(() {
            _remoteUid = existingUid;
            _isCallConnected = true;
            _callStatus = 'Connected';
          });
          _startCallTimer();
        }
      }

      if (_currentUserId != null && !SocketService.instance.isConnected) {
        await SocketService.instance.connect(_currentUserId!);
      }

      _setupSocketListeners();
      setState(() => _isInitializing = false);

      if (widget.isInitiator) {
        setState(() => _callStatus = 'Calling...');
        _unansweredTimer = Timer(const Duration(seconds: 30), () {
          if (mounted && !_isCallConnected) _showError('No answer');
        });
      } else {
        await _joinAgoraChannel();
      }
    } catch (e) {
      _showError('Failed to start call: $e');
    }
  }

  Future<void> _joinAgoraChannel() async {
    if (_channelJoined) return;
    _channelJoined = true;
    try {
      setState(() => _callStatus = 'Securing connection...');
      String? token = CallKitService.consumeCachedAgoraToken();

      if (token == null) {
        for (int attempt = 0; attempt < 2; attempt++) {
          try {
            final result =
                await ApiService.getAgoraToken(channelName: widget.chatId)
                    .timeout(const Duration(seconds: 8));
            token =
                (result['success'] == true) ? result['data']['token'] : null;
            if (token != null) break;
          } catch (e) {
            if (attempt == 0)
              await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      if (token == null) {
        _showError('Connection security failed');
        return;
      }

      if (_currentUserId != null) {
        await _agoraService.joinChannelWithUserAccount(
            channelName: widget.chatId,
            userAccount: _currentUserId!,
            isVideo: true,
            token: token);
      } else {
        await _agoraService.joinChannel(
            channelName: widget.chatId, uid: 0, isVideo: true, token: token);
      }

      if (mounted) {
        setState(() {
          _callStatus = 'Connected';
          _isCallConnected = true;
        });
        _startCallTimer();
      }
    } catch (e) {
      if (mounted) _showError('Failed to connect to call');
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket == null) return;

    socket.off('call:accepted');
    socket.off('call:accept');
    socket.off('call:ended');
    socket.off('call:rejected');

    void handleCallAccepted(dynamic data) async {
      if (data['chatId'] == widget.chatId && !_channelJoined) {
        _unansweredTimer?.cancel();
        _unansweredTimer = null;
        setState(() => _callStatus = 'Connecting...');
        await _joinAgoraChannel();
      }
    }

    socket.on('call:accepted', handleCallAccepted);
    socket.on('call:accept', handleCallAccepted);
    socket.on('call:ended', (data) {
      if (data['chatId'] == widget.chatId) _endCall();
    });
    socket.on('call:rejected', (data) {
      if (data['chatId'] == widget.chatId && mounted) {
        _showError('Call declined');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _endCall();
        });
      }
    });
  }

  void _startCallTimer() {
    if (_callTimer != null && _callTimer!.isActive) return;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
          final m = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
          final s = (_callDurationSeconds % 60).toString().padLeft(2, '0');
          _callDuration = '$m:$s';
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _agoraService.toggleAudio(_isMuted);
  }

  void _toggleVideo() {
    setState(() => _isVideoOff = !_isVideoOff);
    _agoraService.toggleVideo(_isVideoOff);
  }

  void _switchCamera() {
    _agoraService.switchCamera();
  }

  void _endCall() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _callTimer?.cancel();
    await ActiveCallState.clearActiveCall();

    try {
      if (widget.otherUserId.isNotEmpty && widget.isInitiator) {
        await AgoraChatService.instance.sendCallLog(
          conversationId: widget.otherUserId,
          callType: 'video',
          status: _isCallConnected ? 'ended' : 'cancelled',
          duration: _isCallConnected ? _callDuration : '',
          backendChatId: widget.chatId,
          uuid: widget.uuid,
        );
      }
    } catch (e) {
      debugPrint('Failed to send call log: $e');
    }

    try {
      await ApiService.endCall(
          chatId: widget.chatId,
          toUserId: widget.otherUserId,
          uuid: widget.uuid);
    } catch (e) {
      SocketService.instance.emit('call:end', {
        'chatId': widget.chatId,
        'toUserId': widget.otherUserId,
        'fromUserId': _currentUserId,
        'uuid': widget.uuid
      });
    }

    await _agoraService.leaveChannel();
    if (mounted) Navigator.pop(context);
  }

  void _showError(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _callTimer?.cancel();
    _unansweredTimer?.cancel();
    if (!_isDisposed) {
      _isDisposed = true;
      ActiveCallState.clearActiveCall();
      _agoraService.leaveChannel();
      SocketService.instance.emit('call:end', {
        'chatId': widget.chatId,
        'toUserId': widget.otherUserId,
        'fromUserId': _currentUserId,
        'uuid': widget.uuid
      });
    }
    _agoraService.onUserJoined = null;
    _agoraService.onUserOffline = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          // Remote video
          if (_remoteUid != null)
            Positioned.fill(
              child: AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _agoraService.engine!,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.chatId),
                ),
              ),
            )
          else
            Container(
              color: colors.heading,
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white24,
                        backgroundImage: widget.userAvatar != null &&
                                widget.userAvatar!.isNotEmpty
                            ? NetworkImage(widget.userAvatar!)
                            : null,
                        child: widget.userAvatar == null
                            ? const Icon(Icons.person,
                                color: Colors.white70, size: 60)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Text(widget.userName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(_callStatus,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16)),
                      if (_isInitializing ||
                          _callStatus == 'Calling...' ||
                          _callStatus == 'Connecting...')
                        const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child:
                                CircularProgressIndicator(color: Colors.white)),
                    ]),
              ),
            ),

          // Local video (PIP)
          if (!_isVideoOff && _agoraService.engine != null)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                        rtcEngine: _agoraService.engine!,
                        canvas: const VideoCanvas(uid: 0)),
                  ),
                ),
              ),
            ),

          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBtn(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          _isMuted ? 'Unmute' : 'Mute',
                          _toggleMute,
                          _isMuted ? Colors.red : Colors.white),
                      _buildBtn(
                          _isVideoOff ? Icons.videocam_off : Icons.videocam,
                          _isVideoOff ? 'Cam Off' : 'Cam On',
                          _toggleVideo,
                          _isVideoOff ? Colors.red : Colors.white),
                      _buildBtn(Icons.cameraswitch, 'Switch', _switchCamera,
                          Colors.white),
                      _buildEndBtn(),
                    ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildBtn(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28))),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ]);
  }

  Widget _buildEndBtn() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
          onTap: _endCall,
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child:
                  const Icon(Icons.call_end, color: Colors.white, size: 28))),
      const SizedBox(height: 8),
      const Text('End', style: TextStyle(color: Colors.white, fontSize: 12)),
    ]);
  }
}
