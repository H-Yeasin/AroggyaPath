import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/appointment_message_model.dart';
import '../../services/appointment_message_service.dart';
import '../../services/socket_service.dart';
import '../common/calls/audio_call_screen.dart';
import '../common/calls/video_call_screen.dart';
import '../../services/api_service.dart';

class AppointmentChatScreen extends StatefulWidget {
  final String appointmentId;
  final String title;
  final String receiverId;
  final String? receiverAvatar;
  final String userRole;

  const AppointmentChatScreen({
    super.key,
    required this.appointmentId,
    required this.title,
    required this.receiverId,
    required this.userRole,
    this.receiverAvatar,
  });

  @override
  State<AppointmentChatScreen> createState() => _AppointmentChatScreenState();
}

class _AppointmentChatScreenState extends State<AppointmentChatScreen> {
  final _messageService = AppointmentMessageService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<AppointmentMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');

    if (_currentUserId != null) {
      await SocketService.instance.connect(_currentUserId!);
      await SocketService.instance.emit('appointment_chat:join', {
        'appointmentId': widget.appointmentId,
      });
    }

    SocketService.instance.off('appointment_message:new');
    SocketService.instance.on('appointment_message:new', (payload) {
      final incomingAppointmentId = payload is Map
          ? payload['appointmentId']?.toString()
          : null;
      if (incomingAppointmentId == widget.appointmentId) {
        _loadMessages(showSpinner: false);
      }
    });

    await _loadMessages();
  }

  Future<void> _loadMessages({bool showSpinner = true}) async {
    if (showSpinner && mounted) setState(() => _isLoading = true);

    final response = await _messageService.getMessages(widget.appointmentId);
    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _messages =
            (response['messages'] as List<AppointmentMessageModel>? ?? []);
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response['message'] ?? 'Could not load messages')),
    );
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final response = await _messageService.sendMessage(
      appointmentId: widget.appointmentId,
      content: content,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (response['success'] == true) {
      _controller.clear();
      await _loadMessages(showSpinner: false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response['message'] ?? 'Could not send message')),
    );
  }

  Future<void> _startCall(bool isVideo) async {
    if (_isSending) return;
    setState(() => _isSending = true);

    final response = await ApiService.initiateCall(
      chatId: widget.appointmentId,
      receiverId: widget.receiverId,
      isVideo: isVideo,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final isReceiverOnline = data['isReceiverOnline'] as bool? ?? false;
      final uuid = data['uuid'] as String?;

      if (!isReceiverOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient is offline. Ringing via push notification...'),
            duration: Duration(seconds: 4),
          ),
        );
      }

      if (isVideo) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              chatId: widget.appointmentId,
              isInitiator: true,
              userName: widget.title,
              userAvatar: widget.receiverAvatar,
              otherUserId: widget.receiverId,
              uuid: uuid,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioCallScreen(
              chatId: widget.appointmentId,
              isInitiator: true,
              userName: widget.title,
              userAvatar: widget.receiverAvatar,
              otherUserId: widget.receiverId,
              uuid: uuid,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Could not start call')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    SocketService.instance.emit('appointment_chat:leave', {
      'appointmentId': widget.appointmentId,
    });
    SocketService.instance.off('appointment_message:new');
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primaryDark),
        title: Text(
          widget.title,
          style: TextStyle(color: colors.heading, fontWeight: FontWeight.bold),
        ),
        actions: widget.userRole == 'doctor'
            ? [
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => _startCall(false),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: () => _startCall(true),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == _currentUserId;
                          return _MessageBubble(message: message, isMe: isMe);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        filled: true,
                        fillColor: colors.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AppointmentMessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? colors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: isMe ? null : const Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe && (message.senderName?.isNotEmpty ?? false)) ...[
              Text(
                message.senderName!,
                style: TextStyle(
                  color: colors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.content,
              style: TextStyle(color: isMe ? Colors.white : colors.heading),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                time,
                style: TextStyle(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.75)
                      : Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
