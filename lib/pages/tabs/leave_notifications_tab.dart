import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../models/leave_record.dart';
import '../../repositories/employee_repository.dart';
import 'package:intl/intl.dart';

class LeaveNotificationsTab extends StatelessWidget {
  final EmployeeRepository repo;
  final List<Employee> employees;

  const LeaveNotificationsTab({
    super.key,
    required this.repo,
    required this.employees,
  });

  @override
  Widget build(BuildContext context) {
    // Tạo danh sách tất cả các đơn xin nghỉ
    final allLeaveRequests = <Map<String, dynamic>>[];

    for (final emp in employees) {
      for (final record in emp.leaveHistory) {
        allLeaveRequests.add({'employee': emp, 'leave': record});
      }
    }

    // Sắp xếp theo thời gian mới nhất (dùng startDate)
    allLeaveRequests.sort((a, b) {
      final leaveA = a['leave'] as LeaveRecord;
      final leaveB = b['leave'] as LeaveRecord;

      final timeA = DateTime.parse(leaveA.startDate);
      final timeB = DateTime.parse(leaveB.startDate);

      return timeB.compareTo(timeA);
    });

    if (allLeaveRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có thông báo đơn xin nghỉ',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allLeaveRequests.length,
      itemBuilder: (context, index) {
        final item = allLeaveRequests[index];
        final emp = item['employee'] as Employee;
        final leave = item['leave'] as LeaveRecord;

        final dateFormat = DateFormat('dd/MM/yyyy');
        final startDate = DateTime.parse(leave.startDate);
        final endDate = DateTime.parse(leave.endDate);

        Color statusColor;
        IconData statusIcon;
        String statusText;

        switch (leave.status) {
          case LeaveStatus.pending:
            statusColor = const Color(0xFFFFB74D);
            statusIcon = Icons.hourglass_empty;
            statusText = 'Chờ duyệt';
            break;
          case LeaveStatus.approved:
            statusColor = const Color(0xFF0F6BAC);
            statusIcon = Icons.check_circle;
            statusText = 'Đã duyệt';
            break;
          case LeaveStatus.rejected:
            statusColor = const Color(0xFF2A3950);
            statusIcon = Icons.cancel;
            statusText = 'Từ chối';
            break;
          case LeaveStatus.all:
            statusColor = Colors.grey;
            statusIcon = Icons.help_outline;
            statusText = 'Tất cả';
            break;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text(
              emp.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leave.reason.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.description,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lý do:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  leave.reason,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ID: ${emp.id}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
