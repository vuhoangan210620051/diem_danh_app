import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service để xử lý FCM (Firebase Cloud Messaging)
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Khởi tạo notification service (không request permission ngay)
  static Future<void> initialize() async {
    try {
      // Setup listeners trước
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  /// Request notification permission và lấy token (gọi sau khi login)
  static Future<void> requestPermissionAndGetToken() async {
    try {
      if (kDebugMode) {
        print('🔔 [NotificationService] Requesting notification permission...');
      }

      // ⚠️ WEB: Cần VAPID key từ Firebase Console
      if (kIsWeb) {
        const vapidKey = 'YOUR_VAPID_KEY_HERE';
        if (vapidKey == 'YOUR_VAPID_KEY_HERE') {
          if (kDebugMode) {
            print('⚠️ [NotificationService] VAPID key chưa được cấu hình!');
            print('📝 Hướng dẫn:');
            print('   1. Vào Firebase Console > Project Settings');
            print('   2. Tab Cloud Messaging > Web Push certificates');
            print('   3. Generate key pair và copy VAPID key');
            print(
              '   4. Thay "YOUR_VAPID_KEY_HERE" trong notification_service.dart',
            );
          }
          return; // Tạm thời skip notification cho web
        }
      }

      // Request permission (iOS & Web)
      if (kDebugMode) {
        print('🔔 [NotificationService] Calling requestPermission()...');
      }

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print(
          '🔔 [NotificationService] Permission status: ${settings.authorizationStatus}',
        );
      }

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) {
          print('❌ [NotificationService] User denied notification permission');
        }
        return;
      }

      // Lấy FCM token
      if (kDebugMode) {
        print('🔔 [NotificationService] Getting FCM token...');
      }

      _fcmToken = await _messaging.getToken(
        vapidKey: kIsWeb ? 'YOUR_VAPID_KEY_HERE' : null,
      );

      if (kDebugMode) {
        print('✅ [NotificationService] FCM Token: $_fcmToken');
      }

      // Listen khi token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          print('FCM Token refreshed: $newToken');
        }
        // TODO: Update token trong Firestore nếu cần
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Handle foreground message (khi app đang mở)
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // TODO: Show in-app notification hoặc dialog
    // Có thể dùng overlay_support package hoặc tự implement
  }

  /// Handle khi user tap vào notification
  static void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.data}');
    }

    // TODO: Navigate đến màn hình phù hợp dựa trên message.data
    // Ví dụ: if (message.data['type'] == 'leave_request') { navigate to leave tab }
  }

  /// Lưu FCM token vào employee record
  static Future<void> saveTokenToEmployee(String employeeId) async {
    if (_fcmToken == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .update({'fcmToken': _fcmToken});

      if (kDebugMode) {
        print('FCM token saved for employee: $employeeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  /// Xóa FCM token khi logout
  static Future<void> clearToken(String employeeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .update({'fcmToken': FieldValue.delete()});

      _fcmToken = null;

      if (kDebugMode) {
        print('FCM token cleared for employee: $employeeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing FCM token: $e');
      }
    }
  }

  /// Gửi notification đến một employee cụ thể (qua Cloud Function)
  static Future<void> sendNotificationToEmployee({
    required String employeeId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Trigger Cloud Function để gửi notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetEmployeeId': employeeId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (kDebugMode) {
        print('Notification queued for employee: $employeeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
    }
  }

  /// Gửi notification đến tất cả admin
  static Future<void> sendNotificationToAdmins({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Lấy tất cả admin
      final adminsSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('role', isEqualTo: 'admin')
          .get();

      // Queue notification cho từng admin
      for (final doc in adminsSnapshot.docs) {
        await sendNotificationToEmployee(
          employeeId: doc.id,
          title: title,
          body: body,
          data: data,
        );
      }

      if (kDebugMode) {
        print('Notifications queued for ${adminsSnapshot.docs.length} admins');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notifications to admins: $e');
      }
    }
  }
}

/// Background message handler (phải ở top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message: ${message.notification?.title}');
  }
}
