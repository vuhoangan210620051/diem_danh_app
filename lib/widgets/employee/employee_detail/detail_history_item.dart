import 'package:flutter/material.dart';

class DetailHistoryItem extends StatelessWidget {
  final String text;
  final Color color;

  const DetailHistoryItem({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color.withValues(alpha: .8)),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
