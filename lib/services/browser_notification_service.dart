import 'dart:html' as html;

/// Service để hiển thị browser notifications (Windows/OS notifications)
/// Không cần FCM, chỉ dùng Web Notifications API
/// CHỈ DÙNG CHO WEB
class BrowserNotificationService {
  static bool _permissionRequested = false;

  /// Xin quyền hiển thị notifications
  static Future<bool> requestPermission() async {
    if (_permissionRequested) {
      return html.Notification.permission == 'granted';
    }

    _permissionRequested = true;

    try {
      final permission = await html.Notification.requestPermission();
      print('🔔 Browser notification permission: $permission');
      return permission == 'granted';
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Kiểm tra quyền hiện tại
  static Future<bool> isPermissionGranted() async {
    return html.Notification.permission == 'granted';
  }

  /// Hiển thị browser notification
  static Future<void> show({
    required String title,
    required String body,
    String? icon,
  }) async {
    if (html.Notification.permission != 'granted') {
      print('⚠️ Cannot show notification: Permission not granted');
      return;
    }

    try {
      final notification = html.Notification(
        title,
        body: body,
        icon: icon ?? '/icons/Icon-192.png',
      );

      // Auto close sau 5 giây
      Future.delayed(const Duration(seconds: 5), () {
        notification.close();
      });

      print('✅ Browser notification shown: $title');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  /// Hiển thị notification khi có đơn xin nghỉ mới
  static Future<void> showLeaveRequest({
    required String employeeName,
    required String leaveType,
  }) async {
    await show(
      title: '🔔 Đơn xin nghỉ mới',
      body: '$employeeName đã gửi đơn xin nghỉ $leaveType',
    );
  }

  /// Hiển thị notification khi đơn được duyệt
  static Future<void> showLeaveApproved({required String leaveType}) async {
    await show(
      title: '✅ Đơn nghỉ đã được duyệt',
      body: 'Đơn xin nghỉ $leaveType đã được phê duyệt',
    );
  }

  /// Hiển thị notification khi đơn bị từ chối
  static Future<void> showLeaveRejected({
    required String leaveType,
    String? reason,
  }) async {
    await show(
      title: '❌ Đơn nghỉ bị từ chối',
      body:
          'Đơn xin nghỉ $leaveType đã bị từ chối${reason != null ? ': $reason' : ''}',
    );
  }
}
