import 'dart:convert';
import 'package:flutter/material.dart';
import 'employee_detail/employee_detail_dialog.dart';
import '../../models/employee.dart';

class EmployeeCard extends StatelessWidget {
  // final String name;
  // final String id;
  // final String dept;
  final VoidCallback onDelete;
  final Employee emp;

  const EmployeeCard({
    super.key,
    required this.emp,
    // required this.name,
    // required this.id,
    // required this.dept,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => showEmployeeDetailDialog(context, emp),
                child: _buildAvatar(),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => showEmployeeDetailDialog(context, emp),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${emp.id} • ${emp.dept}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Badge trạng thái
              _buildStatusBadge(emp),

              const SizedBox(width: 10),

              // Nút xóa
              // InkWell(
              //   onTap: onDelete,
              //   child: Container(
              //     padding: const EdgeInsets.all(6),
              //     decoration: BoxDecoration(
              //       border: Border.all(color: Colors.grey.shade300),
              //       shape: BoxShape.circle,
              //     ),
              //     child: const Icon(Icons.close, size: 18),
              //   ),
              // ),
            ],
          ),

          const SizedBox(height: 14),

          // Xóa nhân viên
          GestureDetector(
            onTap: onDelete,
            child: Row(
              children: const [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 6),
                Text(
                  "Xóa nhân viên",
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (emp.avatarPath != null && emp.avatarPath!.isNotEmpty) {
      // Nếu có avatar, hiển thị ảnh từ base64
      if (emp.avatarPath!.startsWith('data:image')) {
        try {
          final base64String = emp.avatarPath!.split(',')[1];
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              const Base64Decoder().convert(base64String),
              width: 55,
              height: 55,
              fit: BoxFit.cover,
              cacheWidth: 110,
              cacheHeight: 110,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF2A3950),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                );
              },
            ),
          );
        } catch (e) {
          // Fallback nếu decode lỗi
        }
      }
    }

    // Mặc định: hiển thị icon
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF2A3950),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 32),
    );
  }
}

Widget _buildStatusBadge(Employee emp) {
  final status = emp.getTodayStatus();

  late Color bgColor;
  late String text;

  switch (status) {
    case AttendanceStatus.present:
      bgColor = Colors.green.shade100;
      text = "Có mặt";
      break;
    case AttendanceStatus.onLeave:
      bgColor = const Color.fromARGB(74, 240, 129, 18);
      text = "Nghỉ phép";
      break;
    case AttendanceStatus.late:
      bgColor = Colors.orange.shade100;
      text = "Đi muộn";
      break;
    case AttendanceStatus.absent:
      bgColor = Colors.red.shade100;
      text = "Vắng";
      break;
    case AttendanceStatus.notChecked:
      bgColor = Colors.grey.shade200;
      text = "Chưa điểm danh";
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(text, style: const TextStyle(fontSize: 13)),
  );
}
