import 'package:flutter/material.dart';
import '../common/common_app_header.dart';

class StatisticsHeader extends StatelessWidget implements PreferredSizeWidget {
  const StatisticsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonAppHeader(
      title: "Thống kê điểm danh",
      bottom: Align(
        alignment: Alignment.centerLeft, // 👈 ÉP CĂN TRÁI
        child: Text(
          "Thứ Sáu, 12 tháng 12, 2025",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
