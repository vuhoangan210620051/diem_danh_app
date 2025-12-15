import 'package:flutter/material.dart';

class StatsRecentActivity extends StatelessWidget {
  const StatsRecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hoạt động gần đây",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 18),
          Center(
            child: Text(
              "Chưa có hoạt động nào",
              style: TextStyle(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }
}
