import 'package:flutter/material.dart';
import 'detail_history_item.dart';

class DetailHistorySection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String count;
  final List<String> items;

  const DetailHistorySection({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(count, style: TextStyle(color: color)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: items
                  .map((e) => DetailHistoryItem(text: e, color: color))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
