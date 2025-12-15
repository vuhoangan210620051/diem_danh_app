import 'package:flutter/material.dart';

class DepartmentPerformanceRow extends StatelessWidget {
  final int index;
  final String dept;
  final int total;
  final int present;

  const DepartmentPerformanceRow({
    super.key,
    required this.index,
    required this.dept,
    required this.total,
    required this.present,
  });

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0 : (present / total * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              // ===== ICON SỐ THỨ TỰ =====
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3950),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  "$index",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ===== TÊN PHÒNG BAN =====
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dept,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "$total nhân viên",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // ===== BADGE % =====
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$rate%",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ===== PROGRESS =====
          LinearProgressIndicator(
            value: rate / 100,
            minHeight: 6,
            backgroundColor: Colors.grey.shade300,
            color: const Color(0xFF2A3950),
          ),
        ],
      ),
    );
  }
}
