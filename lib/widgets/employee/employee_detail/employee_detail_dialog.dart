import 'package:flutter/material.dart';
import 'detail_header.dart';
import 'detail_leave_block.dart';
import 'detail_history_section.dart';
import 'edit_employee_dialog.dart';
import '../../../models/employee.dart';
import '../../../repositories/app_repositories.dart';

void showEmployeeDetailDialog(BuildContext context, Employee emp) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => EmployeeDetailDialog(employeeId: emp.id),
  );
}

class EmployeeDetailDialog extends StatelessWidget {
  final String employeeId;
  const EmployeeDetailDialog({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Employee>>(
      stream: AppRepositories.employeeRepo.streamEmployees(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Material(
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(40),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          );
        }

        final employee = snapshot.data!.firstWhere(
          (e) => e.id == employeeId,
          orElse: () => snapshot.data!.first,
        );

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Material(
              color: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DetailHeader(employee: employee),
                      SizedBox(height: 12),
                      DetailLeaveBlock(employee: employee),
                      DetailHistorySection(
                        icon: Icons.access_time,
                        color: Colors.orange,
                        title: "Lịch sử đi muộn",
                        count: "${employee.lateCount} lần",
                        items: employee.lateHistory.map((r) {
                          final date =
                              "${r.timestamp.day}/${r.timestamp.month}/${r.timestamp.year}";
                          return "$date - Trễ ${r.minutesLate} phút";
                        }).toList(),
                      ),
                      DetailHistorySection(
                        icon: Icons.error_outline,
                        color: Colors.red,
                        title: "Lịch sử vắng mặt",
                        count: "${employee.absentCount} lần",
                        items: employee.absentHistory.map((r) {
                          final reason = r.reason ?? "Không rõ lý do";
                          return "${r.date} - $reason";
                        }).toList(),
                      ),

                      // Nút sửa thông tin
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await showEditEmployeeDialog(
                                context,
                                employee,
                                AppRepositories.employeeRepo,
                              );
                              // Không đóng dialog, để StreamBuilder tự động refresh
                            },
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text(
                              "Sửa thông tin",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A3950),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
