import 'package:flutter/material.dart';

class DashboardKpiGrid extends StatelessWidget {
  final int total;
  final int present;
  final int late;
  final int absent;

  const DashboardKpiGrid({
    super.key,
    required this.total,
    required this.present,
    required this.late,
    required this.absent,
  });

  Widget _card({
    required IconData icon,
    required Color bg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: bg.withValues(alpha: .15),
            child: Icon(icon, color: bg),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      children: [
        _card(
          icon: Icons.people,
          bg: Colors.blue,
          label: "Tổng nhân viên",
          value: "$total",
        ),
        _card(
          icon: Icons.track_changes,
          bg: Colors.green,
          label: "Tỷ lệ điểm danh",
          value: total == 0 ? "0%" : "${(present / total * 100).round()}%",
        ),
        _card(
          icon: Icons.access_time,
          bg: Colors.orange,
          label: "Đi muộn hôm nay",
          value: "$late",
        ),
        _card(
          icon: Icons.error_outline,
          bg: Colors.red,
          label: "Vắng hôm nay",
          value: "$absent",
        ),
      ],
    );
  }
}
