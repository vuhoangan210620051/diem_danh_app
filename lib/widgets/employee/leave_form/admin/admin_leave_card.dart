import 'package:flutter/material.dart';
import '../../../../models/employee.dart';
import '../../../../models/leave_record.dart';
import '../leave_card.dart';

class AdminLeaveCard extends StatelessWidget {
  final Employee employee;
  final LeaveRecord leave;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const AdminLeaveCard({
    super.key,
    required this.employee,
    required this.leave,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 420;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HÀNG TRÊN =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: EmployeeLeaveContent(
                      employee: employee,
                      leave: leave,
                      showStatus: false,
                    ),
                  ),

                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    _RightActions(
                      leave: leave,
                      onApprove: onApprove,
                      onReject: onReject,
                    ),
                  ],
                ],
              ),

              // ===== MOBILE: RỚT XUỐNG DƯỚI =====
              if (isMobile) ...[
                const SizedBox(height: 14),
                _RightActions(
                  leave: leave,
                  onApprove: onApprove,
                  onReject: onReject,
                  alignLeft: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RightActions extends StatelessWidget {
  final LeaveRecord leave;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool alignLeft;

  const _RightActions({
    required this.leave,
    required this.onApprove,
    required this.onReject,
    this.alignLeft = false,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final isPending = leave.status == LeaveStatus.pending;

    // ❌ KHÔNG CÒN PENDING → CHỈ HIỆN TRẠNG THÁI
    if (!isPending) {
      return _statusPill(
        text: leave.status.label,
        bgColor: leave.status.bgColor,
        textColor: leave.status.textColor,
        icon: leave.status.icon,
      );
    }

    // ===== MOBILE: 3 NÚT 1 HÀNG =====
    if (alignLeft) {
      return Row(
        children: [
          Expanded(
            child: _statusPill(
              text: leave.status.label,
              bgColor: leave.status.bgColor,
              textColor: leave.status.textColor,
              icon: leave.status.icon,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _actionChip(
              text: "Chấp nhận",
              textColor: const Color(0xFF1E9E61),
              bgColor: const Color(0xFFE6F7EE),
              onTap: onApprove,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _actionChip(
              text: "Từ chối",
              textColor: const Color(0xFFD92D20),
              bgColor: const Color(0xFFFFE5E5),
              onTap: onReject,
            ),
          ),
        ],
      );
    }

    // ===== DESKTOP / TABLET =====
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _statusPill(
          text: leave.status.label,
          bgColor: leave.status.bgColor,
          textColor: leave.status.textColor,
          icon: leave.status.icon,
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _actionChip(
              text: "Chấp nhận",
              textColor: const Color(0xFF1E9E61),
              bgColor: const Color(0xFFE6F7EE),
              onTap: onApprove,
            ),
            const SizedBox(height: 6),
            _actionChip(
              text: "Từ chối",
              textColor: const Color(0xFFD92D20),
              bgColor: const Color(0xFFFFE5E5),
              onTap: onReject,
            ),
          ],
        ),
      ],
    );
  }
}

/// pill trạng thái (giống Chờ duyệt)
Widget _statusPill({
  required String text,
  required Color bgColor,
  required Color textColor,
  required IconData icon,
}) {
  return Container(
    width: 110,
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: textColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    ),
  );
}

Widget _actionChip({
  required String text,
  required Color textColor,
  required Color bgColor,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 110,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    ),
  );
}
