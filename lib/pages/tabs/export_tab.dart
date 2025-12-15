import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/employee.dart';
import '../../repositories/employee_repository.dart';
import '../../theme/app_colors.dart';
import 'package:universal_html/html.dart' as html;

class ExportTab extends StatefulWidget {
  final EmployeeRepository repo;
  final List<Employee> employees;

  const ExportTab({super.key, required this.repo, required this.employees});

  @override
  State<ExportTab> createState() => _ExportTabState();
}

class _ExportTabState extends State<ExportTab> {
  DateTime? startDate;
  DateTime? endDate;
  bool isExporting = false;
  String exportMode = 'all'; // 'all' hoặc 'selected'
  Set<String> selectedEmployeeIds = {};

  // Các cột có thể xuất
  Map<String, bool> exportColumns = {
    'stt': true,
    'name': true,
    'id': true,
    'email': true,
    'gender': true,
    'workDays': true,
    'absentDays': true,
    'leaveDays': true,
    'lateDays': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xuất báo cáo Excel',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF1FAF6),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card chứa form
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon và tiêu đề
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.file_download,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xuất báo cáo chấm công',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Chọn khoảng thời gian để xuất dữ liệu',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Chọn nhân viên
                        const Text(
                          'Nhân viên',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: exportMode,
                          onChanged: (value) {
                            setState(() {
                              exportMode = value!;
                              if (exportMode == 'all') {
                                selectedEmployeeIds.clear();
                              }
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF5F7F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Row(
                                children: [
                                  Icon(Icons.people, size: 20),
                                  SizedBox(width: 12),
                                  Text('Tất cả nhân viên'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'selected',
                              child: Row(
                                children: [
                                  Icon(Icons.person_search, size: 20),
                                  SizedBox(width: 12),
                                  Text('Chọn nhân viên'),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (exportMode == 'selected') ...[
                          const SizedBox(height: 16),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedEmployeeIds.isNotEmpty
                                    ? AppColors.primary.withValues(alpha: 0.3)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Header với chọn tất cả
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value:
                                            selectedEmployeeIds.length ==
                                            widget.employees.length,
                                        tristate: true,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              selectedEmployeeIds = widget
                                                  .employees
                                                  .map((e) => e.id)
                                                  .toSet();
                                            } else {
                                              selectedEmployeeIds.clear();
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Chọn tất cả (${selectedEmployeeIds.length}/${widget.employees.length})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                // Danh sách nhân viên
                                Expanded(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: widget.employees.length,
                                    itemBuilder: (context, index) {
                                      final emp = widget.employees[index];
                                      final isSelected = selectedEmployeeIds
                                          .contains(emp.id);
                                      return CheckboxListTile(
                                        dense: true,
                                        value: isSelected,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              selectedEmployeeIds.add(emp.id);
                                            } else {
                                              selectedEmployeeIds.remove(
                                                emp.id,
                                              );
                                            }
                                          });
                                        },
                                        title: Text(
                                          emp.name,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          '${emp.id} • ${emp.dept}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Ngày bắt đầu
                        const Text(
                          'Ngày bắt đầu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: startDate != null
                                    ? AppColors.primary.withValues(alpha: 0.3)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: startDate != null
                                      ? AppColors.primary
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  startDate != null
                                      ? '${startDate!.day.toString().padLeft(2, '0')}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.year}'
                                      : 'Chọn ngày bắt đầu',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: startDate != null
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Ngày kết thúc
                        const Text(
                          'Ngày kết thúc',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: endDate != null
                                    ? AppColors.primary.withValues(alpha: 0.3)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: endDate != null
                                      ? AppColors.primary
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  endDate != null
                                      ? '${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}'
                                      : 'Chọn ngày kết thúc',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: endDate != null
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Nút xuất file
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                (startDate != null &&
                                    endDate != null &&
                                    !isExporting &&
                                    (exportMode == 'all' ||
                                        selectedEmployeeIds.isNotEmpty))
                                ? _exportToExcel
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isExporting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.download, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Xuất file Excel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        if (startDate == null ||
                            endDate == null ||
                            (exportMode == 'selected' &&
                                selectedEmployeeIds.isEmpty))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              startDate == null || endDate == null
                                  ? 'Vui lòng chọn cả ngày bắt đầu và kết thúc'
                                  : 'Vui lòng chọn ít nhất 1 nhân viên',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Thông tin thêm
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.checklist,
                              size: 20,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chọn thông tin xuất',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildColumnCheckbox('STT', 'stt'),
                            _buildColumnCheckbox('Tên', 'name'),
                            _buildColumnCheckbox('ID', 'id'),
                            _buildColumnCheckbox('Email', 'email'),
                            _buildColumnCheckbox('Giới tính', 'gender'),
                            _buildColumnCheckbox('Đi làm', 'workDays'),
                            _buildColumnCheckbox('Vắng', 'absentDays'),
                            _buildColumnCheckbox('Nghỉ phép', 'leaveDays'),
                            _buildColumnCheckbox('Trễ', 'lateDays'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnCheckbox(String label, String key) {
    return InkWell(
      onTap: () {
        setState(() {
          exportColumns[key] = !exportColumns[key]!;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: exportColumns[key]!
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: exportColumns[key]!
                ? AppColors.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exportColumns[key]!
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              size: 18,
              color: exportColumns[key]! ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: exportColumns[key]!
                    ? AppColors.primary
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (startDate ?? DateTime.now())
          : (endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate != null && picked.isAfter(endDate!)) {
            endDate = null;
          }
        } else {
          if (startDate != null && picked.isBefore(startDate!)) {
            _showSnackBar('Ngày kết thúc phải sau ngày bắt đầu');
            return;
          }
          endDate = picked;
        }
      });
    }
  }

  Future<void> _exportToExcel() async {
    if (startDate == null || endDate == null) return;
    if (exportMode == 'selected' && selectedEmployeeIds.isEmpty) return;

    setState(() => isExporting = true);

    try {
      // Lọc danh sách nhân viên theo chế độ
      final employeesToExport = exportMode == 'all'
          ? widget.employees
          : widget.employees
                .where((emp) => selectedEmployeeIds.contains(emp.id))
                .toList();

      final excel = Excel.createExcel();
      final sheet = excel['Báo cáo chấm công'];

      // Style cho header
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#2A3950'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Header row - chỉ các cột được chọn
      final allHeaders = {
        'stt': 'STT',
        'name': 'TÊN',
        'id': 'ID',
        'email': 'EMAIL',
        'gender': 'GIỚI TÍNH',
        'workDays': 'SỐ NGÀY ĐI LÀM',
        'absentDays': 'SỐ NGÀY NGHỈ KHÔNG PHÉP',
        'leaveDays': 'SỐ NGÀY NGHỈ CÓ PHÉP',
        'lateDays': 'SỐ NGÀY TRỄ',
      };

      final headers = <String>[];
      final selectedKeys = <String>[];

      exportColumns.forEach((key, isSelected) {
        if (isSelected) {
          headers.add(allHeaders[key]!);
          selectedKeys.add(key);
        }
      });

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Data rows
      for (var i = 0; i < employeesToExport.length; i++) {
        final emp = employeesToExport[i];
        final rowIndex = i + 1;

        // Tính toán số liệu trong khoảng thời gian
        final workDays = _countWorkDays(emp);
        final absentDays = _countAbsentDays(emp);
        final leaveDays = _countLeaveDays(emp);
        final lateDays = _countLateDays(emp);

        final allData = {
          'stt': (i + 1).toString(),
          'name': emp.name,
          'id': emp.id,
          'email': emp.email,
          'gender': emp.gender ?? '',
          'workDays': workDays.toString(),
          'absentDays': absentDays.toString(),
          'leaveDays': leaveDays.toString(),
          'lateDays': lateDays.toString(),
        };

        final rowData = selectedKeys.map((key) => allData[key]!).toList();

        for (var j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);

          final key = selectedKeys[j];
          // Style cho các ô dữ liệu
          cell.cellStyle = CellStyle(
            horizontalAlign:
                key == 'stt' ||
                    key == 'workDays' ||
                    key == 'absentDays' ||
                    key == 'leaveDays' ||
                    key == 'lateDays'
                ? HorizontalAlign.Center
                : HorizontalAlign.Left,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }

      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        final key = selectedKeys[i];
        if (key == 'name') {
          sheet.setColumnWidth(i, 25);
        } else if (key == 'email') {
          sheet.setColumnWidth(i, 30);
        } else {
          sheet.setColumnWidth(i, 15);
        }
      }

      // Save file
      final bytes = excel.encode();
      if (bytes != null) {
        final fileName =
            'BaoCaoChamCong_${startDate!.day.toString().padLeft(2, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.year}_${endDate!.day.toString().padLeft(2, '0')}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.year}.xlsx';

        if (kIsWeb) {
          // Web: Download file
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          _showSnackBar('Xuất file thành công!');
        } else {
          // Mobile/Desktop: Lưu vào Downloads folder
          try {
            Directory? directory;
            if (Platform.isAndroid) {
              // Android: Lưu vào Downloads
              directory = Directory('/storage/emulated/0/Download');
              if (!await directory.exists()) {
                directory = await getExternalStorageDirectory();
              }
            } else {
              // iOS/Desktop: Lưu vào Documents
              directory = await getApplicationDocumentsDirectory();
            }

            if (directory != null) {
              final filePath = '${directory.path}/$fileName';
              final file = File(filePath);
              await file.writeAsBytes(bytes);
              _showSnackBar('Đã lưu file: $filePath');
            } else {
              _showSnackBar('Không thể tìm thư mục lưu file');
            }
          } catch (e) {
            _showSnackBar('Lỗi lưu file: $e');
          }
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi: ${e.toString()}');
    } finally {
      setState(() => isExporting = false);
    }
  }

  int _countWorkDays(Employee emp) {
    if (startDate == null || endDate == null) return 0;

    int count = 0;
    DateTime current = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
    );
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // Tìm check-in và check-out trong ngày này
      final checkIns = emp.checkInHistory.where((record) {
        final recordDate = DateTime(
          record.timestamp.year,
          record.timestamp.month,
          record.timestamp.day,
        );
        return recordDate.isAtSameMomentAs(current);
      }).toList();

      final checkOuts = emp.checkOutHistory.where((record) {
        final recordDate = DateTime(
          record.timestamp.year,
          record.timestamp.month,
          record.timestamp.day,
        );
        return recordDate.isAtSameMomentAs(current);
      }).toList();

      // Chỉ tính nếu có cả check-in và check-out, và đủ giờ làm việc
      if (checkIns.isNotEmpty && checkOuts.isNotEmpty) {
        final checkIn = checkIns.first.timestamp;
        final checkOut = checkOuts.last.timestamp; // Lấy check-out cuối cùng

        // Kiểm tra đã đủ giờ làm việc chưa (mặc định 8 giờ)
        final workDuration = checkOut.difference(checkIn);
        if (workDuration.inHours >= 8) {
          count++;
        }
      }

      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  int _countAbsentDays(Employee emp) {
    if (startDate == null || endDate == null) return 0;

    return emp.absentHistory.where((record) {
      final date = _parseDate(record.date);
      if (date == null) return false;
      return (date.isAfter(startDate!) || date.isAtSameMomentAs(startDate!)) &&
          (date.isBefore(endDate!) || date.isAtSameMomentAs(endDate!));
    }).length;
  }

  int _countLeaveDays(Employee emp) {
    if (startDate == null || endDate == null) return 0;

    int count = 0;
    for (var record in emp.leaveHistory) {
      if (record.status != 'Đã duyệt') continue;

      final start = DateTime.parse(record.startDate);
      final end = DateTime.parse(record.endDate);

      // Tính số ngày nghỉ trong khoảng thời gian
      DateTime current = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);

      while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
        if ((current.isAfter(startDate!) ||
                current.isAtSameMomentAs(startDate!)) &&
            (current.isBefore(this.endDate!) ||
                current.isAtSameMomentAs(this.endDate!))) {
          count++;
        }
        current = current.add(const Duration(days: 1));
      }
    }

    return count;
  }

  int _countLateDays(Employee emp) {
    if (startDate == null || endDate == null) return 0;

    return emp.lateHistory.where((record) {
      final timestamp = record.timestamp;
      return (timestamp.isAfter(startDate!) ||
              timestamp.isAtSameMomentAs(startDate!)) &&
          (timestamp.isBefore(endDate!) ||
              timestamp.isAtSameMomentAs(endDate!));
    }).length;
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (e) {
      return null;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
