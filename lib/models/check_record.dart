class CheckRecord {
  final DateTime timestamp;
  final String type; // 'in' hoặc 'out'

  CheckRecord({required this.timestamp, required this.type});

  Map<String, dynamic> toJson() => {
    "timestamp": timestamp.toIso8601String(),
    "type": type,
  };

  factory CheckRecord.fromJson(Map<String, dynamic> json) {
    return CheckRecord(
      timestamp: DateTime.parse(json["timestamp"]),
      type: json["type"],
    );
  }
}
