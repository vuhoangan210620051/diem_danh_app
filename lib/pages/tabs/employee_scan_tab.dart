import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/employee.dart';
import '../../widgets/scan/scan_header.dart';

class EmployeeScanTab extends StatelessWidget {
  final Employee employee;

  const EmployeeScanTab({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FCF7),
      appBar: const ScanHeader(),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ===== LOGO (GIỮ NGUYÊN) =====
                  // const ScanLogo(),
                  const SizedBox(height: 6),

                  const Text(
                    "Mã QR nhân viên",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Đưa mã này cho quản lý để quét",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 6),

                  // ===== QR CODE =====
                  QrImageView(
                    data: employee.id,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),

                  const SizedBox(height: 6),

                  // ===== ID =====
                  Text(
                    employee.id,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    employee.name,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 24),

                  // Hiển thị trạng thái điểm danh hiện tại
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: _buildStatusRow(employee),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(Employee emp) {
    final status = emp.getTodayStatus();
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case AttendanceStatus.present:
        statusText = 'Có mặt';
        statusColor = const Color(0xFF2A3950);
        statusIcon = Icons.check_circle;
        break;
      case AttendanceStatus.late:
        statusText = 'Đi muộn';
        statusColor = const Color(0xFFFFB74D);
        statusIcon = Icons.access_time;
        break;
      case AttendanceStatus.absent:
        statusText = 'Vắng';
        statusColor = const Color(0xFF2A3950);
        statusIcon = Icons.cancel;
        break;
      case AttendanceStatus.onLeave:
        statusText = 'Nghỉ phép';
        statusColor = const Color(0xFF64B5F6);
        statusIcon = Icons.event_busy;
        break;
      case AttendanceStatus.notChecked:
        statusText = 'Chưa điểm danh';
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        break;
    }

    return Row(
      children: [
        Icon(statusIcon, size: 18, color: statusColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              children: [
                const TextSpan(text: 'Trạng thái hôm nay: '),
                TextSpan(
                  text: statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
