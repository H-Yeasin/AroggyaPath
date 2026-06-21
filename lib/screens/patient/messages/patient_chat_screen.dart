import 'dart:async';
import 'dart:io';

import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/agora_chat_service.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';
import '../../common/calls/audio_call_screen.dart';
import '../../common/calls/video_call_screen.dart';
import '../../../widgets/chat/chat_app_bar.dart';
import '../../../widgets/chat/chat_bubble.dart';
import '../../../widgets/chat/chat_input.dart';
import 'utils/patient_message_time_formatter.dart';
import 'widgets/call_log_placeholder.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String doctorName;
  final String? doctorAvatar;
  final String? doctorId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.doctorName,
    this.doctorAvatar,
    this.doctorId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  List<File> _selectedFiles = [];
  String? _currentUserId;
  String? _currentUserAvatar;

  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile().then((_) {
      _setupAgoraListener();
      _loadMessages();
      _ensureAgoraConnection();
      if (widget.doctorId != null) {
        AgoraChatService.instance.markAllMessagesAsRead(widget.chatId);
        ApiService.markChatAsRead(chatId: widget.chatId);
      }
    });
  }

  Future<void> _loadCurrentUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');
    _currentUserAvatar = prefs.getString('user_avatar');
  }

  void _setupAgoraListener() {
    AgoraChatService.instance.addMessageListener(
      'chat_detail_${widget.chatId}',
      ChatEventHandler(
        onMessagesReceived: (messages) {
          debugPrint('New message received');
          _loadMessages();
        },
      ),
    );
  }

  Future<void> _ensureAgoraConnection() async {
    if (!AgoraChatService.instance.isConnected) {
      await AgoraChatService.instance.init();
    }
    try {
      final isLoggedIn = await ChatClient.getInstance.isLoginBefore();
      if (!isLoggedIn && _currentUserId != null) {
        await AgoraChatService.instance.login(_currentUserId!);
      }
    } catch (e) {
      debugPrint('Agora connection error: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await AgoraChatService.instance.fetchHistoryMessages(
        conversationId: widget.chatId,
        pageSize: 100,
      );
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Load messages error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedFiles.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await AgoraChatService.instance.sendMessage(
        conversationId: widget.chatId,
        content: text,
        files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        backendChatId: widget.chatId,
      );

      _controller.clear();
      setState(() => _selectedFiles.clear());

      await _loadMessages();
    } catch (e) {
      debugPrint('Send message error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedFiles.add(File(picked.path)));
    }
  }

  void _toggleSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedMessageIds.add(messageId);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    await AgoraChatService.instance.deleteMessages(
      conversationId: widget.chatId,
      messageIds: _selectedMessageIds.toList(),
    );
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
    _loadMessages();
  }

  Future<void> _initiateCall(bool isVideo) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_full_name') ?? 'User';
    final userId = prefs.getString('user_id') ?? '';
    final avatar = prefs.getString('user_avatar');

    if (widget.doctorId == null) return;

    final result = await ApiService.initiateCall(
      chatId: widget.chatId,
      receiverId: widget.doctorId!,
      isVideo: isVideo,
    );

    if (result['success'] != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Could not start call'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uuid = result['data']?['uuid']?.toString();

    await SocketService.instance.emit('call:request', {
      'toUserId': widget.doctorId,
      'chatId': widget.chatId,
      'fromUserId': userId,
      'fromUserName': userName,
      'fromUserAvatar': avatar,
      'isVideo': isVideo,
      'uuid': uuid,
    });

    // Navigate to call screen
    if (isVideo) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => _buildCallScreen(
                  isVideo: true,
                  userName: widget.doctorName,
                  otherUserId: widget.doctorId!,
                  avatar: widget.doctorAvatar,
                  uuid: uuid)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => _buildCallScreen(
                  isVideo: false,
                  userName: widget.doctorName,
                  otherUserId: widget.doctorId!,
                  avatar: widget.doctorAvatar,
                  uuid: uuid)));
    }
  }

  Widget _buildCallScreen({
    required bool isVideo,
    required String userName,
    required String otherUserId,
    String? avatar,
    String? uuid,
  }) {
    if (isVideo) {
      return VideoCallScreen(
        chatId: widget.chatId,
        userName: userName,
        userAvatar: avatar,
        otherUserId: otherUserId,
        isInitiator: true,
        uuid: uuid,
      );
    }

    return AudioCallScreen(
      chatId: widget.chatId,
      userName: userName,
      userAvatar: avatar,
      otherUserId: otherUserId,
      isInitiator: true,
      uuid: uuid,
    );
  }

  @override
  void dispose() {
    AgoraChatService.instance
        .removeMessageListener('chat_detail_${widget.chatId}');
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: colors.surfaceAlt,
      appBar: ChatAppBar(
        userName: widget.doctorName,
        userAvatar: widget.doctorAvatar,
        isSelectionMode: _isSelectionMode,
        selectedCount: _selectedMessageIds.length,
        onCancelSelection: () => setState(() {
          _isSelectionMode = false;
          _selectedMessageIds.clear();
        }),
        onDeleteSelected: _deleteSelected,
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: colors.success),
            onPressed: () => _initiateCall(false),
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: colors.primary),
            onPressed: () => _initiateCall(true),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg.from == _currentUserId;
                    final isSelected = _selectedMessageIds.contains(msg.msgId);
                    final isCallLog = msg.body.toString().contains('call:');

                    if (isCallLog) {
                      return CallLogPlaceholder(
                          isMe: isMe, text: msg.body.toString());
                    }

                    return ChatBubble(
                      message: {
                        'content': msg.body.toString(),
                        'createdAt': formatChatMessageTime(
                            DateTime.fromMillisecondsSinceEpoch(
                                msg.serverTime)),
                        'fileUrl': [],
                      },
                      isMe: isMe,
                      isSelected: isSelected,
                      currentUserAvatar: _currentUserAvatar,
                      otherUserAvatar: widget.doctorAvatar,
                      onTap: _isSelectionMode
                          ? () => _toggleSelection(msg.msgId)
                          : null,
                      onLongPress: () => _toggleSelection(msg.msgId),
                    );
                  },
                ),
        ),
        ChatInput(
          controller: _controller,
          selectedFiles: _selectedFiles,
          isSending: _isSending,
          onPickImage: _pickImage,
          onRemoveFile: (index) =>
              setState(() => _selectedFiles.removeAt(index)),
          onSendMessage: _sendMessage,
          onChanged: (_) {},
        ),
      ]),
    );
  }

}
