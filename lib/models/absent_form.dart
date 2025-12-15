enum LeaveStatus {
  pending, // Chờ duyệt
  approved, // Đã duyệt
  rejected, // Từ chối
}

class LeaveRequest {
  final String employeeName;
  final DateTime fromDate;
  final DateTime toDate;
  final LeaveStatus status;

  LeaveRequest({
    required this.employeeName,
    required this.fromDate,
    required this.toDate,
    required this.status,
  });
}
