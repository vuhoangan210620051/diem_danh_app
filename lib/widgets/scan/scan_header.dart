import 'package:flutter/material.dart';
import '../common/common_app_header.dart';

class ScanHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScanHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommonAppHeader(title: "Điểm danh nhân viên");
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
