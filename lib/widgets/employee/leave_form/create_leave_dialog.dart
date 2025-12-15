import 'package:flutter/material.dart';
import '../../../../models/employee.dart';
import '../../../../models/leave_record.dart';

Future<void> showCreateLeaveDialog(
  BuildContext context,
  Employee employee,
  void Function(LeaveRecord record) onSubmit,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CreateLeaveDialog(employee: employee, onSubmit: onSubmit),
  );
}

class _CreateLeaveDialog extends StatefulWidget {
  final Employee employee;
  final void Function(LeaveRecord record) onSubmit;

  const _CreateLeaveDialog({required this.employee, required this.onSubmit});

  @override
  State<_CreateLeaveDialog> createState() => _CreateLeaveDialogState();
}

class _CreateLeaveDialogState extends State<_CreateLeaveDialog> {
  String leaveType = "Nghỉ phép năm";
  DateTime? startDate;
  DateTime? endDate;
  final reasonCtrl = TextEditingController();

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      initialDate: now,
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startDate = picked;
      } else {
        endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Tạo đơn xin nghỉ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// NHÂN VIÊN
                const Text("Nhân viên"),
                const SizedBox(height: 6),
                _readonlyField(widget.employee.name),

                const SizedBox(height: 16),

                /// LOẠI NGHỈ
                const Text("Loại nghỉ phép"),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: leaveType,
                  items: const [
                    DropdownMenuItem(
                      value: "Nghỉ phép năm",
                      child: Text("Nghỉ phép năm"),
                    ),
                    DropdownMenuItem(value: "Nghỉ ốm", child: Text("Nghỉ ốm")),
                    DropdownMenuItem(
                      value: "Nghỉ không lương",
                      child: Text("Nghỉ không lương"),
                    ),
                  ],
                  onChanged: (v) => setState(() => leaveType = v!),
                  decoration: _inputDecoration(),
                ),

                const SizedBox(height: 16),

                /// DATE
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        label: "Từ ngày",
                        date: startDate,
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateField(
                        label: "Đến ngày",
                        date: endDate,
                        onTap: () => _pickDate(false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// LÝ DO
                const Text("Lý do"),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: _inputDecoration(hint: "Nhập lý do xin nghỉ..."),
                ),

                const SizedBox(height: 24),

                /// BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Hủy",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A3950),
                        ),
                        child: const Text(
                          "Gửi đơn",
                          style: TextStyle(color: Colors.white),
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

  void _submit() {
    if (startDate == null || endDate == null) return;

    final days = endDate!.difference(startDate!).inDays + 1;

    final record = LeaveRecord(
      type: leaveType,
      startDate: _fmt(startDate!),
      endDate: _fmt(endDate!),
      reason: reasonCtrl.text.trim(),
      status: LeaveStatus.pending,
      days: days,
    );

    widget.onSubmit(record);
    Navigator.pop(context);
  }

  String _fmt(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  String _displayFmt(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  }

  Widget _readonlyField(String text) {
    return TextField(enabled: false, decoration: _inputDecoration(hint: text));
  }

  Widget _dateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextField(
              decoration: _inputDecoration(
                hint: date == null ? "dd/mm/yyyy" : _displayFmt(date),
                suffix: const Icon(Icons.calendar_month),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF5F7F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
