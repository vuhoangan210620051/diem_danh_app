import 'package:flutter/material.dart';

class CommonAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? bottom;

  const CommonAppHeader({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF2A3950),
      scrolledUnderElevation: 0,
      surfaceTintColor: const Color(0xFF2A3950),

      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      iconTheme: const IconThemeData(color: Colors.white),

      actions: actions,

      bottom: bottom == null
          ? null
          : PreferredSize(
              preferredSize: preferredSize,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: bottom!,
              ),
            ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
