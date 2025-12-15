import 'package:flutter/material.dart';

class StatsAttendanceRate extends StatelessWidget {
  final double rate;

  const StatsAttendanceRate({super.key, required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== HEADER =====
          Row(
            children: [
              // 🎯 ICON TRÒN THEO MOCK
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.track_changes,
                  color: Color(0xFF2A3950),
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  "Tỷ lệ điểm danh",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const Icon(Icons.trending_up, color: Colors.green),
            ],
          ),

          const SizedBox(height: 14),

          /// ===== VALUE =====
          Text(
            "${(rate * 100).round()}%",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          /// ===== PROGRESS =====
          LinearProgressIndicator(
            value: rate,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            color: const Color(0xFF2A3950),
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}
