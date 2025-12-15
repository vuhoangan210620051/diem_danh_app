import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/work_time_setting.dart';
import 'work_time_repository.dart';

class LocalWorkTimeRepository implements WorkTimeRepository {
  static const _key = "work_time_setting";

  @override
  Future<WorkTimeSetting> getSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null) {
      // DEFAULT
      return WorkTimeSetting(
        startHour: 8,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        allowLateMinutes: 15,
      );
    }

    return WorkTimeSetting.fromJson(jsonDecode(raw));
  }

  @override
  Future<void> saveSetting(WorkTimeSetting setting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(setting.toJson()));
  }
}
