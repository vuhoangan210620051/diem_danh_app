import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Admin login will use local repo/auth service (no firebase_auth required)
import '../theme/app_colors.dart';
import '../widgets/login/login_form.dart';
import '../pages/admin_home_page.dart';
import '../pages/employee_home_page.dart';
import '../services/auth_service.dart';
import '../repositories/local_admin_repository.dart';
import '../services/employee_auth_service.dart';
import '../services/browser_notification.dart';
import '../repositories/app_repositories.dart';

enum LoginType { admin, employee }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginType type = LoginType.admin;
  String? savedEmail;
  String? savedPassword;
  bool savedRememberMe = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedEmail = prefs.getString('saved_email');
      savedPassword = prefs.getString('saved_password');
      savedRememberMe = prefs.getBool('remember_me') ?? false;
      final savedType = prefs.getString('login_type');
      if (savedType == 'employee') {
        type = LoginType.employee;
      }
      isLoading = false;
    });

    // Auto login nếu có thông tin lưu
    if (savedRememberMe && savedEmail != null && savedPassword != null) {
      _autoLogin();
    }
  }

  Future<void> _autoLogin() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final empAuth = EmployeeAuthService(AppRepositories.employeeRepo);

    if (type == LoginType.admin) {
      final auth = AuthService(LocalAdminRepository());
      final username = savedEmail!.contains('@')
          ? savedEmail!.split('@').first
          : savedEmail!;
      final ok = await auth.loginAdmin(username, savedPassword!);
      if (ok && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
        );
      }
    } else {
      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (_) {}
      }
      final emp = await empAuth.login(savedEmail!, savedPassword!);
      if (emp != null && mounted) {
        // 🔔 Xin quyền browser notification
        await BrowserNotificationService.requestPermission();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeHomePage(
              employee: emp,
              repo: AppRepositories.employeeRepo,
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveCredentials(
    String email,
    String password,
    bool rememberMe,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
      await prefs.setString('login_type', type.name);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.remove('remember_me');
      await prefs.remove('login_type');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final empAuth = EmployeeAuthService(AppRepositories.employeeRepo);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ANHL Company',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hệ thống điểm danh',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Card chứa form
                  Card(
                    elevation: 0,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ===== TOGGLE ADMIN / NHÂN VIÊN =====
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => type = LoginType.admin),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: type == LoginType.admin
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: type == LoginType.admin
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.admin_panel_settings,
                                            size: 20,
                                            color: type == LoginType.admin
                                                ? AppColors.primary
                                                : Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Admin',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: type == LoginType.admin
                                                  ? AppColors.primary
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => type = LoginType.employee,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: type == LoginType.employee
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: type == LoginType.employee
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 20,
                                            color: type == LoginType.employee
                                                ? AppColors.primary
                                                : Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Nhân viên',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: type == LoginType.employee
                                                  ? AppColors.primary
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ===== LOGIN FORM =====
                          LoginForm(
                            initialEmail: savedRememberMe ? savedEmail : null,
                            initialPassword: savedRememberMe
                                ? savedPassword
                                : null,
                            initialRememberMe: savedRememberMe,
                            onLogin: (email, password, rememberMe) async {
                              await _saveCredentials(
                                email,
                                password,
                                rememberMe,
                              );
                              final ctx = context;
                              if (type == LoginType.admin) {
                                // Use local admin auth (username default 'admin', password '123456')
                                final auth = AuthService(
                                  LocalAdminRepository(),
                                );
                                // allow user to type admin@... or admin
                                final username = email.contains('@')
                                    ? email.split('@').first
                                    : email;
                                final ok = await auth.loginAdmin(
                                  username,
                                  password,
                                );
                                if (ok) {
                                  if (mounted) {
                                    Navigator.pushReplacement(
                                      ctx,
                                      MaterialPageRoute(
                                        builder: (_) => const AdminHomePage(),
                                      ),
                                    );
                                  }
                                  return true;
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đăng nhập admin thất bại.',
                                        ),
                                      ),
                                    );
                                  }
                                  return false;
                                }
                              } else {
                                // Ensure we're authenticated (anonymous or real user)
                                if (FirebaseAuth.instance.currentUser == null) {
                                  try {
                                    await FirebaseAuth.instance
                                        .signInAnonymously();
                                  } catch (_) {}
                                }

                                final emp = await empAuth.login(
                                  email,
                                  password,
                                );
                                if (emp != null && mounted) {
                                  // 🔔 Xin quyền browser notification
                                  await BrowserNotificationService.requestPermission();

                                  Navigator.pushReplacement(
                                    ctx,
                                    MaterialPageRoute(
                                      builder: (_) => EmployeeHomePage(
                                        employee: emp,
                                        repo: AppRepositories.employeeRepo,
                                      ),
                                    ),
                                  );
                                  return true;
                                }
                                return false;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
