import 'package:flutter/material.dart';

class ScanLogo extends StatelessWidget {
  final VoidCallback? onTap;

  const ScanLogo({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xFF2A3950),
        ),
        child: const Icon(Icons.qr_code_scanner, size: 46, color: Colors.white),
      ),
    );
  }
}
