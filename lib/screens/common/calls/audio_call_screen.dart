import 'dart:async';
import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../services/active_call_state.dart';
import '../../../services/agora_service.dart';
import '../../../services/api_service.dart';
import '../../../services/callkit_service.dart';
import '../../../services/socket_service.dart';

class AudioCallScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String otherUserId;
  final bool isInitiator;
  final String? uuid;
  final Duration unansweredTimeout;

  const AudioCallScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.userAvatar,
    required this.otherUserId,
    required this.isInitiator,
    this.uuid,
    this.unansweredTimeout = const Duration(seconds: 30),
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final AgoraService _agoraService = AgoraService.instance;

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callConnected = false;
  String _callStatus = 'Connecting...';
  String? _currentUserId;
  bool _isDisposed = false;
  bool _channelJoined = false;

  Timer? _timer;
  int _callDuration = 0;
  Timer? _unansweredTimer;
  Function(dynamic)? _callAcceptedHandler;
  Function(dynamic)? _callEndedHandler;
  Function(dynamic)? _callRejectedHandler;

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
          if (_currentUserId != null) {
            await prefs.setString('user_id', _currentUserId!);
          }
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
      setState(() => _callStatus = 'Setting up audio...');

      if (_currentUserId != null && !SocketService.instance.isConnected) {
        await SocketService.instance.connect(_currentUserId!);
      }

      await ActiveCallState.saveActiveCall(
        chatId: widget.chatId,
        userName: widget.userName,
        userAvatar: widget.userAvatar,
        otherUserId: widget.otherUserId,
        isInitiator: widget.isInitiator,
        callType: 'audio',
      );

      await _agoraService.initialize();
      _agoraService.onUserJoined = (uid, elapsed) {
        if (mounted) {
          setState(() {
            _callConnected = true;
            _callStatus = 'Connected';
          });
          _startTimer();
        }
      };
      _agoraService.onUserOffline = (uid, reason) {
        if (mounted) _endCall();
      };

      _setupSocketListeners();

      if (widget.isInitiator) {
        setState(() => _callStatus = 'Calling...');
        _unansweredTimer = Timer(widget.unansweredTimeout, () {
          if (mounted && !_callConnected) {
            _showNoAnswerAndEnd();
          }
        });
      } else {
        await _joinAgoraChannel();
      }
    } catch (e) {
      _showError('Error: $e');
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
            final result = await ApiService.getAgoraToken(
              channelName: widget.chatId,
              account: _currentUserId,
            ).timeout(const Duration(seconds: 8));
            token =
                (result['success'] == true) ? result['data']['token'] : null;
            if (token != null) break;
          } catch (e) {
            debugPrint('Token fetch attempt ${attempt + 1} failed: $e');
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
          isVideo: false,
          token: token,
        );
      } else {
        await _agoraService.joinChannel(
            channelName: widget.chatId, uid: 0, isVideo: false, token: token);
      }

      if (mounted) {
        setState(() {
          _callStatus = 'Connected';
          _callConnected = true;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) _showError('Failed to connect: $e');
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket == null) return;

    _removeSocketListeners();

    void handleCallAccepted(dynamic data) async {
      if (data['chatId'] == widget.chatId && !_channelJoined) {
        _unansweredTimer?.cancel();
        _unansweredTimer = null;
        setState(() => _callStatus = 'Connecting...');
        await _joinAgoraChannel();
      }
    }
    _callAcceptedHandler = handleCallAccepted;
    _callEndedHandler = (data) {
      if (data['chatId'] == widget.chatId) _endCall();
    };
    _callRejectedHandler = (data) {
      if (data['chatId'] == widget.chatId && mounted) {
        _showError('Call declined');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _endCall();
        });
      }
    };

    socket.on('call:accepted', _callAcceptedHandler!);
    socket.on('call:accept', _callAcceptedHandler!);
    socket.on('call:ended', _callEndedHandler!);
    socket.on('call:rejected', _callRejectedHandler!);
  }

  void _removeSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket == null) return;
    if (_callAcceptedHandler != null) {
      socket.off('call:accepted', _callAcceptedHandler);
      socket.off('call:accept', _callAcceptedHandler);
    }
    if (_callEndedHandler != null) {
      socket.off('call:ended', _callEndedHandler);
    }
    if (_callRejectedHandler != null) {
      socket.off('call:rejected', _callRejectedHandler);
    }
    _callAcceptedHandler = null;
    _callEndedHandler = null;
    _callRejectedHandler = null;
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted)
        setState(() => _callDuration++);
      else
        timer.cancel();
    });
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _agoraService.toggleAudio(_isMuted);
  }

  void _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await _agoraService.engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  void _endCall({bool isMissedCall = false}) async {
    if (_isDisposed) return;
    _isDisposed = true;
    _timer?.cancel();
    _unansweredTimer?.cancel();

    await ActiveCallState.clearActiveCall();

    try {
      await ApiService.endCall(
          chatId: widget.chatId,
          toUserId: widget.otherUserId,
          uuid: widget.uuid,
          isMissedCall: isMissedCall);
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

  void _showNoAnswerAndEnd() {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No answer'), backgroundColor: Colors.red),
    );
    setState(() => _callStatus = 'No answer');
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_isDisposed) _endCall(isMissedCall: true);
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _unansweredTimer?.cancel();
    _timer?.cancel();
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
    _removeSocketListeners();
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
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.callDark, colors.callAccent])),
          child: SafeArea(
            child: Column(children: [
              const SizedBox(height: 60),
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white24,
                backgroundImage: widget.userAvatar != null
                    ? NetworkImage(widget.userAvatar!)
                    : null,
                child: widget.userAvatar == null
                    ? const Icon(Icons.person, color: Colors.white70, size: 80)
                    : null,
              ),
              const SizedBox(height: 30),
              Text(widget.userName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                  _callConnected ? _formatDuration(_callDuration) : _callStatus,
                  style: TextStyle(
                      color:
                          _callConnected ? Colors.greenAccent : Colors.white70,
                      fontSize: 18)),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBtn(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          _isMuted ? 'Unmute' : 'Mute',
                          _toggleMute,
                          _isMuted
                              ? Colors.red
                              : Colors.white.withValues(alpha: 0.3)),
                      _buildBtn(
                          _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          'Speaker',
                          _toggleSpeaker,
                          _isSpeakerOn
                              ? Colors.blue
                              : Colors.white.withValues(alpha: 0.3)),
                    ]),
              ),
              const SizedBox(height: 40),
              IconButton(
                iconSize: 60,
                icon: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.red),
                    child: const Icon(Icons.call_end, color: Colors.white)),
                onPressed: _endCall,
              ),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(IconData icon, String label, VoidCallback onTap, Color bg) {
    return Column(children: [
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28))),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ]);
  }
}
