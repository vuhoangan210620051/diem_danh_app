import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'login_logo.dart';
import 'login_button.dart';

class LoginForm extends StatefulWidget {
  final Future<bool> Function(String email, String password, bool rememberMe)
  onLogin;
  final String? initialEmail;
  final String? initialPassword;
  final bool initialRememberMe;

  const LoginForm({
    super.key,
    required this.onLogin,
    this.initialEmail,
    this.initialPassword,
    this.initialRememberMe = false,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final TextEditingController emailCtrl;
  late final TextEditingController passwordCtrl;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
    passwordCtrl = TextEditingController(text: widget.initialPassword ?? '');
    _rememberMe = widget.initialRememberMe;
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LoginLogo(),
        const SizedBox(height: 10),
        const Text(
          "Chào mừng trở lại",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          "Đăng nhập vào tài khoản của bạn",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 25),

        // ====== EMAIL FIELD ======
        TextField(
          controller: emailCtrl,
          decoration: InputDecoration(
            labelText: "Email",
            labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade800),
            hintText: "name@example.com",
            filled: true,
            fillColor: const Color(0xFFF7F9FA),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.email_outlined, color: AppColors.primary),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ====== PASSWORD FIELD ======
        TextField(
          controller: passwordCtrl,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: "Mật khẩu",
            labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade800),
            filled: true,
            fillColor: const Color(0xFFF7F9FA),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.lock_outline, color: AppColors.primary),
            ),
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 12,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ====== REMEMBER ME CHECKBOX ======
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: const Text(
                "Ghi nhớ đăng nhập",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF344054),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ====== LOGIN BUTTON ======
        LoginButton(
          onPressed: () async {
            final email = emailCtrl.text.trim();
            final password = passwordCtrl.text.trim();

            if (email.isEmpty || password.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
              );
              return;
            }

            final ok = await widget.onLogin(email, password, _rememberMe);

            if (!ok) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sai tài khoản hoặc mật khẩu")),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
