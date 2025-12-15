import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../models/employee.dart';
import '../../../repositories/employee_repository.dart';
import '../../../theme/app_colors.dart';

Future<bool?> showEditEmployeeDialog(
  BuildContext context,
  Employee employee,
  EmployeeRepository repo,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => EditEmployeeDialog(employee: employee, repo: repo),
  );
}

class EditEmployeeDialog extends StatefulWidget {
  final Employee employee;
  final EmployeeRepository repo;

  const EditEmployeeDialog({
    super.key,
    required this.employee,
    required this.repo,
  });

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late String selectedDept;
  bool _obscurePassword = true;
  File? avatarFile;
  Uint8List? avatarBytes;
  String? currentAvatarPath;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.employee.name);
    emailController = TextEditingController(text: widget.employee.email);
    passwordController = TextEditingController(text: widget.employee.password);
    selectedDept = widget.employee.dept;
    currentAvatarPath = widget.employee.avatarPath;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
                      "Sửa thông tin nhân viên",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 26),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // -------- AVATAR PICKER --------
                Center(child: _buildAvatarSection()),

                const SizedBox(height: 24),

                // -------- ID (không thể sửa) --------
                const Text(
                  "ID nhân viên",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.employee.id,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ),

                const SizedBox(height: 18),

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
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "password",
                    filled: true,
                    fillColor: const Color(0xFFF5F7F8),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // -------- Department --------
                const Text(
                  "Phòng ban",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedDept,
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
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        selectedDept = v;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F7F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
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
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Lưu",
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
    if (nameController.text.trim().isEmpty) {
      _showSnackBar("Vui lòng nhập tên");
      return;
    }
    if (emailController.text.trim().isEmpty) {
      _showSnackBar("Vui lòng nhập email");
      return;
    }
    if (passwordController.text.trim().length < 6) {
      _showSnackBar("Mật khẩu tối thiểu 6 ký tự");
      return;
    }

    // Xử lý avatar nếu có thay đổi
    String? avatarBase64 = currentAvatarPath;
    if (avatarBytes != null) {
      avatarBase64 = 'data:image/png;base64,${base64Encode(avatarBytes!)}';
    } else if (avatarFile != null) {
      final bytes = await avatarFile!.readAsBytes();
      avatarBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
    }

    final updatedEmployee = widget.employee.copyWith(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      dept: selectedDept,
      avatarPath: avatarBase64,
    );

    try {
      await widget.repo.updateEmployee(updatedEmployee);
      if (mounted) {
        Navigator.pop(context, true);
        _showSnackBar("Cập nhật thành công");
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Lỗi: ${e.toString()}");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildAvatarSection() {
    // Hiển thị ảnh đã chọn mới hoặc ảnh hiện tại
    Widget avatarWidget;

    if (avatarBytes != null) {
      // Ảnh mới từ web
      avatarWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          avatarBytes!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          cacheWidth: 200,
          cacheHeight: 200,
          errorBuilder: (context, error, stackTrace) => _defaultAvatarIcon(),
        ),
      );
    } else if (avatarFile != null) {
      // Ảnh mới từ mobile
      avatarWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          avatarFile!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          cacheWidth: 200,
          cacheHeight: 200,
          errorBuilder: (context, error, stackTrace) => _defaultAvatarIcon(),
        ),
      );
    } else if (currentAvatarPath != null && currentAvatarPath!.isNotEmpty) {
      // Ảnh hiện tại từ employee
      if (currentAvatarPath!.startsWith('data:image')) {
        try {
          final base64String = currentAvatarPath!.split(',')[1];
          avatarWidget = ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              const Base64Decoder().convert(base64String),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              cacheWidth: 200,
              cacheHeight: 200,
              errorBuilder: (context, error, stackTrace) =>
                  _defaultAvatarIcon(),
            ),
          );
        } catch (e) {
          avatarWidget = _defaultAvatarIcon();
        }
      } else {
        avatarWidget = _defaultAvatarIcon();
      }
    } else {
      avatarWidget = _defaultAvatarIcon();
    }

    return GestureDetector(
      onTap: () async {
        // Sử dụng ImagePicker để chọn ảnh
        final picker = ImagePicker();
        final XFile? picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );

        if (picked != null) {
          if (kIsWeb) {
            final bytes = await picked.readAsBytes();
            setState(() {
              avatarBytes = bytes;
              avatarFile = null;
            });
          } else {
            // Crop ảnh trước khi lưu
            final croppedFile = await ImageCropper().cropImage(
              sourcePath: picked.path,
              aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
              uiSettings: [
                AndroidUiSettings(
                  toolbarTitle: 'Chỉnh sửa ảnh',
                  toolbarColor: const Color(0xFF2A3950),
                  toolbarWidgetColor: Colors.white,
                  initAspectRatio: CropAspectRatioPreset.square,
                  lockAspectRatio: true,
                ),
                IOSUiSettings(
                  title: 'Chỉnh sửa ảnh',
                  aspectRatioLockEnabled: true,
                  resetAspectRatioEnabled: false,
                ),
              ],
            );

            if (croppedFile != null) {
              setState(() {
                avatarFile = File(croppedFile.path);
                avatarBytes = null;
              });
            }
          }
        }
      },
      child: Stack(
        children: [
          avatarWidget,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3950),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatarIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF5F7F8),
      ),
      child: const Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
    );
  }
}
