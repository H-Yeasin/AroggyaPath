import '../core/utils/api_config.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  Future<List<AppNotificationModel>> getNotifications() async {
    final response = await ApiService.get(ApiConfig.notifications);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Could not load notifications');
    }

    final rawList = _extractList(response);
    return rawList
        .whereType<Map>()
        .map((item) => AppNotificationModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await ApiService.get(ApiConfig.unreadCount);
    if (response['success'] != true) return 0;

    final value = response['count'] ??
        response['unreadCount'] ??
        response['data']?['count'] ??
        response['data']?['unreadCount'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.isEmpty) return;
    await ApiService.patch(ApiConfig.getMarkAsReadUrl(notificationId), {});
  }

  Future<void> markAllAsRead() async {
    await ApiService.patch(ApiConfig.markAllAsRead, {});
  }

  List<dynamic> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) return data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final candidates = [
        map['notifications'],
        map['notification'],
        map['items'],
        map['docs'],
        map['results'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) return candidate;
      }
    }

    final candidates = [
      response['notifications'],
      response['notification'],
      response['items'],
      response['docs'],
      response['results'],
    ];
    for (final candidate in candidates) {
      if (candidate is List) return candidate;
    }

    return const [];
  }
}
