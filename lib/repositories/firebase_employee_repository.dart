import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import 'employee_repository.dart';

class FirebaseEmployeeRepository implements EmployeeRepository {
  final CollectionReference _col = FirebaseFirestore.instance.collection(
    'employees',
  );

  @override
  Future<void> addEmployee(Employee e) async {
    await _col.doc(e.id).set(e.toJson());
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await _col.doc(id).delete();
  }

  @override
  Future<List<Employee>> getEmployees() async {
    final snap = await _col.get();
    return snap.docs
        .map((d) => Employee.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<Employee>> streamEmployees() {
    return _col.snapshots().map((snap) {
      return snap.docs
          .map((d) => Employee.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<void> updateEmployee(Employee e) async {
    await _col.doc(e.id).set(e.toJson());
  }
}
