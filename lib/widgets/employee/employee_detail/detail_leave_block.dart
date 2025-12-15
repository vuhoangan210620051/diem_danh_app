import 'package:flutter/material.dart';
import '../../../models/employee.dart';
import '../../../config/work_time_config.dart';

class DetailLeaveBlock extends StatelessWidget {
  final Employee employee;
  const DetailLeaveBlock({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final usedLeave = employee.approvedLeaveDaysInYear(year);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                "Nghỉ phép năm",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text("Đã nghỉ", style: TextStyle(fontSize: 15)),
                    Spacer(),
                    Text(
                      "$usedLeave / ${WorkTimeConfig.maxLeaveDays} ngày",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: usedLeave / WorkTimeConfig.maxLeaveDays,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue,
                  backgroundColor: Colors.blueAccent.withValues(alpha: .2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
