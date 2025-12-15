import 'package:diem_danh/pages/tabs/leave_tab.dart';
import 'package:flutter/material.dart';
import 'tabs/scan_tab.dart';
import 'tabs/employee_tab.dart';
import 'tabs/more_tab.dart';
import 'tabs/notification_tab.dart';
import '../theme/app_colors.dart';

import '../repositories/employee_repository.dart';
import '../repositories/app_repositories.dart';
import '../models/employee.dart';
import '../services/attendance_service.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int index = 0;
  int _unreadCount = 0;
  final EmployeeRepository repo = AppRepositories.employeeRepo;
  VoidCallback? _refreshNotifications;

  void updateUnreadCount(int count) {
    setState(() {
      _unreadCount = count;
    });
  }

  void setRefreshCallback(VoidCallback callback) {
    _refreshNotifications = callback;
  }

  @override
  void initState() {
    super.initState();
    // Auto mark absent khi khởi động
    repo.getEmployees().then((employees) async {
      await AttendanceService.autoMarkAbsent(repo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Employee>>(
      stream: repo.streamEmployees(),
      builder: (context, snapshot) {
        // Xử lý lỗi
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Trigger rebuild
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        // Đang loading
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final employees = snapshot.data!;

        // Tạo key dựa trên tổng số leave và statuses để force rebuild
        final leaveKey = employees.fold<String>(
          '',
          (prev, emp) =>
              prev +
              emp.leaveHistory
                  .map((l) => '${l.startDate}_${l.status.name}')
                  .join(','),
        );

        final pages = [
          ScanTab(
            employees: employees,
            repo: repo,
            key: ValueKey(employees.length),
          ),
          EmployeeTab(
            employees: employees,
            repo: repo,
            key: ValueKey(employees.length),
          ),
          LeaveTab(employees: employees, repo: repo, key: ValueKey(leaveKey)),
          NotificationTab(
            employees: employees,
            repo: repo,
            onUnreadCountChanged: updateUnreadCount,
            onRefreshCallbackSet: setRefreshCallback,
            key: ValueKey(leaveKey),
          ),
          SettingTab(
            employees: employees,
            repo: repo,
            key: ValueKey(employees.length),
          ),
        ];

        return Scaffold(
          body: IndexedStack(index: index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) {
              setState(() => index = i);
              // Reload notifications khi chuyển đến tab thông báo
              if (i == 3 && _refreshNotifications != null) {
                _refreshNotifications!();
              }
            },
            indicatorColor: AppColors.primary.withValues(alpha: .2),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.qr_code_scanner),
                label: "Quét mã",
              ),
              const NavigationDestination(
                icon: Icon(Icons.people_alt),
                label: "Nhân viên",
              ),
              const NavigationDestination(
                icon: Icon(Icons.description_outlined),
                label: "Duyệt đơn",
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: _unreadCount > 0,
                  label: Text(_unreadCount.toString()),
                  child: const Icon(Icons.notifications),
                ),
                label: "Thông báo",
              ),
              const NavigationDestination(
                icon: Icon(Icons.more_horiz),
                label: "Thêm",
              ),
            ],
          ),
        );
      },
    );
  }
}
