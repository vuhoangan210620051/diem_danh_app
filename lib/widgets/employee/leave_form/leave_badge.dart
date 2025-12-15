import 'package:flutter/material.dart';
import '../../../models/leave_record.dart';

class LeaveBadge extends StatelessWidget {
  final LeaveStatus status;

  const LeaveBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.textColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
