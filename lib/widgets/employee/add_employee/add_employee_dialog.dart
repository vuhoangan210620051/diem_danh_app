import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../../models/employee.dart';
import '../../../repositories/employee_repository.dart';
import 'avatar_picker.dart'; // chỉ dùng cái này

// void showAddEmployeeDialog(BuildContext context, EmployeeRepository repo) {
//   showDialog(
//     context: context,
//     barrierDismissible: true,
//     builder: (_) => AddEmployeeDialog(repo: repo),
//   );
// }
Future<bool?> showAddEmployeeDialog(
  BuildContext context,
  EmployeeRepository repo,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => AddEmployeeDialog(repo: repo),
  );
}

String deptCode(String dept) {
  switch (dept) {
    case "Phát triển":
      return "DEV";
    case "Kinh doanh":
      return "SAL";
    case "Marketing":
      return "MKT";
    case "Nhân sự":
      return "HRM";
    default:
      return "XXX";
  }
}

String generateEmployeeId(String dept) {
  final now = DateTime.now();

  final String code = deptCode(dept);
  final String mm = now.month.toString().padLeft(2, '0');
  final String yy = (now.year % 100).toString().padLeft(2, '0');
  final String rand = (1000 + (now.millisecondsSinceEpoch % 9000)).toString();

  return "$code$mm$yy$rand";
}

class AddEmployeeDialog extends StatefulWidget {
  final EmployeeRepository repo;

  const AddEmployeeDialog({super.key, required this.repo});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  File? avatarFile;
  Uint8List? avatarBytes; // web
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final nameController = TextEditingController();
  String? selectedDept;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------- HEADER --------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Thêm nhân viên mới",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: isLoading ? null : () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        size: 26,
                        color: isLoading ? Colors.grey : Colors.black,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // -------- AVATAR PICKER --------
                Center(
                  child: AvatarPicker(
                    onChanged: (file, bytes) {
                      avatarFile = file; // mobile
                      avatarBytes = bytes; // web
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // -------- NAME --------
                const Text(
                  "Họ và tên",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "Nhập họ và tên",
                    filled: true,
                    fillColor: const Color(0xFFF5F7F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 22),
                const SizedBox(height: 18),

                // -------- EMAIL --------
                const Text(
                  "Email",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "email@company.com",
                    filled: true,
                    fillColor: const Color(0xFFF5F7F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // -------- PASSWORD --------
                const Text(
                  "Mật khẩu",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),

                TextField(
                  controller: passwordController,
                  // obscureText: true,
                  decoration: InputDecoration(
                    hintText: "password",
                    filled: true,
                    fillColor: const Color(0xFFF5F7F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // -------- Department --------
                DropdownButtonFormField<String>(
                  items: const [
                    DropdownMenuItem(
                      value: "Phát triển",
                      child: Text("Phát triển"),
                    ),
                    DropdownMenuItem(
                      value: "Kinh doanh",
                      child: Text("Kinh doanh"),
                    ),
                    DropdownMenuItem(
                      value: "Marketing",
                      child: Text("Marketing"),
                    ),
                    DropdownMenuItem(value: "Nhân sự", child: Text("Nhân sự")),
                  ],
                  onChanged: (v) => selectedDept = v,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F7F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  hint: const Text("Chọn phòng ban"),
                ),

                const SizedBox(height: 32),

                // -------- BUTTONS --------
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Hủy"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A3950),
                        disabledBackgroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              "Thêm",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (isLoading) return; // Ngăn spam click

    if (nameController.text.trim().isEmpty) {
      _show("Vui lòng nhập tên");
      return;
    }
    if (emailController.text.trim().isEmpty) {
      _show("Vui lòng nhập email");
      return;
    }
    if (passwordController.text.trim().length < 6) {
      _show("Mật khẩu tối thiểu 6 ký tự");
      return;
    }
    if (selectedDept == null) {
      _show("Chọn phòng ban");
      return;
    }

    // Kiểm tra email trùng
    final existingEmployees = await widget.repo.getEmployees();
    final emailExists = existingEmployees.any(
      (e) => e.email.toLowerCase() == emailController.text.trim().toLowerCase(),
    );
    if (emailExists) {
      _show("Email đã tồn tại trong hệ thống");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Chuyển avatar thành base64 string
      String? avatarBase64;
      if (avatarBytes != null) {
        // Web: dùng bytes trực tiếp
        avatarBase64 = 'data:image/png;base64,${base64Encode(avatarBytes!)}';
      } else if (avatarFile != null) {
        // Mobile: đọc file thành bytes
        final bytes = await avatarFile!.readAsBytes();
        avatarBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
      }

      final employee = Employee(
        id: generateEmployeeId(selectedDept!),
        name: nameController.text.trim(),
        dept: selectedDept!,
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        avatarPath: avatarBase64,
      );

      await widget.repo.addEmployee(employee);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      final msg = e.toString();
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
