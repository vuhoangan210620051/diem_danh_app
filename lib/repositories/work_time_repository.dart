import '../models/work_time_setting.dart';

abstract class WorkTimeRepository {
  Future<WorkTimeSetting> getSetting();
  Future<void> saveSetting(WorkTimeSetting setting);
}
