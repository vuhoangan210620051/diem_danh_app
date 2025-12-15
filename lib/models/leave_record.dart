import 'package:flutter/material.dart';

enum LeaveStatus { all, pending, approved, rejected }

extension LeaveStatusX on LeaveStatus {
  String get label {
    switch (this) {
      case LeaveStatus.all:
        return "Tất cả";
      case LeaveStatus.pending:
        return "Chờ duyệt";
      case LeaveStatus.approved:
        return "Đã duyệt";
      case LeaveStatus.rejected:
        return "Từ chối";
    }
  }

  Color get bgColor {
    switch (this) {
      case LeaveStatus.all:
        return const Color(0xFF2A3950);
      case LeaveStatus.pending:
        return const Color(0xFFFFF3CD);
      case LeaveStatus.approved:
        return const Color(0xFFE6F7EE);
      case LeaveStatus.rejected:
        return const Color(0xFFFFE5E5);
    }
  }

  Color get textColor {
    switch (this) {
      case LeaveStatus.all:
        return Colors.white;
      case LeaveStatus.pending:
        return const Color(0xFFB78103);
      case LeaveStatus.approved:
        return const Color(0xFF1E9E61);
      case LeaveStatus.rejected:
        return const Color(0xFFD92D20);
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveStatus.all:
        return Icons.list_alt;
      case LeaveStatus.pending:
        return Icons.access_time;
      case LeaveStatus.approved:
        return Icons.check_circle;
      case LeaveStatus.rejected:
        return Icons.cancel;
    }
  }
}

class LeaveRecord {
  final String type;
  final String startDate;
  final String endDate;
  final String reason;
  final LeaveStatus status;
  final int days; // 3

  LeaveRecord({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.days,
  });
  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    return LeaveRecord(
      type: json["type"] ?? "",
      startDate: json["startDate"] ?? "",
      endDate: json["endDate"] ?? "",
      reason: json["reason"] ?? "",
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == json["status"],
        orElse: () => LeaveStatus.pending, // 👈 fallback
      ),
      days: json["days"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "type": type,
    "startDate": startDate,
    "endDate": endDate,
    "reason": reason,
    "status": status.name,
    "days": days,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveRecord &&
        other.type == type &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.reason == reason &&
        other.status == status &&
        other.days == days;
  }

  @override
  int get hashCode {
    return Object.hash(type, startDate, endDate, reason, status, days);
  }
}
