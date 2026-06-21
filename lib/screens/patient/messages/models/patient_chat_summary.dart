import '../utils/patient_last_message_preview.dart';

class PatientChatSummary {
  final String id;
  final String actualUserId;
  final String fullName;
  final String? avatarUrl;
  final String lastMessageContent;
  final int unreadCount;
  final DateTime? updatedAt;
  final bool hasMessages;

  const PatientChatSummary({
    required this.id,
    required this.actualUserId,
    required this.fullName,
    required this.avatarUrl,
    required this.lastMessageContent,
    required this.unreadCount,
    required this.updatedAt,
    required this.hasMessages,
  });

  factory PatientChatSummary.fromBackend({
    required dynamic rawChat,
    required String? currentUserId,
    required String counterpartFallbackName,
  }) {
    final chat = Map<String, dynamic>.from(rawChat as Map);
    final participants = chat['participants'] as List? ?? [];
    final otherUser = participants.firstWhere(
      (participant) =>
          participant is Map && participant['_id']?.toString() != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : {},
    );
    final other = otherUser is Map
        ? Map<String, dynamic>.from(otherUser)
        : <String, dynamic>{};
    final lastMessage = chat['lastMessage'];
    final lastMessageMap = lastMessage is Map
        ? Map<String, dynamic>.from(lastMessage)
        : <String, dynamic>{};
    final avatar = other['avatar'];
    final updatedAtText =
        lastMessageMap['createdAt']?.toString() ?? chat['updatedAt']?.toString();

    return PatientChatSummary(
      id: chat['_id']?.toString() ?? '',
      actualUserId: other['_id']?.toString() ?? '',
      fullName: other['fullName']?.toString() ?? counterpartFallbackName,
      avatarUrl: avatar is Map ? avatar['url']?.toString() : null,
      lastMessageContent: formatLastMessagePreview(lastMessageMap),
      unreadCount: int.tryParse(chat['unreadCount']?.toString() ?? '') ?? 0,
      updatedAt: DateTime.tryParse(updatedAtText ?? ''),
      hasMessages: lastMessageMap.isNotEmpty,
    );
  }

  bool get isDisplayable =>
      id.isNotEmpty && actualUserId.isNotEmpty && hasMessages;

  PatientChatSummary copyWith({
    int? unreadCount,
  }) {
    return PatientChatSummary(
      id: id,
      actualUserId: actualUserId,
      fullName: fullName,
      avatarUrl: avatarUrl,
      lastMessageContent: lastMessageContent,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt,
      hasMessages: hasMessages,
    );
  }
}
