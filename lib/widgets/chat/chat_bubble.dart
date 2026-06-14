import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool isSelected;
  final String? currentUserAvatar;
  final String? otherUserAvatar;
  final String otherUserPlaceholder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isSelected,
    this.currentUserAvatar,
    this.otherUserAvatar,
    this.otherUserPlaceholder = 'assets/images/doctor_booking.png',
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final String text = message['content']?.toString() ?? '';
    final List<dynamic> attachments = message['fileUrl'] ?? [];
    final time = message['createdAt']?.toString() ?? '';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) _buildAvatar(otherUserAvatar, otherUserPlaceholder),
                if (!isMe) const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isMe ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(22),
                        topRight: const Radius.circular(22),
                        bottomLeft: Radius.circular(isMe ? 22 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: isMe ? 0.1 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (attachments.isNotEmpty)
                          ...attachments.map((att) {
                            final String? url = att['url']?.toString();
                            if (url != null && url.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: url.startsWith('http')
                                        ? CachedNetworkImage(
                                            imageUrl: url, fit: BoxFit.cover)
                                        : Image.file(File(url),
                                            fit: BoxFit.cover),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        if (text.isNotEmpty && text.trim().isNotEmpty)
                          Text(
                            text,
                            style: TextStyle(
                              color:
                                  isMe ? Colors.white : const Color(0xFF1B2C49),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isMe) const SizedBox(width: 8),
                if (isMe)
                  _buildAvatar(currentUserAvatar, 'assets/images/profile.png'),
              ],
            ),
            if (time.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 54,
                  right: isMe ? 54 : 0,
                  top: 6,
                ),
                child: Text(time,
                    style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, String placeholder) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipOval(
        child: SizedBox(
          width: 36,
          height: 36,
          child: url != null && url.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Image.asset(placeholder, fit: BoxFit.cover))
              : Image.asset(placeholder, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
