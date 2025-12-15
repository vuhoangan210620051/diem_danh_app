import 'package:shared_preferences/shared_preferences.dart';

class NotificationStateService {
  static const String _adminReadKey = 'admin_read_notifications';
  static const String _employeeReadKeyPrefix = 'employee_read_notifications_';

  // Lấy danh sách notification IDs đã đọc cho admin
  static Future<Set<String>> getAdminReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_adminReadKey) ?? [];
    return list.toSet();
  }

  // Lưu notification ID đã đọc cho admin
  static Future<void> markAdminNotificationAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_adminReadKey) ?? [];
    if (!list.contains(notificationId)) {
      list.add(notificationId);
      await prefs.setStringList(_adminReadKey, list);
    }
  }

  // Đánh dấu tất cả notifications admin là đã đọc
  static Future<void> markAllAdminAsRead(List<String> notificationIds) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_adminReadKey) ?? [];
    final combined = {...existing, ...notificationIds}.toList();
    await prefs.setStringList(_adminReadKey, combined);
  }

  // Xóa tất cả admin notifications đã đọc
  static Future<void> clearAdminReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminReadKey);
  }

  // Lấy danh sách notification IDs đã đọc cho employee
  static Future<Set<String>> getEmployeeReadNotifications(
    String employeeId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_employeeReadKeyPrefix$employeeId';
    final list = prefs.getStringList(key) ?? [];
    return list.toSet();
  }

  // Lưu notification ID đã đọc cho employee
  static Future<void> markEmployeeNotificationAsRead(
    String employeeId,
    String notificationId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_employeeReadKeyPrefix$employeeId';
    final list = prefs.getStringList(key) ?? [];
    if (!list.contains(notificationId)) {
      list.add(notificationId);
      await prefs.setStringList(key, list);
    }
  }

  // Đánh dấu tất cả notifications employee là đã đọc
  static Future<void> markAllEmployeeAsRead(
    String employeeId,
    List<String> notificationIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_employeeReadKeyPrefix$employeeId';
    final existing = prefs.getStringList(key) ?? [];
    final combined = {...existing, ...notificationIds}.toList();
    await prefs.setStringList(key, combined);
  }

  // Xóa tất cả employee notifications đã đọc
  static Future<void> clearEmployeeReadNotifications(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_employeeReadKeyPrefix$employeeId';
    await prefs.remove(key);
  }

  // DELETED NOTIFICATIONS MANAGEMENT
  static const String _adminDeletedKey = 'admin_deleted_notifications';
  static const String _employeeDeletedKeyPrefix =
      'employee_deleted_notifications_';

  // Lấy danh sách notification IDs đã xóa cho admin
  static Future<Set<String>> getAdminDeletedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_adminDeletedKey) ?? [];
    return list.toSet();
  }

  // Đánh dấu notification đã xóa cho admin
  static Future<void> markAdminNotificationAsDeleted(
    String notificationId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_adminDeletedKey) ?? [];
    if (!list.contains(notificationId)) {
      list.add(notificationId);
      await prefs.setStringList(_adminDeletedKey, list);
    }
  }

  // Lấy danh sách notification IDs đã xóa cho employee
  static Future<Set<String>> getEmployeeDeletedNotifications(
    String employeeId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_employeeDeletedKeyPrefix$employeeId';
    final list = prefs.getStringList(key) ?? [];
    return list.toSet();
  }

  // Đánh dấu notification đã xóa cho employee
  static Future<void> markEmployeeNotificationAsDeleted(
    String employeeId,
    String notificationId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_employeeDeletedKeyPrefix$employeeId';
    final list = prefs.getStringList(key) ?? [];
    if (!list.contains(notificationId)) {
      list.add(notificationId);
      await prefs.setStringList(key, list);
    }
  }

  // LEAVE NOTIFICATION TIMESTAMPS
  static const String _leaveNotificationTimestampPrefix =
      'leave_notification_timestamp_';

  // Lưu timestamp cho leave notification lần đầu
  static Future<void> saveLeaveNotificationTimestamp(
    String employeeId,
    String notificationId,
    DateTime timestamp,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        '$_leaveNotificationTimestampPrefix${employeeId}_$notificationId';
    await prefs.setInt(key, timestamp.millisecondsSinceEpoch);
  }

  // Lấy timestamp của leave notification (nếu có)
  static Future<DateTime?> getLeaveNotificationTimestamp(
    String employeeId,
    String notificationId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        '$_leaveNotificationTimestampPrefix${employeeId}_$notificationId';
    final millis = prefs.getInt(key);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
