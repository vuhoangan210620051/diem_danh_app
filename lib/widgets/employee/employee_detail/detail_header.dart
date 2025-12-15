import 'dart:convert';
import 'package:diem_danh/models/employee.dart';
import 'package:flutter/material.dart';

class DetailHeader extends StatelessWidget {
  final Employee employee;

  const DetailHeader({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF2A3950), // màu xanh đúng UI
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------- Hàng Avatar + tên + nút đóng -------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _buildAvatar(),

              const SizedBox(width: 14),

              // Tên + ID + Phòng ban
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${employee.id} • ${employee.dept}${employee.gender != null ? ' • ${employee.gender}' : ''}",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Nút đóng
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ------- 3 khối thống kê -------
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: "Nghỉ phép",
                  value:
                      "${employee.approvedLeaveDaysInYear(DateTime.now().year)} ngày",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: "Đi muộn",
                  value: "${employee.lateCount}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: "Vắng mặt",
                  value: "${employee.absentCount}",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (employee.avatarPath != null && employee.avatarPath!.isNotEmpty) {
      if (employee.avatarPath!.startsWith('data:image')) {
        try {
          final base64String = employee.avatarPath!.split(',')[1];
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              const Base64Decoder().convert(base64String),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              cacheWidth: 112,
              cacheHeight: 112,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person,
                    size: 34,
                    color: Colors.black87,
                  ),
                );
              },
            ),
          );
        } catch (e) {
          // Nếu lỗi decode thì hiển thị icon mặc định
        }
      }
    }

    // Mặc định: hiển thị icon
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 34, color: Colors.black87),
    );
  }
}

// *********************
//   WIDGET Ô THỐNG KÊ
// *********************
class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
