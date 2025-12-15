import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    // Request permission cho Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Channel for default notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> showLeaveRequest({
    required String employeeName,
    required String leaveType,
  }) async {
    await show(
      title: 'Yêu cầu nghỉ phép mới',
      body: '$employeeName đã gửi yêu cầu nghỉ $leaveType',
    );
  }

  static Future<void> showLeaveApproved({required String leaveType}) async {
    await show(
      title: 'Yêu cầu nghỉ phép đã được duyệt',
      body: 'Yêu cầu nghỉ $leaveType của bạn đã được admin chấp nhận',
    );
  }

  static Future<void> showLeaveRejected({
    required String leaveType,
    String? reason,
  }) async {
    await show(
      title: 'Yêu cầu nghỉ phép bị từ chối',
      body:
          'Yêu cầu nghỉ $leaveType của bạn đã bị từ chối${reason != null ? ': $reason' : ''}',
    );
  }
}
