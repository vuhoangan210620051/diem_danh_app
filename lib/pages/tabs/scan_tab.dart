import 'package:flutter/material.dart';
import '../../widgets/scan/scan_logo.dart';
import '../../widgets/scan/scan_input.dart';
import '../../widgets/scan/scan_header.dart';
import '../../models/employee.dart';
import '../../repositories/employee_repository.dart';
import '../../widgets/scan/QR_Scan/qr_scan_page.dart';
import '../../services/attendance_service.dart';
import 'package:flutter/foundation.dart';

class ScanTab extends StatefulWidget {
  final EmployeeRepository repo;
  final List<Employee> employees;

  const ScanTab({super.key, required this.repo, required this.employees});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  late final TextEditingController inputCtrl;
  bool isCheckInMode = true; // true: Check-in, false: Check-out
  Employee? lastScannedEmployee;

  @override
  void initState() {
    super.initState();
    inputCtrl = TextEditingController();
  }

  @override
  void dispose() {
    inputCtrl.dispose();
    super.dispose();
  }

  Employee? findEmployeeById(String id) {
    try {
      return widget.employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void _showDesktopHint(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Color(0xFF2A3950)),
            SizedBox(width: 8),
            Text("Quét QR trên Web"),
          ],
        ),
        content: const Text(
          "Trình duyệt web không hỗ trợ quét QR trực tiếp.\n\n"
          "Vui lòng:\n"
          "• Nhập ID nhân viên vào ô bên dưới\n"
          "• Hoặc sử dụng ứng dụng trên điện thoại để quét QR",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A3950),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Đã hiểu", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FCF7),
      appBar: const ScanHeader(),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScanLogo(
                    onTap: () async {
                      if (kIsWeb) {
                        // WEB: không mở camera
                        _showDesktopHint(context);
                        return;
                      }
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(builder: (_) => const QRScanPage()),
                      );

                      if (result != null && result.isNotEmpty) {
                        inputCtrl.text = result;

                        // Sử dụng mode được chọn từ toggle
                        final emp = findEmployeeById(result);
                        if (emp == null) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Không tìm thấy nhân viên"),
                              ),
                            );
                          }
                          return;
                        }

                        if (isCheckInMode) {
                          // Thực hiện check-in
                          final attendanceResult =
                              await AttendanceService.confirm(emp, widget.repo);

                          if (!mounted) return;

                          switch (attendanceResult) {
                            case AttendanceResult.present:
                              _snack(
                                context,
                                "✅ Check-in thành công! Đúng giờ",
                              );
                              break;

                            case AttendanceResult.late:
                              _snack(
                                context,
                                "⚠️ Check-in thành công! Đi muộn",
                              );
                              break;

                            case AttendanceResult.absent:
                              _snack(context, "❌ Quá 15 phút → tính vắng");
                              break;

                            case AttendanceResult.onLeave:
                              _snack(context, "ℹ️ Hôm nay đang nghỉ phép");
                              return;

                            case AttendanceResult.alreadyChecked:
                              _snack(context, "ℹ️ Hôm nay đã check-in rồi");
                              return;

                            case AttendanceResult.afterWork:
                              _snack(context, "❌ Đã hết giờ làm việc");
                              return;
                          }
                        } else {
                          // Thực hiện check-out
                          final checkOutResult =
                              await AttendanceService.checkOut(
                                emp,
                                widget.repo,
                              );

                          if (!mounted) return;

                          switch (checkOutResult) {
                            case CheckOutResult.success:
                              _snack(
                                context,
                                "✅ Check-out thành công! Đủ giờ làm",
                              );
                              break;
                            case CheckOutResult.insufficientHours:
                              _snack(
                                context,
                                "⚠️ Check-out thành công! Chưa đủ 8 giờ - Sẽ tính vắng",
                              );
                              break;
                            case CheckOutResult.notCheckedIn:
                              _snack(context, "❌ Chưa check-in hôm nay");
                              return;
                            case CheckOutResult.alreadyCheckedOut:
                              _snack(context, "ℹ️ Hôm nay đã check-out rồi");
                              return;
                          }
                        }

                        // Cập nhật nhân viên vừa quét để hiển thị trạng thái
                        setState(() {
                          lastScannedEmployee = emp;
                        });

                        inputCtrl.clear();
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Quét mã nhân viên",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Quét mã vạch hoặc nhập ID nhân viên",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 22),

                  // Toggle Check-in/Check-out
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isCheckInMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isCheckInMode
                                    ? const Color(0xFF2A3950)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.login,
                                    size: 20,
                                    color: isCheckInMode
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Check-in',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isCheckInMode
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isCheckInMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isCheckInMode
                                    ? const Color(0xFF2A3950)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout,
                                    size: 20,
                                    color: !isCheckInMode
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Check-out',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: !isCheckInMode
                                          ? Colors.white
                                          : Colors.grey,
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

                  const SizedBox(height: 22),
                  ScanInput(controller: inputCtrl),
                  const SizedBox(height: 18),

                  // Nút xác nhận dựa trên mode hiện tại
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => isCheckInMode
                          ? _handleCheckIn(context)
                          : _handleCheckOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A3950),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCheckInMode ? Icons.login : Icons.logout,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCheckInMode
                                ? "Xác nhận Check-in"
                                : "Xác nhận Check-out",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
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

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleCheckIn(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final inputId = inputCtrl.text.trim();
    if (inputId.isEmpty) return;

    final emp = findEmployeeById(inputId);
    if (emp == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Không tìm thấy nhân viên")));
      return;
    }

    final result = await AttendanceService.confirm(emp, widget.repo);

    if (!mounted) return;

    switch (result) {
      case AttendanceResult.present:
        _snack(context, "Check-in thành công! Đúng giờ");
        break;
      case AttendanceResult.late:
        _snack(context, "Check-in thành công! Đi muộn");
        break;
      case AttendanceResult.absent:
        _snack(context, "Quá 15 phút → tính vắng");
        break;
      case AttendanceResult.onLeave:
        _snack(context, "Hôm nay đang nghỉ phép");
        return;
      case AttendanceResult.alreadyChecked:
        _snack(context, "Hôm nay đã check-in rồi");
        return;
      case AttendanceResult.afterWork:
        _snack(context, "Đã hết giờ làm việc");
        return;
    }

    inputCtrl.clear();
  }

  Future<void> _handleCheckOut(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final inputId = inputCtrl.text.trim();
    if (inputId.isEmpty) return;

    final emp = findEmployeeById(inputId);
    if (emp == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Không tìm thấy nhân viên")));
      return;
    }

    final result = await AttendanceService.checkOut(emp, widget.repo);

    if (!mounted) return;

    switch (result) {
      case CheckOutResult.success:
        _snack(context, "Check-out thành công! Đủ giờ làm");
        break;
      case CheckOutResult.insufficientHours:
        _snack(
          context,
          "Check-out thành công! Chưa đủ 8 giờ làm - Sẽ tính vắng",
        );
        break;
      case CheckOutResult.notCheckedIn:
        _snack(context, "Chưa check-in hôm nay");
        return;
      case CheckOutResult.alreadyCheckedOut:
        _snack(context, "Hôm nay đã check-out rồi");
        return;
    }

    setState(() {
      lastScannedEmployee = emp;
    });

    inputCtrl.clear();
  }
}
