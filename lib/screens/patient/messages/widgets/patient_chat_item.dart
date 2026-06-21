import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:arogya_path3/services/agora_chat_service.dart';
import 'package:arogya_path3/services/api_service.dart';
import 'package:flutter/material.dart';

import '../patient_chat_screen.dart';

class PatientChatItem extends StatefulWidget {
  final Map<String, dynamic> chat;
  final String counterpartFallbackName;
  final String roleBadge;
  final bool isSelected;
  final bool isSelectionMode;
  final Function(String) onToggleSelection;
  final VoidCallback onChatUpdated;

  const PatientChatItem({
    super.key,
    required this.chat,
    required this.counterpartFallbackName,
    required this.roleBadge,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onToggleSelection,
    required this.onChatUpdated,
  });

  @override
  State<PatientChatItem> createState() => _PatientChatItemState();
}

class _PatientChatItemState extends State<PatientChatItem> {
  late Map<String, dynamic> _chat;

  @override
  void initState() {
    super.initState();
    _chat = widget.chat;
  }

  @override
  void didUpdateWidget(covariant PatientChatItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat != widget.chat) {
      _chat = widget.chat;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final String chatUserName =
        _chat['fullName']?.toString() ?? widget.counterpartFallbackName;
    final String? chatUserAvatar = _chat['avatarUrl']?.toString();

    final lastMessage = _chat['lastMessage'];
    final String messageText = lastMessage != null
        ? (lastMessage['content']?.toString() ?? 'Start Conversation')
        : 'Start Conversation';

    //  Get unread count
    final int unreadCount = _chat['unreadCount'] ?? 0;

    final DateTime? updatedAt = _chat['updatedAt'] != null
        ? DateTime.tryParse(_chat['updatedAt'].toString())
        : null;
    final String timeText = updatedAt != null ? _formatTime(updatedAt) : '';

    final String convId = _chat['_id']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          if (widget.isSelectionMode) {
            widget.onToggleSelection(convId);
            return;
          }

          final String backendId = _chat['_id']?.toString() ?? '';
          final String actualUserId =
              _chat['actualUserId']?.toString() ?? backendId;

          debugPrint(
              ' [PATIENT] Opening chat: $backendId (User: $actualUserId)');
          debugPrint('• Current unread count: $unreadCount');

          //  Mark as read immediately (optimistic UI update)
          if (unreadCount > 0) {
            setState(() {
              _chat['unreadCount'] = 0;
            });
            debugPrint('• Optimistically set unread count to 0');

            // Mark all messages as read in both Agora and backend
            bool agoraSuccess = false;
            bool backendSuccess = false;

            try {
              // Agora SDK - MUST use UserID
              await AgoraChatService.instance
                  .markAllMessagesAsRead(actualUserId);
              agoraSuccess = true;
              debugPrint(
                  '• Marked conversation $actualUserId as read in Agora');
            } catch (e) {
              debugPrint('• Failed to mark as read in Agora: $e');
            }

            try {
              // Backend API - MUST use ChatID
              final result = await ApiService.markChatAsRead(chatId: backendId);
              backendSuccess = result['success'] == true;
              if (backendSuccess) {
                debugPrint(
                    ' Marked conversation $backendId as read in backend');
              } else {
                debugPrint(
                    ' Backend mark as read failed: ${result['message']}');
              }
            } catch (e) {
              debugPrint('Failed to mark as read in backend: $e');
            }

            // Show error feedback if both failed
            if (!agoraSuccess && !backendSuccess && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to mark as read'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }

          // Navigate to chat screen
          if (!mounted) return;
          debugPrint('• Navigating to chat screen...');
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                chatId: backendId,
                doctorName: chatUserName,
                doctorAvatar: chatUserAvatar,
                doctorId: actualUserId,
              ),
            ),
          ).then((_) {
            debugPrint('• Returned from chat screen, refreshing list...');
            //  Reload chats when returning to update unread counts
            widget.onChatUpdated();
          });
        },
        onLongPress: () => widget.onToggleSelection(convId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected ? Colors.blue[50] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: widget.isSelected
                ? Border.all(color: Colors.blue.shade300)
                : Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: chatUserAvatar != null &&
                        chatUserAvatar.isNotEmpty &&
                        chatUserAvatar != 'file:///' &&
                        (chatUserAvatar.startsWith('http://') ||
                            chatUserAvatar.startsWith('https://'))
                    ? Image.network(
                        chatUserAvatar,
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                          "assets/images/doctor1.png",
                          height: 56,
                          width: 56,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        "assets/images/doctor1.png",
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatUserName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.heading,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.roleBadge,
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    //  Added unread count display
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            messageText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? colors.heading
                                  : Colors.grey,
                              fontSize: 14,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        //  Unread badge
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.chatPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
