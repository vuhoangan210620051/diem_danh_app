import 'package:flutter/material.dart';

class ScanButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const ScanButton({super.key, required this.onPressed, required this.text});
  int calculateMinutesLate(DateTime now) {
    final workTime = DateTime(now.year, now.month, now.day, 9, 0);
    if (now.isBefore(workTime)) return 0;
    return now.difference(workTime).inMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A3950), Color(0xFF5B8FA3)],
          ),
          ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
