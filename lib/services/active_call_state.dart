import 'package:shared_preferences/shared_preferences.dart';

/// Persists active call data to SharedPreferences so that a call
/// can survive app restarts / background-foreground transitions.
class ActiveCallState {
  static const _key = 'active_call_data';

  static Future<void> saveActiveCall({
    required String chatId,
    required String userName,
    String? userAvatar,
    required String otherUserId,
    required bool isInitiator,
    required String callType, // 'audio' or 'video'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, '{"chatId":"$chatId","userName":"$userName","userAvatar":"${userAvatar ?? ''}","otherUserId":"$otherUserId","isInitiator":$isInitiator,"callType":"$callType"}');
  }

  static Future<Map<String, dynamic>?> getActiveCall() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(
          Uri.tryParse('?$raw')?.queryParametersAll.map((k, v) => MapEntry(k, v.first)) ?? {});
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearActiveCall() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
