class CustomNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationTarget target;
  final String? targetValue; // department name hoặc employee ID
  final String? senderId; // ID của admin gửi
  final String? senderName; // Tên admin gửi

  CustomNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.target,
    this.targetValue,
    this.senderId,
    this.senderName,
  });

  factory CustomNotification.fromJson(Map<String, dynamic> json) {
    return CustomNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      target: NotificationTarget.values.firstWhere(
        (e) => e.name == json['target'],
        orElse: () => NotificationTarget.all,
      ),
      targetValue: json['targetValue'],
      senderId: json['senderId'],
      senderName: json['senderName'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'target': target.name,
    'targetValue': targetValue,
    'senderId': senderId,
    'senderName': senderName,
  };

  bool isForEmployee(String employeeId, String employeeDept) {
    switch (target) {
      case NotificationTarget.all:
        return true;
      case NotificationTarget.department:
        return employeeDept == targetValue;
      case NotificationTarget.specific:
        return employeeId == targetValue;
    }
  }
}

enum NotificationTarget {
  all, // Tất cả nhân viên
  department, // Theo phòng ban
  specific, // Người cụ thể
}

extension NotificationTargetX on NotificationTarget {
  String get label {
    switch (this) {
      case NotificationTarget.all:
        return "Tất cả nhân viên";
      case NotificationTarget.department:
        return "Theo phòng ban";
      case NotificationTarget.specific:
        return "Người cụ thể";
    }
  }
}
