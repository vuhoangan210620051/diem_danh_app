import '../repositories/employee_repository.dart';
import '../models/employee.dart';

class EmployeeAuthService {
  final EmployeeRepository repo;

  EmployeeAuthService(this.repo);

  Future<Employee?> login(String email, String password) async {
    try {
      final employees = await repo.getEmployees();
      try {
        return employees.firstWhere(
          (e) => e.email == email && e.password == password,
        );
      } catch (_) {
        return null;
      }
    } catch (e) {
      // If fetching employees from remote fails, treat as login failure.
      return null;
    }
  }
}
