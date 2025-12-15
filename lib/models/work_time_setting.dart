class WorkTimeSetting {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int allowLateMinutes;

  WorkTimeSetting({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.allowLateMinutes,
  });

  Map<String, dynamic> toJson() => {
    "startHour": startHour,
    "startMinute": startMinute,
    "endHour": endHour,
    "endMinute": endMinute,
    "allowLateMinutes": allowLateMinutes,
  };

  factory WorkTimeSetting.fromJson(Map<String, dynamic> json) {
    return WorkTimeSetting(
      startHour: json["startHour"],
      startMinute: json["startMinute"],
      endHour: json["endHour"],
      endMinute: json["endMinute"],
      allowLateMinutes: json["allowLateMinutes"],
    );
  }
}
