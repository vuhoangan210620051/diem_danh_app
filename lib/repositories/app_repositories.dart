import 'firebase_work_time_repository.dart';
import 'firebase_employee_repository.dart';
import '../repositories/employee_repository.dart';
import '../repositories/work_time_repository.dart';

class AppRepositories {
  // Provide a lazy getter so we don't instantiate Firebase-backed
  // repositories before Firebase.initializeApp() has completed.
  // If you need a singleton instance, replace the getter with a
  // late-initialized field set after initialization.
  static EmployeeRepository get employeeRepo => FirebaseEmployeeRepository();

  static WorkTimeRepository get workTimeRepo => FirebaseWorkTimeRepository();
}
