import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../repositories/employee_repository.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryTab extends StatelessWidget {
  final EmployeeRepository repo;
  final List<Employee> employees;

  const AttendanceHistoryTab({
    super.key,
    required this.repo,
    required this.employees,
  });

  @override
  Widget build(BuildContext context) {
    // Tạo danh sách tất cả các records check-in/check-out
    final allRecords = <Map<String, dynamic>>[];

    for (final emp in employees) {
      // Thêm check-in records
      for (final record in emp.checkInHistory) {
        allRecords.add({
          'employee': emp,
          'type': 'in',
          'timestamp': record.timestamp,
        });
      }

      // Thêm check-out records
      for (final record in emp.checkOutHistory) {
        allRecords.add({
          'employee': emp,
          'type': 'out',
          'timestamp': record.timestamp,
        });
      }
    }

    // Sắp xếp theo thời gian mới nhất
    allRecords.sort(
      (a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );

    if (allRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có lịch sử điểm danh',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allRecords.length,
      itemBuilder: (context, index) {
        final record = allRecords[index];
        final emp = record['employee'] as Employee;
        final type = record['type'] as String;
        final timestamp = record['timestamp'] as DateTime;

        final isCheckIn = type == 'in';
        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCheckIn
                    ? const Color(0xFF2A3950).withValues(alpha: 0.1)
                    : const Color(0xFF2A3950).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCheckIn ? Icons.login : Icons.logout,
                color: isCheckIn
                    ? const Color(0xFF2A3950)
                    : const Color(0xFF2A3950),
              ),
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
                  'ID: ${emp.id}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(timestamp),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCheckIn
                    ? const Color(0xFF2A3950)
                    : const Color(0xFF2A3950),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCheckIn ? 'Check-in' : 'Check-out',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
