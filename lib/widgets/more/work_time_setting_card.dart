import 'package:flutter/material.dart';
import '../../config/work_time_config.dart';
import '../../models/work_time_setting.dart';
import '../../repositories/firebase_work_time_repository.dart';
import '../../repositories/app_repositories.dart';
import '../../models/late_record.dart';
import '../../models/absent_record.dart';
import '../../models/check_record.dart';

class WorkTimeSettingCard extends StatefulWidget {
  const WorkTimeSettingCard({super.key});

  @override
  State<WorkTimeSettingCard> createState() => _WorkTimeSettingCardState();
}

class _WorkTimeSettingCardState extends State<WorkTimeSettingCard> {
  late TimeOfDay start;
  late TimeOfDay end;
  late TimeOfDay lateTime;

  @override
  void initState() {
    super.initState();
    start = TimeOfDay(
      hour: WorkTimeConfig.startHour,
      minute: WorkTimeConfig.startMinute,
    );
    end = TimeOfDay(
      hour: WorkTimeConfig.endHour,
      minute: WorkTimeConfig.endMinute,
    );
    final startTotal =
        WorkTimeConfig.startHour * 60 + WorkTimeConfig.startMinute;
    final lateTotal = startTotal + WorkTimeConfig.allowLateMinutes;
    lateTime = TimeOfDay(hour: lateTotal ~/ 60, minute: lateTotal % 60);
  }

  Future<void> _pickTime(
    TimeOfDay current,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  String _fmt(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// ===== CARD =====
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE6FBF6),
                    child: Icon(Icons.access_time, color: Color(0xFF2A3950)),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Giờ làm việc",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// GIỜ VÀO / RA
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: "Giờ vào",
                      value: _fmt(start),
                      onTap: () => _pickTime(start, (v) => start = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: "Giờ ra",
                      value: _fmt(end),
                      onTap: () => _pickTime(end, (v) => end = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// GIỜ TÍNH MUỘN
              _TimeField(
                label: "Thời gian tính muộn",
                value: _fmt(lateTime),
                helper: "Sau giờ này sẽ tính là đi muộn",
                onTap: () => _pickTime(lateTime, (v) => lateTime = v),
              ),
            ],
          ),
        ),

        /// ===== SAVE BUTTON =====
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text("Lưu cài đặt"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A3950),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ===== SAVE =====
  Future<void> _save() async {
    final repo = FirebaseWorkTimeRepository();
    final setting = WorkTimeSetting(
      startHour: start.hour,
      startMinute: start.minute,
      endHour: end.hour,
      endMinute: end.minute,
      allowLateMinutes:
          (lateTime.hour * 60 + lateTime.minute) -
          (start.hour * 60 + start.minute),
    );

    // 1️⃣ LƯU FIREBASE (đồng bộ tất cả thiết bị)
    await repo.saveSetting(setting);

    // 2️⃣ ÁP DỤNG NGAY CHO THIẾT BỊ NÀY
    WorkTimeConfig.applyFromSetting(setting);

    // 3️⃣ TÍNH LẠI TẤT CẢ ĐIỂM DANH TRONG NGÀY
    await _recalculateTodayAttendance();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã lưu giờ làm việc và cập nhật điểm danh"),
      ),
    );
  }

  /// TÍNH LẠI ĐIỂM DANH HÔM NAY
  Future<void> _recalculateTodayAttendance() async {
    final employeeRepo = AppRepositories.employeeRepo;
    final employees = await employeeRepo.getEmployees();
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    for (final emp in employees) {
      // Tìm check-in hôm nay trong checkInHistory (không dùng lastCheckInDate vì có thể bị reset)
      final todayCheckIns = emp.checkInHistory.where((record) {
        final recordDate = DateTime(
          record.timestamp.year,
          record.timestamp.month,
          record.timestamp.day,
        );
        final currentDate = DateTime(now.year, now.month, now.day);
        return recordDate.isAtSameMomentAs(currentDate) && record.type == 'in';
      }).toList();

      // Chỉ xử lý nhân viên đã check-in hôm nay
      if (todayCheckIns.isEmpty) continue;

      final checkInTime = todayCheckIns.first.timestamp;
      final startTime = WorkTimeConfig.startTime(checkInTime);
      final lateLimit = WorkTimeConfig.lateLimit(checkInTime);

      // Xóa tất cả late và absent của hôm nay trước
      List<LateRecord> newLateHistory = emp.lateHistory.where((late) {
        final lateDate = DateTime(
          late.timestamp.year,
          late.timestamp.month,
          late.timestamp.day,
        );
        final currentDate = DateTime(now.year, now.month, now.day);
        return !lateDate.isAtSameMomentAs(currentDate);
      }).toList();

      List<AbsentRecord> newAbsentHistory = emp.absentHistory.where((absent) {
        return absent.date != today;
      }).toList();

      // Reset lastCheckInDate để cho phép check-in lại
      String? newLastCheckInDate;
      List<CheckRecord> newCheckInHistory = emp.checkInHistory;

      // Kiểm tra lại: đi muộn hay đúng giờ hay vắng
      if (checkInTime.isAfter(lateLimit)) {
        // Quá 15p → Reset về trạng thái "chưa điểm danh"
        // Xóa checkInHistory và KHÔNG thêm late hay absent
        newLastCheckInDate = null;
        newCheckInHistory = emp.checkInHistory.where((record) {
          final recordDate = DateTime(
            record.timestamp.year,
            record.timestamp.month,
            record.timestamp.day,
          );
          final currentDate = DateTime(now.year, now.month, now.day);
          return !recordDate.isAtSameMomentAs(currentDate);
        }).toList();
      } else if (checkInTime.isAfter(startTime)) {
        // Đi muộn - thêm vào newLateHistory (giữ lastCheckInDate và checkInHistory)
        final minutesLate = checkInTime.difference(startTime).inMinutes;
        if (minutesLate > 0) {
          newLateHistory.add(
            LateRecord(timestamp: checkInTime, minutesLate: minutesLate),
          );
        }
        newLastCheckInDate = today;
      } else {
        // Đúng giờ (giữ lastCheckInDate và checkInHistory, không thêm late)
        newLastCheckInDate = today;
      }

      // Cập nhật employee
      final updatedEmp = emp.copyWith(
        checkInHistory: newCheckInHistory,
        lateHistory: newLateHistory,
        absentHistory: newAbsentHistory,
        lastCheckInDate: newLastCheckInDate,
      );

      await employeeRepo.updateEmployee(updatedEmp);
    }
  }
}

/// ===== TIME FIELD =====
class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextField(
              decoration: InputDecoration(
                hintText: value,
                suffixIcon: const Icon(Icons.access_time),
                filled: true,
                fillColor: const Color(0xFFF5F7F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}
