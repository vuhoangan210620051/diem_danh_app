import '../models/employee.dart';
import '../repositories/employee_repository.dart';
import '../models/late_record.dart';
import '../models/absent_record.dart';
import '../models/check_record.dart';
import '../config/work_time_config.dart';

class AttendanceService {
  static Future<AttendanceResult> confirm(
    Employee emp,
    EmployeeRepository repo,
  ) async {
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final startTime = WorkTimeConfig.startTime(now);
    final lateLimit = WorkTimeConfig.lateLimit(now);

    // 1. Kiểm tra đã check-in hôm nay chưa (dựa vào checkInHistory thực tế)
    final hasCheckedInToday = emp.checkInHistory.any((record) {
      final recordDate = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      final currentDate = DateTime(now.year, now.month, now.day);
      return recordDate.isAtSameMomentAs(currentDate) && record.type == 'in';
    });

    // Nếu đã check-in và còn trong khung giờ hợp lệ → block
    if (hasCheckedInToday && now.isBefore(lateLimit)) {
      return AttendanceResult.alreadyChecked;
    }

    if (emp.isOnApprovedLeave(now)) {
      return AttendanceResult.onLeave;
    }

    // 3. Quá 15p → vắng
    if (now.isAfter(lateLimit)) {
      final updated = emp.copyWith(
        absentHistory: [
          ...emp.absentHistory,
          AbsentRecord(date: today),
        ],
        lastCheckInDate: today,
      );

      await repo.updateEmployee(updated);
      return AttendanceResult.absent;
    }

    // 5. Đi muộn / đúng giờ
    LateRecord? late;
    if (now.isAfter(startTime)) {
      final minutesLate = now.difference(startTime).inMinutes;

      if (minutesLate > 0) {
        late = LateRecord(timestamp: now, minutesLate: minutesLate);
      }
    }

    final updated = emp.copyWith(
      lateHistory: [...emp.lateHistory, if (late != null) late],
      checkInHistory: [
        ...emp.checkInHistory,
        CheckRecord(timestamp: now, type: 'in'),
      ],
      lastCheckInDate: today,
    );

    await repo.updateEmployee(updated);
    return late != null ? AttendanceResult.late : AttendanceResult.present;
  }

  static Future<CheckOutResult> checkOut(
    Employee emp,
    EmployeeRepository repo,
  ) async {
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Kiểm tra đã check-in chưa
    if (emp.lastCheckInDate != today) {
      return CheckOutResult.notCheckedIn;
    }

    // Kiểm tra đã check-out hôm nay chưa
    final hasCheckedOut = emp.checkOutHistory.any((record) {
      final recordDate = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      final currentDate = DateTime(now.year, now.month, now.day);
      return recordDate.isAtSameMomentAs(currentDate);
    });

    if (hasCheckedOut) {
      return CheckOutResult.alreadyCheckedOut;
    }

    // Tìm check-in hôm nay
    final todayCheckIn = emp.checkInHistory.where((record) {
      final recordDate = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      final currentDate = DateTime(now.year, now.month, now.day);
      return recordDate.isAtSameMomentAs(currentDate);
    }).toList();

    if (todayCheckIn.isEmpty) {
      return CheckOutResult.notCheckedIn;
    }

    final checkInTime = todayCheckIn.first.timestamp;
    final workDuration = now.difference(checkInTime);

    // Kiểm tra thời gian hiện tại có >= thời gian ra về không
    final endWorkTime = WorkTimeConfig.endTime(now);
    final isAfterEndTime =
        now.isAfter(endWorkTime) || now.isAtSameMomentAs(endWorkTime);

    // Kiểm tra có đủ giờ làm không (8 giờ)
    final hasEnoughHours = workDuration.inHours >= WorkTimeConfig.minWorkHours;

    // Xác định có cần tính vắng không:
    // - Nếu checkout trước giờ ra về → tính vắng
    // - Nếu checkout sau giờ ra về nhưng chưa đủ 8 giờ → tính vắng
    final shouldMarkAbsent = !isAfterEndTime || !hasEnoughHours;

    // Thêm check-out vào lịch sử
    final updated = emp.copyWith(
      checkOutHistory: [
        ...emp.checkOutHistory,
        CheckRecord(timestamp: now, type: 'out'),
      ],
      // Tính vắng nếu checkout trước giờ ra về hoặc chưa đủ giờ làm
      absentHistory: shouldMarkAbsent
          ? [...emp.absentHistory, AbsentRecord(date: today)]
          : emp.absentHistory,
    );

    await repo.updateEmployee(updated);

    // Luôn cho phép checkout và trả về success
    return CheckOutResult.success;
  }

  static Future<void> autoMarkAbsent(EmployeeRepository repo) async {
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (now.isBefore(WorkTimeConfig.lateLimit(now))) return;

    final employees = await repo.getEmployees();

    for (final emp in employees) {
      // đã check-in → bỏ
      if (emp.lastCheckInDate == today) continue;

      // đang nghỉ phép → bỏ
      if (emp.isOnApprovedLeave(now)) continue;

      // đã bị đánh vắng → bỏ
      final alreadyAbsent = emp.absentHistory.any((a) => a.date == today);
      if (alreadyAbsent) continue;

      final updated = emp.copyWith(
        absentHistory: [
          ...emp.absentHistory,
          AbsentRecord(date: today),
        ],
        lastCheckInDate: today,
      );

      await repo.updateEmployee(updated);
    }
  }
}

enum AttendanceResult {
  present,
  late,
  absent,
  alreadyChecked,
  afterWork,
  onLeave,
}

enum CheckOutResult { success, notCheckedIn, alreadyCheckedOut }
