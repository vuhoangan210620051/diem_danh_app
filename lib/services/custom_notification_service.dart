import '../models/custom_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomNotificationService {
  static final _col = FirebaseFirestore.instance.collection(
    'custom_notifications',
  );

  // Lấy tất cả notifications (mới nhất trước)
  static Future<List<CustomNotification>> getNotifications() async {
    final snap = await _col.orderBy('timestamp', descending: true).get();
    return snap.docs.map((d) => CustomNotification.fromJson(d.data())).toList();
  }

  // Stream tất cả notifications (mới nhất trước)
  static Stream<List<CustomNotification>> streamNotifications() {
    return _col
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CustomNotification.fromJson(d.data()))
              .toList(),
        );
  }

  // Thêm notification mới
  static Future<void> addNotification(CustomNotification notification) async {
    await _col.doc(notification.id).set(notification.toJson());
  }

  // Xóa notification
  static Future<void> deleteNotification(String notificationId) async {
    await _col.doc(notificationId).delete();
  }

  // Lấy notifications cho một nhân viên cụ thể
  static Future<List<CustomNotification>> getNotificationsForEmployee(
    String employeeId,
    String employeeDept,
  ) async {
    final allNotifications = await getNotifications();
    return allNotifications
        .where((n) => n.isForEmployee(employeeId, employeeDept))
        .toList();
  }

  // Stream notifications cho một nhân viên cụ thể
  static Stream<List<CustomNotification>> streamNotificationsForEmployee(
    String employeeId,
    String employeeDept,
  ) {
    return streamNotifications().map(
      (list) =>
          list.where((n) => n.isForEmployee(employeeId, employeeDept)).toList(),
    );
  }
}
