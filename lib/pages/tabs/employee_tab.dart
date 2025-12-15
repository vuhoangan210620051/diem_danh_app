import 'package:flutter/material.dart';
import '../../widgets/employee/employee_card.dart';
import '../../widgets/employee/employee_header.dart';
import '../../models/employee.dart';
import '../../repositories/employee_repository.dart';

class EmployeeTab extends StatefulWidget {
  final EmployeeRepository repo;
  final List<Employee> employees;

  const EmployeeTab({super.key, required this.repo, required this.employees});

  @override
  State<EmployeeTab> createState() => _EmployeeTabState();
}

class _EmployeeTabState extends State<EmployeeTab>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  void updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _handleRefresh() async {
    // Reload employees from repository
    await widget.repo.getEmployees();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tải lại danh sách nhân viên'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  List<Employee> get _filteredEmployees {
    if (_searchQuery.isEmpty) {
      return widget.employees;
    }
    final query = _searchQuery.toLowerCase();
    return widget.employees.where((emp) {
      return emp.name.toLowerCase().contains(query) ||
          emp.id.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: EmployeeHeader(repo: widget.repo),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: const Color(0xFF2A3950),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Thanh tìm kiếm
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Color(0xFF757575)),
                      hintText: "Tìm kiếm nhân viên theo tên hoặc ID...",
                      hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                    ),
                  ),
                ),
                if (_filteredEmployees.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Không tìm thấy nhân viên',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  )
                else
                  for (final emp in _filteredEmployees)
                    EmployeeCard(
                      emp: emp,
                      onDelete: () async {
                        await widget.repo.deleteEmployee(emp.id);
                        // StreamBuilder tự động cập nhật
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
