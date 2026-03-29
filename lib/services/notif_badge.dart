import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service that tracks the notification badge count
/// and which notifications have been dismissed by the user.
class NotifBadgeService {
  NotifBadgeService._();

  static final ValueNotifier<int> count = ValueNotifier(0);
  static Set<String> _dismissed = {};

  /// Load dismissed IDs and last-known count from SharedPreferences.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _dismissed = Set.from(prefs.getStringList('dismissed_notifs') ?? []);
    count.value = prefs.getInt('notif_count') ?? 0;
  }

  static bool isDismissed(String id) => _dismissed.contains(id);

  /// Dismiss a single notification and persist.
  static Future<void> dismiss(String id) async {
    _dismissed.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dismissed_notifs', _dismissed.toList());
    if (count.value > 0) count.value = count.value - 1;
    await prefs.setInt('notif_count', count.value);
  }

  /// Dismiss all given IDs at once and reset count to 0.
  static Future<void> dismissAll(List<String> ids) async {
    _dismissed.addAll(ids);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dismissed_notifs', _dismissed.toList());
    count.value = 0;
    await prefs.setInt('notif_count', 0);
  }

  /// Set count (called after fresh load from Supabase).
  static Future<void> setCount(int n) async {
    count.value = n;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_count', n);
  }
}
