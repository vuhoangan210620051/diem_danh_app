import 'package:flutter/material.dart';
import '../../../../models/leave_record.dart';
import '../../../common/common_app_header.dart';
import '../leave_status_tabs.dart';

class LeaveHeader extends StatelessWidget implements PreferredSizeWidget {
  final LeaveStatus selected;
  final ValueChanged<LeaveStatus> onChanged;
  final VoidCallback onCreate;
  final Map<LeaveStatus, int> counts;

  const LeaveHeader({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onCreate,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return CommonAppHeader(
      title: "Đơn xin nghỉ",
      actions: [
        // Padding(
        //   padding: const EdgeInsets.only(right: 12),
        //   child: ElevatedButton.icon(
        //     onPressed: onCreate,
        //     icon: const Icon(Icons.add, size: 18),
        //     label: const Text("Tạo đơn"),
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: const Color(0xFF2A3950),
        //       foregroundColor: Colors.white,
        //       elevation: 0,
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(20),
        //       ),
        //     ),
        //   ),
        // ),
      ],
      bottom: LeaveStatusTabs(
        selected: selected,
        onChanged: onChanged,
        counts: counts,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(104);
}
