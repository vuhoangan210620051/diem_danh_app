class LateRecord {
  final DateTime timestamp;
  final int minutesLate;

  LateRecord({required this.timestamp, required this.minutesLate});

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp.toIso8601String(),
        "minutesLate": minutesLate,
      };

  factory LateRecord.fromJson(Map<String, dynamic> json) {
    return LateRecord(
      timestamp: DateTime.parse(json["timestamp"]),
      minutesLate: json["minutesLate"],
    );
  }
}
