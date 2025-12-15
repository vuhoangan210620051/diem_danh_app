import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../models/leave_record.dart';
import '../../models/custom_notification.dart';
import '../../services/notification_state_service.dart';
import '../../services/custom_notification_service.dart';
import 'package:intl/intl.dart';

enum NotificationFilter { all, unread }

enum EmployeeNotificationType { leaveApproved, leaveRejected, custom }

class EmployeeNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final EmployeeNotificationType type;
  bool isRead;

  EmployeeNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class EmployeeNotificationTab extends StatefulWidget {
  final Employee employee;
  final Function(int)? onUnreadCountChanged;
  final Function(VoidCallback)? onRefreshCallbackSet;

  const EmployeeNotificationTab({
    super.key,
    required this.employee,
    this.onUnreadCountChanged,
    this.onRefreshCallbackSet,
  });

  @override
  State<EmployeeNotificationTab> createState() =>
      _EmployeeNotificationTabState();
}

class _EmployeeNotificationTabState extends State<EmployeeNotificationTab>
    with AutomaticKeepAliveClientMixin {
  NotificationFilter _filter = NotificationFilter.all;
  final List<EmployeeNotificationItem> _notifications = [];
  Set<String> _readNotificationIds = {};
  Set<String> _deletedNotificationIds = {};
  StreamSubscription<List<CustomNotification>>? _customSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadReadState();
    // Lắng nghe realtime custom notifications cho nhân viên
    _customSub =
        CustomNotificationService.streamNotificationsForEmployee(
          widget.employee.id,
          widget.employee.dept,
        ).listen((_) {
          // Khi có thay đổi, reload để đồng bộ trạng thái đọc/xóa
          _loadReadState();
        });
    // Set callback để parent có thể trigger refresh
    widget.onRefreshCallbackSet?.call(_loadReadState);
  }

  @override
  void dispose() {
    _customSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(EmployeeNotificationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload notifications khi employee thay đổi (bao gồm leaveHistory)
    if (oldWidget.employee.id != widget.employee.id ||
        oldWidget.employee.dept != widget.employee.dept) {
      _customSub?.cancel();
      _customSub = CustomNotificationService.streamNotificationsForEmployee(
        widget.employee.id,
        widget.employee.dept,
      ).listen((_) => _loadReadState());
      _loadReadState();
    } else if (oldWidget.employee.leaveHistory.length !=
            widget.employee.leaveHistory.length ||
        _hasLeaveStatusChanged(oldWidget.employee, widget.employee)) {
      // Employee data changed (leave approved/rejected) → reload ngay
      _loadReadState();
    }
  }

  bool _hasLeaveStatusChanged(Employee old, Employee current) {
    if (old.leaveHistory.length != current.leaveHistory.length) return true;
    for (var i = 0; i < old.leaveHistory.length; i++) {
      if (old.leaveHistory[i].status != current.leaveHistory[i].status) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadReadState() async {
    _readNotificationIds =
        await NotificationStateService.getEmployeeReadNotifications(
          widget.employee.id,
        );
    _deletedNotificationIds =
        await NotificationStateService.getEmployeeDeletedNotifications(
          widget.employee.id,
        );
    await _loadNotifications();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadNotifications() async {
    try {
      _notifications.clear();
      final now = DateTime.now();

      // Tải custom notifications cho nhân viên này
      final customNotifications =
          await CustomNotificationService.getNotificationsForEmployee(
            widget.employee.id,
            widget.employee.dept,
          );
      for (final customNotif in customNotifications) {
        final notifId = 'custom_${customNotif.id}';
        // Bỏ qua các notification đã bị xóa
        if (_deletedNotificationIds.contains(notifId)) continue;

        _notifications.add(
          EmployeeNotificationItem(
            id: notifId,
            title: customNotif.title,
            message: customNotif.message,
            timestamp: customNotif.timestamp,
            type: EmployeeNotificationType.custom,
            isRead: _readNotificationIds.contains(notifId),
          ),
        );
      }

      // Không cần tạo notification từ leaveHistory nữa
      // Vì admin đã tạo CustomNotification thực sự vào Firestore khi duyệt/từ chối

      // Sắp xếp theo thời gian mới nhất
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _updateBadgeCount();
    } catch (e) {
      print('Error loading notifications: $e');
      // Đảm bảo badge vẫn update ngay cả khi có lỗi
      _updateBadgeCount();
    }
  }

  void _updateBadgeCount() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    widget.onUnreadCountChanged?.call(unreadCount);
  }

  List<EmployeeNotificationItem> get _filteredNotifications {
    if (_filter == NotificationFilter.unread) {
      return _notifications.where((n) => !n.isRead).toList();
    }
    return _notifications;
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _markAllAsRead() async {
    final notificationIds = _notifications.map((n) => n.id).toList();
    await NotificationStateService.markAllEmployeeAsRead(
      widget.employee.id,
      notificationIds,
    );
    _readNotificationIds.addAll(notificationIds);
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    setState(() {});
    _updateBadgeCount();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
    );
  }

  void _deleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tất cả thông báo'),
        content: const Text('Bạn có chắc muốn xóa tất cả thông báo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              _updateBadgeCount();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa tất cả thông báo')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(EmployeeNotificationItem notification) async {
    await NotificationStateService.markEmployeeNotificationAsRead(
      widget.employee.id,
      notification.id,
    );
    _readNotificationIds.add(notification.id);
    notification.isRead = true;
    setState(() {});
    _updateBadgeCount();
  }

  Future<void> _deleteNotification(
    EmployeeNotificationItem notification,
  ) async {
    // Đánh dấu notification đã bị xóa trong SharedPreferences
    await NotificationStateService.markEmployeeNotificationAsDeleted(
      widget.employee.id,
      notification.id,
    );
    _deletedNotificationIds.add(notification.id);

    // Nếu là custom notification thì cũng xóa khỏi storage
    if (notification.type == EmployeeNotificationType.custom &&
        notification.id.startsWith('custom_')) {
      final actualId = notification.id.substring(7); // Bỏ prefix 'custom_'
      await CustomNotificationService.deleteNotification(actualId);
    }

    setState(() {
      _notifications.remove(notification);
    });
    _updateBadgeCount();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa thông báo')));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text(
                'Thông báo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: const Color(0xFF2A3950),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _unreadCount > 0 ? _markAllAsRead : null,
              tooltip: 'Đánh dấu tất cả đã đọc',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _notifications.isNotEmpty ? _deleteAll : null,
              tooltip: 'Xóa tất cả',
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            tabs: [
              Tab(icon: Icon(Icons.notifications), text: 'Thông báo'),
              Tab(icon: Icon(Icons.history), text: 'Lịch sử'),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF5F7FA),
        body: TabBarView(
          children: [_buildNotificationList(), _buildHistoryList()],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    final filtered = _filteredNotifications;

    return Column(
      children: [
        // Filter buttons
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          setState(() => _filter = NotificationFilter.all),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _filter == NotificationFilter.all
                            ? const Color(0xFF2A3950)
                            : Colors.white,
                        foregroundColor: _filter == NotificationFilter.all
                            ? Colors.white
                            : Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _filter == NotificationFilter.all
                                ? const Color(0xFF2A3950)
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      child: Text('Tất cả (${_notifications.length})'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          setState(() => _filter = NotificationFilter.unread),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _filter == NotificationFilter.unread
                            ? const Color(0xFF2A3950)
                            : Colors.white,
                        foregroundColor: _filter == NotificationFilter.unread
                            ? Colors.white
                            : Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _filter == NotificationFilter.unread
                                ? const Color(0xFF2A3950)
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      child: Text('Chưa đọc ($_unreadCount)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Notifications list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filter == NotificationFilter.unread
                            ? 'Không có thông báo chưa đọc'
                            : 'Chưa có thông báo',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final notification = filtered[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    // Tạo danh sách tất cả các records check-in/check-out
    final allRecords = <Map<String, dynamic>>[];

    // Thêm check-in records
    for (final record in widget.employee.checkInHistory) {
      allRecords.add({'type': 'in', 'timestamp': record.timestamp});
    }

    // Thêm check-out records
    for (final record in widget.employee.checkOutHistory) {
      allRecords.add({'type': 'out', 'timestamp': record.timestamp});
    }

    // Sắp xếp theo thời gian mới nhất
    allRecords.sort(
      (a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );

    if (allRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử điểm danh',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allRecords.length,
          itemBuilder: (context, index) {
            final record = allRecords[index];
            final isCheckIn = record['type'] == 'in';
            final timestamp = record['timestamp'] as DateTime;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCheckIn
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF2A3950),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCheckIn
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                            : const Color(0xFF2A3950).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCheckIn ? Icons.login : Icons.logout,
                        color: isCheckIn
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2A3950),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCheckIn ? 'Check-in' : 'Check-out',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy - HH:mm:ss',
                            ).format(timestamp),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(EmployeeNotificationItem notification) {
    final now = DateTime.now();
    final diff = now.difference(notification.timestamp);
    String timeAgo;
    if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours} giờ trước';
    } else {
      timeAgo = '${diff.inDays} ngày trước';
    }

    IconData icon;
    Color iconBgColor;
    Color borderColor;

    switch (notification.type) {
      case EmployeeNotificationType.leaveApproved:
        icon = Icons.check_circle;
        iconBgColor = const Color(0xFF4CAF50).withValues(alpha: 0.1);
        borderColor = const Color(0xFF4CAF50);
        break;
      case EmployeeNotificationType.leaveRejected:
        icon = Icons.cancel;
        iconBgColor = const Color(0xFF2A3950).withValues(alpha: 0.1);
        borderColor = const Color(0xFF2A3950);
        break;
      case EmployeeNotificationType.custom:
        icon = Icons.campaign;
        iconBgColor = const Color(0xFF9C27B0).withValues(alpha: 0.1);
        borderColor = const Color(0xFF9C27B0);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: borderColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2A3950),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!notification.isRead)
                  TextButton.icon(
                    onPressed: () => _markAsRead(notification),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Đánh dấu đã đọc'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2A3950),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _deleteNotification(notification),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
