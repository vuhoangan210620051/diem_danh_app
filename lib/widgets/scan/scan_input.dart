import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ScanInput extends StatelessWidget {
  final TextEditingController controller;
  const ScanInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: "Quét mã hoặc nhập ID (vd: SAL12134512)",
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),

        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }
}
