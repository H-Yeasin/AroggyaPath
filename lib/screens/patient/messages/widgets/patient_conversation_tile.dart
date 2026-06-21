import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';

import '../models/patient_chat_summary.dart';
import '../utils/patient_message_time_formatter.dart';

class PatientConversationTile extends StatelessWidget {
  final PatientChatSummary chat;
  final String roleBadge;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PatientConversationTile({
    super.key,
    required this.chat,
    required this.roleBadge,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final timeText =
        chat.updatedAt != null ? formatConversationTime(chat.updatedAt!) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
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
              _ConversationAvatar(avatarUrl: chat.avatarUrl),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.fullName,
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
                            roleBadge,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessageContent,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: chat.unreadCount > 0
                                  ? colors.heading
                                  : Colors.grey,
                              fontSize: 14,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (chat.unreadCount > 0)
                          _UnreadBadge(count: chat.unreadCount),
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

class _ConversationAvatar extends StatelessWidget {
  final String? avatarUrl;

  const _ConversationAvatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasRemoteAvatar = url != null &&
        url.isNotEmpty &&
        url != 'file:///' &&
        (url.startsWith('http://') || url.startsWith('https://'));

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: hasRemoteAvatar
          ? Image.network(
              url,
              height: 56,
              width: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _FallbackAvatarImage(),
            )
          : _FallbackAvatarImage(),
    );
  }
}

class _FallbackAvatarImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/doctor1.png',
      height: 56,
      width: 56,
      fit: BoxFit.cover,
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.chatPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
