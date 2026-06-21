String formatLastMessagePreview(Map<String, dynamic> message) {
  final contentType = message['contentType']?.toString() ?? 'text';
  final content = message['content']?.toString().trim() ?? '';

  if (content.isNotEmpty) return content;
  if (contentType == 'image') return '[Image]';
  if (contentType == 'video') return '[Video]';
  if (contentType == 'audio') return '[Audio]';
  if (contentType == 'file') return '[File]';
  return 'No messages yet';
}
