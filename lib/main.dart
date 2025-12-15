// import 'package:flutter/material.dart';
// import 'auth/login_page.dart';
// import '../../repositories/local_work_time_repository.dart';
// import 'config/work_time_config.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final workTimeRepo = LocalWorkTimeRepository();
//   final setting = await workTimeRepo.getSetting();

//   // ✅ CHỈ APPLY KHI CÓ SETTING
//   WorkTimeConfig.applyFromSetting(setting);

//   runApp(const AttendanceApp());
// }

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'auth/login_page.dart';
import 'config/work_time_config.dart';
import 'models/work_time_setting.dart';
import 'repositories/firebase_work_time_repository.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo local notifications cho Android
  if (!kIsWeb && Platform.isAndroid) {
    await LocalNotificationService.initialize();
  }

  //  ĐẢM BẢO AUTH TRƯỚC KHI ĐỤNG FIRESTORE
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  // 🔥 LOAD GIỜ LÀM TỪ FIREBASE
  try {
    final repo = FirebaseWorkTimeRepository();
    final setting = await repo.getSetting().timeout(
      const Duration(seconds: 5),
      onTimeout: () => WorkTimeSetting(
        startHour: 8,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        allowLateMinutes: 15,
      ),
    );
    WorkTimeConfig.applyFromSetting(setting);

    // 🔄 LẮNG NGHE REALTIME CHANGES
    repo.streamSetting().listen((newSetting) {
      WorkTimeConfig.applyFromSetting(newSetting);
    });
  } catch (_) {
    WorkTimeConfig.applyFromSetting(
      WorkTimeSetting(
        startHour: 8,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        allowLateMinutes: 15,
      ),
    );
  }

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Điểm danh nhân viên',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: const LoginPage(),
    );
  }
}
