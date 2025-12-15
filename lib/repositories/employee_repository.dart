import '../models/employee.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getEmployees();
  Stream<List<Employee>> streamEmployees();
  Future<void> addEmployee(Employee e);
  Future<void> deleteEmployee(String id);
  Future<void> updateEmployee(Employee e);
}
