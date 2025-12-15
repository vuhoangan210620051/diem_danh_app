import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/leave_record.dart';
import '../../models/custom_notification.dart';
import '../../services/custom_notification_service.dart';
import '../../widgets/employee/leave_form/admin/admin_leave_header.dart';
import '../../widgets/employee/leave_form/admin/admin_leave_card.dart';
import '../../models/employee.dart';
import '../../repositories/employee_repository.dart';

class LeaveTab extends StatefulWidget {
  final List<Employee> employees;
  final EmployeeRepository repo;

  const LeaveTab({super.key, required this.employees, required this.repo});

  @override
  State<LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<LeaveTab> {
  LeaveStatus currentStatus = LeaveStatus.all;
  Map<LeaveStatus, int> get statusCounts {
    return {
      LeaveStatus.all: allLeaves.length,
      LeaveStatus.pending: allLeaves
          .where((e) => e.leave.status == LeaveStatus.pending)
          .length,
      LeaveStatus.approved: allLeaves
          .where((e) => e.leave.status == LeaveStatus.approved)
          .length,
      LeaveStatus.rejected: allLeaves
          .where((e) => e.leave.status == LeaveStatus.rejected)
          .length,
    };
  }

  Future<void> _updateLeaveStatus({
    required Employee employee,
    required LeaveRecord leave,
    required LeaveStatus newStatus,
  }) async {
    final updatedLeave = LeaveRecord(
      type: leave.type,
      startDate: leave.startDate,
      endDate: leave.endDate,
      reason: leave.reason,
      days: leave.days,
      status: newStatus,
    );

    final updatedEmployee = employee.copyWith(
      leaveHistory: employee.leaveHistory
          .map((l) => l == leave ? updatedLeave : l)
          .toList(),
    );

    await widget.repo.updateEmployee(updatedEmployee);

    // TẠO THÔNG BÁO cho nhân viên ngay lập tức
    if (newStatus == LeaveStatus.approved ||
        newStatus == LeaveStatus.rejected) {
      final notification = CustomNotification(
        id: 'leave_${newStatus.name}_${employee.id}_${leave.startDate}_${DateTime.now().millisecondsSinceEpoch}',
        title: newStatus == LeaveStatus.approved
            ? 'Đơn xin nghỉ đã được duyệt'
            : 'Đơn xin nghỉ bị từ chối',
        message:
            'Đơn xin nghỉ của bạn từ ${DateFormat('dd/MM/yyyy').format(DateTime.parse(leave.startDate))} đến ${DateFormat('dd/MM/yyyy').format(DateTime.parse(leave.endDate))} đã ${newStatus == LeaveStatus.approved ? "được phê duyệt" : "bị từ chối"}',
        timestamp: DateTime.now(),
        target: NotificationTarget.specific,
        targetValue: employee.id,
        senderId: 'admin',
        senderName: 'Quản trị viên',
      );
      await CustomNotificationService.addNotification(notification);
    }

    setState(() {
      final index = widget.employees.indexWhere((e) => e.id == employee.id);
      widget.employees[index] = updatedEmployee;
    });
  }

  void onStatusChanged(LeaveStatus status) {
    setState(() => currentStatus = status);
  }

  List<EmployeeLeave> get allLeaves {
    final List<EmployeeLeave> result = [];

    for (final emp in widget.employees) {
      for (final leave in emp.leaveHistory) {
        result.add(EmployeeLeave(employee: emp, leave: leave));
      }
    }

    return result;
  }

  List<EmployeeLeave> get filteredLeaves {
    if (currentStatus == LeaveStatus.all) {
      return allLeaves;
    }

    return allLeaves.where((e) => e.leave.status == currentStatus).toList();
  }

  void onCreateLeave() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: LeaveHeader(
        selected: currentStatus,
        onChanged: onStatusChanged,
        onCreate: onCreateLeave,
        counts: statusCounts,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final item in filteredLeaves)
                AdminLeaveCard(
                  employee: item.employee,
                  leave: item.leave,
                  onApprove: () {
                    _updateLeaveStatus(
                      employee: item.employee,
                      leave: item.leave,
                      newStatus: LeaveStatus.approved,
                    );
                  },
                  onReject: () {
                    _updateLeaveStatus(
                      employee: item.employee,
                      leave: item.leave,
                      newStatus: LeaveStatus.rejected,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
