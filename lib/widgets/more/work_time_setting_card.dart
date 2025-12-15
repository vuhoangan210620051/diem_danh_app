import 'package:flutter/material.dart';
import '../../config/work_time_config.dart';
import '../../models/work_time_setting.dart';
import '../../repositories/firebase_work_time_repository.dart';

class WorkTimeSettingCard extends StatefulWidget {
  const WorkTimeSettingCard({super.key});

  @override
  State<WorkTimeSettingCard> createState() => _WorkTimeSettingCardState();
}

class _WorkTimeSettingCardState extends State<WorkTimeSettingCard> {
  late TimeOfDay start;
  late TimeOfDay end;
  late TimeOfDay lateTime;

  @override
  void initState() {
    super.initState();
    start = TimeOfDay(
      hour: WorkTimeConfig.startHour,
      minute: WorkTimeConfig.startMinute,
    );
    end = TimeOfDay(
      hour: WorkTimeConfig.endHour,
      minute: WorkTimeConfig.endMinute,
    );
    final startTotal =
        WorkTimeConfig.startHour * 60 + WorkTimeConfig.startMinute;
    final lateTotal = startTotal + WorkTimeConfig.allowLateMinutes;
    lateTime = TimeOfDay(hour: lateTotal ~/ 60, minute: lateTotal % 60);
  }

  Future<void> _pickTime(
    TimeOfDay current,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  String _fmt(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// ===== CARD =====
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE6FBF6),
                    child: Icon(Icons.access_time, color: Color(0xFF2A3950)),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Giờ làm việc",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// GIỜ VÀO / RA
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: "Giờ vào",
                      value: _fmt(start),
                      onTap: () => _pickTime(start, (v) => start = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: "Giờ ra",
                      value: _fmt(end),
                      onTap: () => _pickTime(end, (v) => end = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// GIỜ TÍNH MUỘN
              _TimeField(
                label: "Thời gian tính muộn",
                value: _fmt(lateTime),
                helper: "Sau giờ này sẽ tính là đi muộn",
                onTap: () => _pickTime(lateTime, (v) => lateTime = v),
              ),
            ],
          ),
        ),

        /// ===== SAVE BUTTON =====
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text("Lưu cài đặt"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A3950),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ===== SAVE =====
  Future<void> _save() async {
    final repo = FirebaseWorkTimeRepository();
    final setting = WorkTimeSetting(
      startHour: start.hour,
      startMinute: start.minute,
      endHour: end.hour,
      endMinute: end.minute,
      allowLateMinutes:
          (lateTime.hour * 60 + lateTime.minute) -
          (start.hour * 60 + start.minute),
    );

    // 1️⃣ LƯU FIREBASE (đồng bộ tất cả thiết bị)
    await repo.saveSetting(setting);

    // 2️⃣ ÁP DỤNG NGAY CHO THIẾT BỊ NÀY
    WorkTimeConfig.applyFromSetting(setting);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Đã lưu giờ làm việc")));
  }
}

/// ===== TIME FIELD =====
class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextField(
              decoration: InputDecoration(
                hintText: value,
                suffixIcon: const Icon(Icons.access_time),
                filled: true,
                fillColor: const Color(0xFFF5F7F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}
