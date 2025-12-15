import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/employee.dart';
import '../repositories/employee_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalEmployeeRepository implements EmployeeRepository {
  static const String key = "employees";

  @override
  Future<List<Employee>> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key) ?? "[]";
    final List decoded = jsonDecode(raw);

    return decoded.map((e) => Employee.fromJson(e)).toList();
  }

  @override
  Future<void> addEmployee(Employee e) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getEmployees();

    employees.add(e);

    await prefs.setString(
      key,
      jsonEncode(employees.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> deleteEmployee(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getEmployees();

    employees.removeWhere((e) => e.id == id);

    await prefs.setString(
      key,
      jsonEncode(employees.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> updateEmployee(Employee e) async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getEmployees();

    final index = employees.indexWhere((x) => x.id == e.id);
    if (index == -1) return;

    employees[index] = e;

    await prefs.setString(
      key,
      jsonEncode(employees.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Stream<List<Employee>> streamEmployees() {
    // Local không có realtime, trả về stream từ Future
    return Stream.fromFuture(getEmployees());
  }
}

class EmployeeLocalRepo implements EmployeeRepository {
  static EmployeeLocalRepo? _instance;
  late File dbFile;

  EmployeeLocalRepo._();

  static Future<EmployeeLocalRepo> create() async {
    // tránh khởi tạo nhiều lần
    if (_instance != null) return _instance!;

    final repo = EmployeeLocalRepo._();
    await repo._init();
    _instance = repo;
    return repo;
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    dbFile = File("${dir.path}/employees.json");

    if (!await dbFile.exists()) {
      await dbFile.writeAsString(jsonEncode([]));
    }
  }

  @override
  Future<List<Employee>> getEmployees() async {
    final text = await dbFile.readAsString();
    final list = jsonDecode(text) as List;
    return list.map((e) => Employee.fromJson(e)).toList();
  }

  @override
  Future<void> addEmployee(Employee e) async {
    final list = await getEmployees();
    list.add(e);

    await dbFile.writeAsString(
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> deleteEmployee(String id) async {
    final list = await getEmployees();
    list.removeWhere((e) => e.id == id);

    await dbFile.writeAsString(
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> updateEmployee(Employee e) async {
    final list = await getEmployees();
    final index = list.indexWhere((x) => x.id == e.id);
    if (index == -1) return;

    list[index] = e;

    await dbFile.writeAsString(
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Stream<List<Employee>> streamEmployees() {
    // Local không có realtime, trả về stream từ Future
    return Stream.fromFuture(getEmployees());
  }
}
