import 'package:diem_danh/config/work_time_config.dart';

import 'absent_record.dart';
import 'late_record.dart';
import 'leave_record.dart';
import 'check_record.dart';

enum AttendanceStatus { present, late, absent, notChecked, onLeave }

class Employee {
  final String id;
  final String name;
  final String dept;
  final String email;
  final String password;
  final String? avatarPath;
  final String? lastCheckInDate;
  final List<LateRecord> lateHistory;
  final List<AbsentRecord> absentHistory;
  final List<LeaveRecord> leaveHistory;
  final List<CheckRecord> checkInHistory;
  final List<CheckRecord> checkOutHistory;

  Employee({
    required this.id,
    required this.name,
    required this.dept,
    required this.email,
    required this.password,
    this.avatarPath,
    this.lateHistory = const [],
    this.leaveHistory = const [],
    this.absentHistory = const [],
    this.lastCheckInDate,
    this.checkInHistory = const [],
    this.checkOutHistory = const [],
  });
  Employee copyWith({
    String? id,
    String? name,
    String? dept,
    String? email,
    String? password,
    String? avatarPath,
    List<LateRecord>? lateHistory,
    List<LeaveRecord>? leaveHistory,
    List<AbsentRecord>? absentHistory,
    String? lastCheckInDate,
    List<CheckRecord>? checkInHistory,
    List<CheckRecord>? checkOutHistory,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      dept: dept ?? this.dept,
      email: email ?? this.email,
      password: password ?? this.password,
      avatarPath: avatarPath ?? this.avatarPath,
      lateHistory: lateHistory ?? this.lateHistory,
      leaveHistory: leaveHistory ?? this.leaveHistory,
      absentHistory: absentHistory ?? this.absentHistory,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
      checkInHistory: checkInHistory ?? this.checkInHistory,
      checkOutHistory: checkOutHistory ?? this.checkOutHistory,
    );
  }

  int get lateCount => lateHistory.length;
  int get absentCount => absentHistory.length;
  int get leaveCount => leaveHistory.length;
  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "dept": dept,
    "email": email,
    "password": password,
    "checkInHistory": checkInHistory.map((e) => e.toJson()).toList(),
    "checkOutHistory": checkOutHistory.map((e) => e.toJson()).toList(),
    "avatarPath": avatarPath,
    "lateHistory": lateHistory.map((e) => e.toJson()).toList(),
    "absentHistory": absentHistory.map((e) => e.toJson()).toList(),
    "leaveHistory": leaveHistory.map((e) => e.toJson()).toList(),

    "lastCheckInDate": lastCheckInDate,
  };

  bool isOnApprovedLeave(DateTime day) {
    return leaveHistory.any((leave) {
      if (leave.status != LeaveStatus.approved) return false;

      final start = DateTime.parse(leave.startDate);
      final end = DateTime.parse(leave.endDate);

      return !day.isBefore(start) && !day.isAfter(end);
    });
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json["id"],
      name: json["name"],
      dept: json["dept"],
      email: json["email"],
      password: json["password"],
      avatarPath: json["avatarPath"],
      lateHistory: (json["lateHistory"] as List<dynamic>? ?? [])
          .map((e) => LateRecord.fromJson(e))
          .toList(),
      absentHistory: (json["absentHistory"] as List<dynamic>? ?? [])
          .map((e) => AbsentRecord.fromJson(e))
          .toList(),
      leaveHistory: (json["leaveHistory"] as List<dynamic>? ?? [])
          .map((e) => LeaveRecord.fromJson(e))
          .toList(),
      checkInHistory: (json["checkInHistory"] as List<dynamic>? ?? [])
          .map((e) => CheckRecord.fromJson(e))
          .toList(),
      checkOutHistory: (json["checkOutHistory"] as List<dynamic>? ?? [])
          .map((e) => CheckRecord.fromJson(e))
          .toList(),
      lastCheckInDate: json["lastCheckInDate"],
    );
  }

  int absentCountInYear(int year) {
    return absentHistory.where((record) {
      final d = DateTime.parse(record.date);
      return d.year == year;
    }).length;
  }

  int approvedLeaveDaysInYear(int year) {
    return leaveHistory
        .where((leave) {
          if (leave.status != LeaveStatus.approved) return false;

          final start = DateTime.parse(leave.startDate);
          return start.year == year;
        })
        .fold(0, (sum, leave) => sum + leave.days);
  }

  int get approvedLeaveCount {
    return leaveHistory.where((l) => l.status == LeaveStatus.approved).length;
  }

  int remainingLeaveDays(int year, {int totalPerYear = 12}) {
    final used = approvedLeaveDaysInYear(year);
    return (totalPerYear - used).clamp(0, totalPerYear);
  }

  AttendanceStatus getTodayStatus() {
    final now = DateTime.now();

    // 1. Nghỉ phép
    if (isOnApprovedLeave(now)) {
      return AttendanceStatus.onLeave;
    }

    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final startTime = WorkTimeConfig.startTime(now);
    final lateLimit = WorkTimeConfig.lateLimit(now);
    final endTime = WorkTimeConfig.endTime(now);

    // 2. VẮNG (ưu tiên trước)
    final isAbsentToday = absentHistory.any((a) => a.date == todayStr);
    if (isAbsentToday) {
      return AttendanceStatus.absent;
    }

    // 3. ĐÃ CHECK-IN (kiểm tra trong checkInHistory thay vì lastCheckInDate)
    final hasCheckInToday = checkInHistory.any((record) {
      final recordDate = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      final currentDate = DateTime(now.year, now.month, now.day);
      return recordDate.isAtSameMomentAs(currentDate);
    });

    if (hasCheckInToday) {
      final isLateToday = lateHistory.any((l) {
        final d = l.timestamp;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      });

      return isLateToday ? AttendanceStatus.late : AttendanceStatus.present;
    }

    // 4. Chưa đến giờ
    if (now.isBefore(startTime)) {
      return AttendanceStatus.notChecked;
    }

    // 5. Đến giờ nhưng chưa quét
    if (now.isAfter(startTime) && now.isBefore(lateLimit)) {
      return AttendanceStatus.notChecked;
    }

    // 6. Quá 15 phút
    if (now.isAfter(lateLimit) && now.isBefore(endTime)) {
      return AttendanceStatus.absent;
    }

    return AttendanceStatus.absent;
  }
}

class EmployeeLeave {
  final Employee employee;
  final LeaveRecord leave;

  EmployeeLeave({required this.employee, required this.leave});
}
