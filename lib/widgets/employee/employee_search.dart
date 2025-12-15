import 'package:flutter/material.dart';

class EmployeeSearch extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const EmployeeSearch({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Color(0xFF757575)),
          hintText: "Tìm kiếm nhân viên...",
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        ),
      ),
    );
  }
}
