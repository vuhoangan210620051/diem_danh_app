// Stub for non-web platforms
class BrowserNotificationService {
  static Future<bool> isPermissionGranted() async => false;
  static Future<void> requestPermission() async {}
  static Future<void> show({
    required String title,
    required String body,
    String? icon,
  }) async {}
  static Future<void> showLeaveRequest({
    required String employeeName,
    required String leaveType,
  }) async {}
  static Future<void> showLeaveApproved({required String leaveType}) async {}
  static Future<void> showLeaveRejected({
    required String leaveType,
    String? reason,
  }) async {}
}
