import 'package:flutter/material.dart';
import '../common/common_app_header.dart';
import 'add_button.dart';
import 'employee_search.dart';
import 'add_employee/add_employee_dialog.dart';
import '../../repositories/employee_repository.dart';

class EmployeeHeader extends StatelessWidget implements PreferredSizeWidget {
  final EmployeeRepository repo;

  const EmployeeHeader({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return CommonAppHeader(
      title: "Danh sách nhân viên",

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AddEmployeeButton(
            onTap: () async {
              await showAddEmployeeDialog(context, repo);
              // StreamBuilder tự động cập nhật
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
