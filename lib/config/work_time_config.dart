import '../models/work_time_setting.dart';

class WorkTimeConfig {
  static int startHour = 8;
  static int startMinute = 0;

  static int endHour = 17;
  static int endMinute = 0;

  static int allowLateMinutes = 15;
  static const int maxLeaveDays = 12;
  static int minWorkHours = 8; // Số giờ làm việc tối thiểu

  static void applyFromSetting(WorkTimeSetting s) {
    startHour = s.startHour;
    startMinute = s.startMinute;
    endHour = s.endHour;
    endMinute = s.endMinute;
    allowLateMinutes = s.allowLateMinutes;
  }

  static DateTime startTime(DateTime day) =>
      DateTime(day.year, day.month, day.day, startHour, startMinute);

  static DateTime endTime(DateTime day) =>
      DateTime(day.year, day.month, day.day, endHour, endMinute);

  static DateTime lateLimit(DateTime day) =>
      startTime(day).add(Duration(minutes: allowLateMinutes));

  // Kiểm tra xem đã đủ giờ làm việc chưa
  static bool hasCompletedWorkHours(DateTime checkIn, DateTime checkOut) {
    final duration = checkOut.difference(checkIn);
    return duration.inHours >= minWorkHours;
  }
}
