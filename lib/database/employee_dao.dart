import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';

class EmployeeDao {
  static const String key = "employees";

  // Lấy danh sách nhân viên
  Future<List<Employee>> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null) return [];

    final List list = jsonDecode(jsonString);
    return list.map((e) => Employee.fromJson(e)).toList();
  }

  // Thêm nhân viên
  Future<void> insertEmployee(Employee e) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getEmployees();

    employees.add(e);

    final jsonString = jsonEncode(employees.map((e) => e.toJson()).toList());
    await prefs.setString(key, jsonString);
  }

  // Xóa nhân viên
  Future<void> deleteEmployee(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getEmployees();

    employees.removeWhere((x) => x.id == id);

    final jsonString =
        jsonEncode(employees.map((e) => e.toJson()).toList());

    await prefs.setString(key, jsonString);
  }
}
