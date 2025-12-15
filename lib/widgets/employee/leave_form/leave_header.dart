import 'package:flutter/material.dart';
import '../../common/common_app_header.dart';
import 'leave_status_tabs.dart';
import '../../../models/leave_record.dart';

class EmployeeLeaveHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final LeaveStatus selected;
  final ValueChanged<LeaveStatus> onChanged;
  final Map<LeaveStatus, int> counts;
  final VoidCallback onCreate; // ✅ thêm callback

  const EmployeeLeaveHeader({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.counts,
    required this.onCreate, // ✅ bắt buộc
  });

  @override
  Widget build(BuildContext context) {
    return CommonAppHeader(
      title: "Đơn xin nghỉ",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 10),
          child: ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              "Tạo đơn",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A3950),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
      bottom: LeaveStatusTabs(
        selected: selected,
        onChanged: onChanged,
        counts: counts,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(114);
}
