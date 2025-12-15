import 'package:flutter/material.dart';
import '../../widgets/statistics/stats_header.dart';
import '../../widgets/statistics/stats_kpi_row.dart';
import '../../widgets/statistics/stats_department_block.dart';
import '../../repositories/employee_repository.dart';
import '../../models/employee.dart';

class StatisticsTab extends StatelessWidget {
  final EmployeeRepository repo;
  final List<Employee> employees;

  const StatisticsTab({super.key, required this.repo, required this.employees});
  int get totalEmployees => employees.length;

  int get presentToday {
    return employees
        .where((e) => e.getTodayStatus() == AttendanceStatus.present)
        .length;
  }

  int get lateToday {
    return employees
        .where((e) => e.getTodayStatus() == AttendanceStatus.late)
        .length;
  }

  int get absentToday {
    return employees
        .where((e) => e.getTodayStatus() == AttendanceStatus.absent)
        .length;
  }

  double get attendanceRate {
    if (employees.isEmpty) return 0;
    return presentToday / employees.length;
  }

  int deptTotal(String dept) => employees.where((e) => e.dept == dept).length;

  int deptPresent(String dept) => employees
      .where(
        (e) => e.dept == dept && e.getTodayStatus() == AttendanceStatus.present,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF6),

      appBar: StatisticsHeader(),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DashboardKpiGrid(
                total: totalEmployees,
                present: presentToday,
                late: lateToday,
                absent: absentToday,
              ),
              const SizedBox(height: 24),
              DepartmentPerformanceBlock(employees: employees),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
