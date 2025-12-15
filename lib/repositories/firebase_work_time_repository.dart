// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/work_time_setting.dart';
// import 'work_time_repository.dart';

// class FirebaseWorkTimeRepository implements WorkTimeRepository {
//   final _doc =
//       FirebaseFirestore.instance.collection('config').doc('work_time');

//   @override
//   Future<WorkTimeSetting> getSetting() async {
//     final snap = await _doc.get();

//     if (!snap.exists) {
//       final def = WorkTimeSetting(
//         startHour: 8,
//         startMinute: 0,
//         endHour: 17,
//         endMinute: 0,
//         allowLateMinutes: 15,
//       );
//       await saveSetting(def);
//       return def;
//     }

//     return WorkTimeSetting.fromJson(snap.data()!);
//   }

//   @override
//   Future<void> saveSetting(WorkTimeSetting setting) async {
//     await _doc.set(setting.toJson());
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/work_time_setting.dart';
import 'work_time_repository.dart';

class FirebaseWorkTimeRepository implements WorkTimeRepository {
  final _doc = FirebaseFirestore.instance.collection('config').doc('work_time');

  // 🔹 DÙNG CHO INIT APP (main.dart)
  @override
  Future<WorkTimeSetting> getSetting() async {
    final snap = await _doc.get();

    if (!snap.exists) {
      final def = WorkTimeSetting(
        startHour: 8,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        allowLateMinutes: 15,
      );
      await saveSetting(def);
      return def;
    }

    return WorkTimeSetting.fromJson(snap.data()!);
  }

  // 🔥 DÙNG CHO REALTIME UI
  Stream<WorkTimeSetting> streamSetting() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) {
        return WorkTimeSetting(
          startHour: 8,
          startMinute: 0,
          endHour: 17,
          endMinute: 0,
          allowLateMinutes: 15,
        );
      }
      return WorkTimeSetting.fromJson(snap.data()!);
    });
  }

  @override
  Future<void> saveSetting(WorkTimeSetting setting) async {
    await _doc.set(setting.toJson());
  }
}
