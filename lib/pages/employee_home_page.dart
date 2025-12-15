import 'dart:async';
import 'package:flutter/material.dart';
import 'tabs/employee_scan_tab.dart';
import 'tabs/employee_more_tab.dart';
import 'tabs/employee_attendance_tab.dart';
import '../models/employee.dart';
import '../models/custom_notification.dart';
import '../models/leave_record.dart';
import '../repositories/employee_repository.dart';
import '../services/custom_notification_service.dart';
import '../services/notification_state_service.dart';
import 'tabs/employee_leave_tab.dart';
import 'tabs/employee_notification_tab.dart';

class EmployeeHomePage extends StatefulWidget {
  final Employee employee;
  final EmployeeRepository repo;

  const EmployeeHomePage({
    super.key,
    required this.employee,
    required this.repo,
  });

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  int index = 0;
  int _unreadCount = 0;
  VoidCallback? _refreshNotifications;
  StreamSubscription<List<CustomNotification>>? _notificationSub;
  StreamSubscription<List<Employee>>? _employeeSub;
  late Employee _currentEmployee;

  @override
  void initState() {
    super.initState();
    _currentEmployee = widget.employee;
    _startListening();
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _employeeSub?.cancel();
    super.dispose();
  }

  void _startListening() {
    // Lắng nghe custom notifications
    _notificationSub = CustomNotificationService.streamNotificationsForEmployee(
      _currentEmployee.id,
      _currentEmployee.dept,
    ).listen((_) => _updateBadgeCount());

    // Lắng nghe thay đổi employee (leave status changes) từ Firestore
    _employeeSub = widget.repo.streamEmployees().listen((employees) {
      final updated = employees.firstWhere(
        (e) => e.id == widget.employee.id,
        orElse: () => _currentEmployee,
      );
      // Cập nhật employee hiện tại và rebuild UI
      if (mounted) {
        setState(() {
          _currentEmployee = updated;
        });
      }
      _updateBadgeCount();
    });

    _updateBadgeCount();
  }

  Future<void> _updateBadgeCount() async {
    int count = 0;

    // Đếm custom notifications chưa đọc
    final customNotifs =
        await CustomNotificationService.getNotificationsForEmployee(
          _currentEmployee.id,
          _currentEmployee.dept,
        );
    final readIds = await NotificationStateService.getEmployeeReadNotifications(
      _currentEmployee.id,
    );
    final deletedIds =
        await NotificationStateService.getEmployeeDeletedNotifications(
          _currentEmployee.id,
        );

    for (final notif in customNotifs) {
      final id = 'custom_${notif.id}';
      if (!deletedIds.contains(id) && !readIds.contains(id)) {
        count++;
      }
    }

    // Không cần đếm leave notifications nữa vì đã là CustomNotification thực sự

    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  void updateUnreadCount(int count) {
    setState(() {
      _unreadCount = count;
    });
  }

  void setRefreshCallback(VoidCallback callback) {
    _refreshNotifications = callback;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      EmployeeScanTab(employee: _currentEmployee),
      EmployeeLeaveTab(employee: _currentEmployee, repo: widget.repo),
      EmployeeNotificationTab(
        employee: _currentEmployee,
        onUnreadCountChanged: updateUnreadCount,
        onRefreshCallbackSet: setRefreshCallback,
      ),
      EmployeeAttendanceTab(employee: _currentEmployee),
      EmployeeMoreTab(employee: _currentEmployee),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() => index = i);
          // Reload notifications khi chuyển đến tab thông báo
          if (i == 2 && _refreshNotifications != null) {
            _refreshNotifications!();
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: "Quét mã",
          ),
          const NavigationDestination(
            icon: Icon(Icons.description_outlined),
            label: "Nghỉ phép",
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            label: "Thông báo",
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: "Thống kê",
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: "Tài khoản",
          ),
        ],
      ),
    );
  }
}
