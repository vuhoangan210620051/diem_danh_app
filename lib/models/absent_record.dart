class AbsentRecord {
  final String date; // "2025-12-03"
  final String? reason; // optional

  AbsentRecord({required this.date, this.reason});

  Map<String, dynamic> toJson() => {"date": date, "reason": reason};

  factory AbsentRecord.fromJson(Map<String, dynamic> json) {
    return AbsentRecord(date: json["date"], reason: json["reason"]);
  }


  
}
