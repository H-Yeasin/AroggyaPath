class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    final id = (json['_id'] ?? json['id'] ?? json['notificationId'] ?? '')
        .toString();
    final title = (json['title'] ??
            data['title'] ??
            _titleForType((json['type'] ?? data['type'] ?? '').toString()))
        .toString();
    final body =
        (json['body'] ?? json['message'] ?? data['body'] ?? data['message'] ?? '')
            .toString();
    final type = (json['type'] ?? data['type'] ?? '').toString();
    final readValue = json['isRead'] ?? json['read'] ?? json['seen'] ?? false;

    return AppNotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: readValue == true || readValue.toString().toLowerCase() == 'true',
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
      data: {
        ...data,
        if (id.isNotEmpty) 'notificationId': id,
        if (type.isNotEmpty) 'type': type,
      },
    );
  }

  static String _titleForType(String type) {
    switch (type) {
      case 'appointment_created':
        return 'New appointment';
      case 'appointment_accepted':
        return 'Appointment accepted';
      case 'appointment_cancelled':
        return 'Appointment cancelled';
      case 'call_incoming':
        return 'Incoming call';
      case 'call_missed':
        return 'Missed call';
      case 'chat_message':
        return 'New message';
      default:
        return 'Notification';
    }
  }
}
