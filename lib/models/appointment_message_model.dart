class AppointmentMessageModel {
  final String id;
  final String appointmentId;
  final String senderId;
  final String? senderName;
  final String? senderRole;
  final String content;
  final DateTime createdAt;

  AppointmentMessageModel({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    this.senderName,
    this.senderRole,
    required this.content,
    required this.createdAt,
  });

  factory AppointmentMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    String senderId = '';
    String? senderName;
    String? senderRole;

    if (sender is Map<String, dynamic>) {
      senderId = sender['_id']?.toString() ?? sender['id']?.toString() ?? '';
      senderName = sender['fullName']?.toString();
      senderRole = sender['role']?.toString();
    } else if (sender != null) {
      senderId = sender.toString();
    }

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      );
    } catch (_) {
      createdAt = DateTime.now();
    }

    return AppointmentMessageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      appointmentId: json['appointment'] is Map
          ? json['appointment']['_id']?.toString() ?? ''
          : json['appointment']?.toString() ?? '',
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      content: json['content']?.toString() ?? '',
      createdAt: createdAt,
    );
  }
}
