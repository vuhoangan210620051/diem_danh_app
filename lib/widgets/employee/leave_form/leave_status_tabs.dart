import 'package:flutter/material.dart';
import '../../../models/leave_record.dart';

class LeaveStatusTabs extends StatelessWidget {
  final LeaveStatus selected;
  final ValueChanged<LeaveStatus> onChanged;
  final Map<LeaveStatus, int> counts;
  const LeaveStatusTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.counts,
  });

  Widget _buildTab(LeaveStatus status) {
    final bool isActive = selected == status;
    final count = counts[status] ?? 0;

    return GestureDetector(
      onTap: () => onChanged(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F6BAC) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "${status.label} ($count)",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF667085),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab(LeaveStatus.all),
            const SizedBox(width: 8),
            _buildTab(LeaveStatus.pending),
            const SizedBox(width: 8),
            _buildTab(LeaveStatus.approved),
            const SizedBox(width: 8),
            _buildTab(LeaveStatus.rejected),
          ],
        ),
      ),
    );
  }
}
