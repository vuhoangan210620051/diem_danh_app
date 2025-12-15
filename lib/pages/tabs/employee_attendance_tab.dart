import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/employee.dart';
import '../../models/leave_record.dart';
import '../../widgets/common/common_app_header.dart';

class EmployeeAttendanceTab extends StatefulWidget {
  final Employee employee;

  const EmployeeAttendanceTab({super.key, required this.employee});

  @override
  State<EmployeeAttendanceTab> createState() => _EmployeeAttendanceTabState();
}

class _EmployeeAttendanceTabState extends State<EmployeeAttendanceTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Kiểm tra trạng thái của một ngày
  AttendanceStatus _getStatusForDay(DateTime day) {
    final dateStr = "${day.day}/${day.month}/${day.year}";

    // Kiểm tra cuối tuần
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return AttendanceStatus.notChecked;
    }

    // Kiểm tra ngày trong tương lai
    if (day.isAfter(DateTime.now())) {
      return AttendanceStatus.notChecked;
    }

    // Kiểm tra đi muộn
    final isLate = widget.employee.lateHistory.any((record) {
      final recordDate =
          "${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year}";
      return recordDate == dateStr;
    });

    if (isLate) {
      return AttendanceStatus.late;
    }

    // Kiểm tra vắng mặt
    final isAbsent = widget.employee.absentHistory.any((record) {
      return record.date == dateStr;
    });

    if (isAbsent) {
      return AttendanceStatus.absent;
    }

    // Kiểm tra nghỉ phép
    final onLeave = widget.employee.leaveHistory.any((leave) {
      if (leave.status != LeaveStatus.approved) return false;

      try {
        final startDay = DateTime.parse(leave.startDate);
        final endDay = DateTime.parse(leave.endDate);

        return day.isAfter(startDay.subtract(const Duration(days: 1))) &&
            day.isBefore(endDay.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    });

    if (onLeave) {
      return AttendanceStatus.onLeave;
    }

    // Kiểm tra có check-in trong ngày (present)
    // Nếu có lateHistory hoặc lastCheckInDate match thì là đã điểm danh
    if (widget.employee.lastCheckInDate == dateStr) {
      return AttendanceStatus.present;
    }

    // Nếu không có lateHistory, absentHistory, leaveHistory
    // và là ngày trong quá khứ thì coi như chưa có dữ liệu
    return AttendanceStatus.notChecked;
  }

  Color _getColorForDay(DateTime day) {
    final status = _getStatusForDay(day);

    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF10B981); // Xanh lá
      case AttendanceStatus.late:
        return const Color(0xFFF97316); // Cam
      case AttendanceStatus.absent:
        return const Color(0xFFEF4444); // Đỏ
      case AttendanceStatus.onLeave:
        return const Color(0xFF8B5CF6); // Tím
      case AttendanceStatus.notChecked:
        return Colors.grey.shade300; // Xám nhạt
    }
  }

  int _countByStatus(AttendanceStatus status) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    int count = 0;
    for (
      var day = firstDay;
      day.isBefore(lastDay.add(const Duration(days: 1)));
      day = day.add(const Duration(days: 1))
    ) {
      if (_getStatusForDay(day) == status) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const CommonAppHeader(title: "Lịch điểm danh"),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Calendar card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2A3950),
                          ),
                          leftChevronIcon: const Icon(
                            Icons.chevron_left,
                            color: Color(0xFF2A3950),
                          ),
                          rightChevronIcon: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF2A3950),
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: const Color(0xFF2A3950).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xFF2A3950),
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: const TextStyle(fontSize: 14),
                          weekendTextStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            return _buildDayCell(day, false);
                          },
                          selectedBuilder: (context, day, focusedDay) {
                            return _buildDayCell(day, true);
                          },
                          todayBuilder: (context, day, focusedDay) {
                            return _buildDayCell(day, false);
                          },
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Chú thích
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildLegendItem("Đúng giờ", const Color(0xFF10B981)),
                          _buildLegendItem("Đi muộn", const Color(0xFFF97316)),
                          _buildLegendItem("Vắng mặt", const Color(0xFFEF4444)),
                          _buildLegendItem("Cuối tuần", Colors.grey.shade300),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tổng kết tháng
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  "Tổng kết tháng",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_outline,
                      label: "Đúng giờ",
                      value: _countByStatus(
                        AttendanceStatus.present,
                      ).toString(),
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.access_time,
                      label: "Đi muộn",
                      value: _countByStatus(AttendanceStatus.late).toString(),
                      color: const Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.cancel_outlined,
                      label: "Vắng mặt",
                      value: _countByStatus(AttendanceStatus.absent).toString(),
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isSelected) {
    final color = _getColorForDay(day);
    final isToday = isSameDay(day, DateTime.now());

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2A3950) : color,
        borderRadius: BorderRadius.circular(8),
        border: isToday && !isSelected
            ? Border.all(color: const Color(0xFF2A3950), width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isSelected || color != Colors.grey.shade300
                ? Colors.white
                : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
            ),
          ],
        ),
      ),
    );
  }
}
