import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';

class EmployeeDao {
  static const String key = "employees";

  Future<List<Employee>> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null) return [];
    final List list = jsonDecode(jsonString);

    return list.map((e) => Employee.fromJson(e)).toList();
  }

  Future<void> insertEmployee(Employee e) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getEmployees();

    employees.add(e);

    await prefs.setString(
      key,
      jsonEncode(employees.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteEmployee(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getEmployees();

    employees.removeWhere((e) => e.id == id);

    await prefs.setString(
      key,
      jsonEncode(employees.map((e) => e.toJson()).toList()),
    );
  }
}
