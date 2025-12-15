import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../models/leave_record.dart';
import '../../models/custom_notification.dart';
import '../../repositories/employee_repository.dart';
import '../../services/notification_state_service.dart';
import '../../services/custom_notification_service.dart';
import '../../services/browser_notification.dart';
import '../../services/local_notification_service.dart';
import 'package:intl/intl.dart';

enum NotificationFilter { all, unread }

enum NotificationType { late, absent, leavePending, custom }

class NotificationItem {
  final String id;
  final String employeeId;
  final String employeeName;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class NotificationTab extends StatefulWidget {
  final EmployeeRepository repo;
  final List<Employee> employees;
  final Function(int)? onUnreadCountChanged;
  final Function(VoidCallback)? onRefreshCallbackSet;

  const NotificationTab({
    super.key,
    required this.repo,
    required this.employees,
    this.onUnreadCountChanged,
    this.onRefreshCallbackSet,
  });

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab>
    with AutomaticKeepAliveClientMixin {
  NotificationFilter _filter = NotificationFilter.all;
  final List<NotificationItem> _notifications = [];
  Set<String> _readNotificationIds = {};
  Set<String> _deletedNotificationIds = {};
  StreamSubscription<List<CustomNotification>>? _customNotifSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadReadState();
    // Lắng nghe custom notifications từ Firestore
    _customNotifSub = CustomNotificationService.streamNotifications().listen((
      notifications,
    ) {
      // 🔔 Hiển thị notification cho thông báo mới (admin)
      // Chỉ hiển thị thông báo "Yêu cầu nghỉ phép mới" (từ nhân viên gửi lên)
      if (notifications.isNotEmpty) {
        final latest = notifications.first;
        // Chỉ hiển thị nếu là yêu cầu nghỉ phép (không hiển thị khi admin tự duyệt)
        if (latest.title.contains('Yêu cầu nghỉ phép mới')) {
          if (kIsWeb) {
            BrowserNotificationService.show(
              title: latest.title,
              body: latest.message,
            );
          } else if (Platform.isAndroid) {
            LocalNotificationService.show(
              title: latest.title,
              body: latest.message,
            );
          }
        }
      }
      _loadReadState();
    });
    // Set callback để parent có thể trigger refresh
    widget.onRefreshCallbackSet?.call(_loadReadState);
  }

  @override
  void dispose() {
    _customNotifSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(NotificationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload notifications khi employees thay đổi (pending leaves, status changes)
    if (oldWidget.employees.length != widget.employees.length ||
        _hasEmployeeDataChanged(oldWidget.employees, widget.employees)) {
      _loadReadState();
    }
  }

  bool _hasEmployeeDataChanged(List<Employee> old, List<Employee> current) {
    if (old.length != current.length) return true;
    for (var i = 0; i < old.length; i++) {
      final oldEmp = old[i];
      final currentEmp = current.firstWhere(
        (e) => e.id == oldEmp.id,
        orElse: () => oldEmp,
      );
      if (oldEmp.leaveHistory.length != currentEmp.leaveHistory.length) {
        return true;
      }
      for (var j = 0; j < oldEmp.leaveHistory.length; j++) {
        if (j >= currentEmp.leaveHistory.length) return true;
        if (oldEmp.leaveHistory[j].status !=
            currentEmp.leaveHistory[j].status) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _loadReadState() async {
    _readNotificationIds =
        await NotificationStateService.getAdminReadNotifications();
    _deletedNotificationIds =
        await NotificationStateService.getAdminDeletedNotifications();
    await _loadNotifications();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadNotifications() async {
    _notifications.clear();
    final now = DateTime.now();

    // Admin không nhận custom notifications (chỉ nhân viên nhận)
    // Custom notifications được gửi từ admin đến nhân viên

    // Tạo thông báo từ đơn xin nghỉ
    for (final emp in widget.employees) {
      // Đơn xin nghỉ chờ duyệt (Admin nhận thông báo khi nhân viên tạo đơn)
      for (final leave in emp.leaveHistory) {
        if (leave.status == LeaveStatus.pending) {
          final leaveDate = DateTime.parse(leave.startDate);
          final notificationId = '${emp.id}_leave_pending_${leave.startDate}';
          _notifications.add(
            NotificationItem(
              id: notificationId,
              employeeId: emp.id,
              employeeName: emp.name,
              title: 'Đơn xin nghỉ mới',
              message:
                  '${emp.name} đã gửi đơn xin nghỉ từ ${DateFormat('dd/MM').format(DateTime.parse(leave.startDate))} đến ${DateFormat('dd/MM').format(DateTime.parse(leave.endDate))}',
              timestamp: leaveDate,
              type: NotificationType.leavePending,
              isRead: _readNotificationIds.contains(notificationId),
            ),
          );
        }
      }
    }

    // Lọc bỏ các notification đã xóa
    _notifications.removeWhere((n) => _deletedNotificationIds.contains(n.id));

    // Sắp xếp theo thời gian mới nhất
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _updateBadgeCount();
  }

  void _updateBadgeCount() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    widget.onUnreadCountChanged?.call(unreadCount);
  }

  List<NotificationItem> get _filteredNotifications {
    if (_filter == NotificationFilter.unread) {
      return _notifications.where((n) => !n.isRead).toList();
    }
    return _notifications;
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _markAllAsRead() async {
    final notificationIds = _notifications.map((n) => n.id).toList();
    await NotificationStateService.markAllAdminAsRead(notificationIds);
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

  Future<void> _markAsRead(NotificationItem notification) async {
    await NotificationStateService.markAdminNotificationAsRead(notification.id);
    _readNotificationIds.add(notification.id);
    notification.isRead = true;
    setState(() {});
    _updateBadgeCount();
  }

  Future<void> _deleteNotification(NotificationItem notification) async {
    // Admin chỉ có leave notifications, không có custom notifications
    // Đánh dấu notification đã xóa trong SharedPreferences
    await NotificationStateService.markAdminNotificationAsDeleted(
      notification.id,
    );
    _deletedNotificationIds.add(notification.id);

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
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
                  : ListView.builder(
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
    // Tạo danh sách tất cả các thông báo đã xử lý (vắng mặt, đơn nghỉ)
    final allHistoryItems = <Map<String, dynamic>>[];

    for (final emp in widget.employees) {
      // Thêm vắng mặt
      for (final absent in emp.absentHistory) {
        allHistoryItems.add({
          'employee': emp,
          'type': 'absent',
          'date': absent.date,
          'timestamp': DateTime.parse(absent.date),
        });
      }

      // Thêm đơn nghỉ đã xử lý (approved hoặc rejected)
      for (final leave in emp.leaveHistory) {
        if (leave.status != LeaveStatus.pending) {
          allHistoryItems.add({
            'employee': emp,
            'type': leave.status == LeaveStatus.approved
                ? 'leave_approved'
                : 'leave_rejected',
            'leave': leave,
            'timestamp': DateTime.parse(leave.startDate),
          });
        }
      }
    }

    // Sắp xếp theo thời gian mới nhất
    allHistoryItems.sort(
      (a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );

    if (allHistoryItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử',
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
          itemCount: allHistoryItems.length,
          itemBuilder: (context, index) {
            final item = allHistoryItems[index];
            final emp = item['employee'] as Employee;
            final type = item['type'] as String;
            final timestamp = item['timestamp'] as DateTime;

            IconData icon;
            Color iconBgColor;
            Color borderColor;
            String title;
            String subtitle;

            if (type == 'absent') {
              icon = Icons.cancel;
              iconBgColor = const Color(0xFF2A3950).withValues(alpha: 0.1);
              borderColor = const Color(0xFF2A3950);
              title = 'Vắng mặt';
              subtitle = 'Không điểm danh';
            } else if (type == 'leave_approved') {
              final leave = item['leave'] as LeaveRecord;
              icon = Icons.check_circle;
              iconBgColor = const Color(0xFF4CAF50).withValues(alpha: 0.1);
              borderColor = const Color(0xFF4CAF50);
              title = 'Đơn nghỉ đã duyệt';
              subtitle =
                  'Từ ${DateFormat('dd/MM').format(DateTime.parse(leave.startDate))} đến ${DateFormat('dd/MM').format(DateTime.parse(leave.endDate))}';
            } else {
              final leave = item['leave'] as LeaveRecord;
              icon = Icons.cancel;
              iconBgColor = const Color(0xFF2A3950).withValues(alpha: 0.1);
              borderColor = const Color(0xFF2A3950);
              title = 'Đơn nghỉ bị từ chối';
              subtitle =
                  'Từ ${DateFormat('dd/MM').format(DateTime.parse(leave.startDate))} đến ${DateFormat('dd/MM').format(DateTime.parse(leave.endDate))}';
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: borderColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
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

  Widget _buildNotificationCard(NotificationItem notification) {
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
      case NotificationType.late:
        icon = Icons.access_time;
        iconBgColor = const Color(0xFFFFB74D).withValues(alpha: 0.1);
        borderColor = const Color(0xFFFFB74D);
        break;
      case NotificationType.absent:
        icon = Icons.cancel;
        iconBgColor = const Color(0xFF2A3950).withValues(alpha: 0.1);
        borderColor = const Color(0xFF2A3950);
        break;
      case NotificationType.leavePending:
        icon = Icons.pending_actions;
        iconBgColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
        borderColor = const Color(0xFF3B82F6);
        break;
      case NotificationType.custom:
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
