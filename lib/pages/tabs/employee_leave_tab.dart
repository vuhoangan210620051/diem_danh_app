import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/leave_record.dart';
import '../../models/custom_notification.dart';
import '../../repositories/employee_repository.dart';
import '../../services/browser_notification.dart';
import '../../services/custom_notification_service.dart';
import '../../widgets/employee/leave_form/leave_card.dart';
import '../../widgets/employee/leave_form/leave_header.dart';
import '../../widgets/employee/leave_form/create_leave_dialog.dart';

class EmployeeLeaveTab extends StatefulWidget {
  final Employee employee;
  final EmployeeRepository repo;

  const EmployeeLeaveTab({
    super.key,
    required this.employee,
    required this.repo,
  });

  @override
  State<EmployeeLeaveTab> createState() => _EmployeeLeaveTabState();
}

class _EmployeeLeaveTabState extends State<EmployeeLeaveTab> {
  late Employee _employee;
  LeaveStatus currentStatus = LeaveStatus.all;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
  }

  @override
  void didUpdateWidget(EmployeeLeaveTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cập nhật _employee khi parent truyền employee mới (admin đã approve/reject)
    if (oldWidget.employee.leaveHistory.length !=
            widget.employee.leaveHistory.length ||
        _hasLeaveStatusChanged(oldWidget.employee, widget.employee)) {
      setState(() {
        _employee = widget.employee;
      });
    }
  }

  bool _hasLeaveStatusChanged(Employee old, Employee current) {
    if (old.leaveHistory.length != current.leaveHistory.length) return true;
    for (var i = 0; i < old.leaveHistory.length; i++) {
      if (i >= current.leaveHistory.length) return true;
      if (old.leaveHistory[i].status != current.leaveHistory[i].status) {
        return true;
      }
    }
    return false;
  }

  List<LeaveRecord> get allLeaves => _employee.leaveHistory;

  List<LeaveRecord> get filteredLeaves {
    if (currentStatus == LeaveStatus.all) return allLeaves;
    return allLeaves.where((e) => e.status == currentStatus).toList();
  }

  Map<LeaveStatus, int> get counts => {
    LeaveStatus.all: allLeaves.length,
    LeaveStatus.pending: allLeaves
        .where((e) => e.status == LeaveStatus.pending)
        .length,
    LeaveStatus.approved: allLeaves
        .where((e) => e.status == LeaveStatus.approved)
        .length,
    LeaveStatus.rejected: allLeaves
        .where((e) => e.status == LeaveStatus.rejected)
        .length,
  };

  Future<void> _createLeave(BuildContext context) async {
    await showCreateLeaveDialog(context, _employee, (record) async {
      final updated = _employee.copyWith(
        leaveHistory: [..._employee.leaveHistory, record],
      );

      await widget.repo.updateEmployee(updated); // ✅ cập nhật DB

      // 🔔 Tạo thông báo cho admin
      await CustomNotificationService.addNotification(
        CustomNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Yêu cầu nghỉ phép mới',
          message: '${_employee.name} đã gửi đơn xin nghỉ ${record.type}',
          timestamp: DateTime.now(),
          target: NotificationTarget.all,
        ),
      );

      setState(() {
        _employee = updated; // ✅ replace object
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: EmployeeLeaveHeader(
        selected: currentStatus,
        onChanged: (s) => setState(() => currentStatus = s),
        counts: counts,
        onCreate: () => _createLeave(context),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (filteredLeaves.isEmpty)
                const Center(
                  child: Text(
                    "Không có đơn phù hợp",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              for (final leave in filteredLeaves)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EmployeeLeaveContent(employee: _employee, leave: leave),

                      // Nút thu hồi nếu đơn đang pending
                      if (leave.status == LeaveStatus.pending) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text('Thu hồi đơn'),
                                  content: const Text(
                                    'Bạn có chắc muốn thu hồi đơn nghỉ phép này?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Hủy'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text(
                                        'Thu hồi',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                // Trước khi thu hồi, kiểm tra trạng thái mới nhất tránh case admin vừa duyệt
                                final all = await widget.repo.getEmployees();
                                final latest = all.firstWhere(
                                  (e) => e.id == _employee.id,
                                  orElse: () => _employee,
                                );
                                final latestLeave = latest.leaveHistory
                                    .firstWhere(
                                      (l) => l == leave,
                                      orElse: () => leave,
                                    );
                                if (latestLeave.status != LeaveStatus.pending) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Không thể thu hồi: đơn đã được phản hồi',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                final updatedLeaves = latest.leaveHistory
                                    .where((l) => l != latestLeave)
                                    .toList();
                                final updated = latest.copyWith(
                                  leaveHistory: updatedLeaves,
                                );
                                await widget.repo.updateEmployee(updated);
                                setState(() {
                                  _employee = updated;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã thu hồi đơn'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text(
                              'Thu hồi đơn',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
