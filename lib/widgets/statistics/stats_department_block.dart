import 'package:flutter/material.dart';
import '../../models/employee.dart';
import 'department_performance_row.dart';

class DepartmentPerformanceBlock extends StatelessWidget {
  final List<Employee> employees;

  const DepartmentPerformanceBlock({super.key, required this.employees});

  @override
  Widget build(BuildContext context) {
    final depts = employees.map((e) => e.dept).toSet().toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hiệu suất phòng ban",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),

          for (int i = 0; i < depts.length; i++)
            DepartmentPerformanceRow(
              index: i + 1,
              dept: depts[i],
              total: employees.where((e) => e.dept == depts[i]).length,
              present: employees
                  .where(
                    (e) =>
                        e.dept == depts[i] &&
                        (e.getTodayStatus() == AttendanceStatus.present ||
                            e.getTodayStatus() == AttendanceStatus.late),
                  )
                  .length,
            ),
        ],
      ),
    );
  }
}
