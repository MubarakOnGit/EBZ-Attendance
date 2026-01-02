import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/attendance_record.dart';
import '../models/user_account.dart';
import 'package:intl/intl.dart';

class ExcelService {
  Future<String?> generateAttendanceReport(List<AttendanceRecord> records, List<UserAccount> users) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Attendance Report'];
      
      // Header
      sheetObject.appendRow([
        TextCellValue('Date'),
        TextCellValue('Employee ID'),
        TextCellValue('Name'),
        TextCellValue('Check In'),
        TextCellValue('Check Out'),
        TextCellValue('Status'),
      ]);

      for (var record in records) {
        final user = users.firstWhere((u) => u.uid == record.userId, orElse: () => UserAccount(
          uid: '', name: 'Unknown', email: '', role: UserRole.member, employeeId: 'N/A', phoneNumber: '', salaryType: SalaryType.monthly, baseSalary: 0, workingDays: []
        ));

        sheetObject.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd').format(record.date)),
          TextCellValue(user.employeeId),
          TextCellValue(user.name),
          TextCellValue(record.checkIn != null ? DateFormat('HH:mm').format(record.checkIn!) : '--'),
          TextCellValue(record.checkOut != null ? DateFormat('HH:mm').format(record.checkOut!) : '--'),
          TextCellValue(record.status.name.toUpperCase()),
        ]);
      }

      var fileBytes = excel.save();
      if (fileBytes == null) return null;

      // In a real mobile app, you'd use path_provider to find a safe place.
      // For this environment, we'll try to save it in a common place.
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/attendance_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
        
      return filePath;
    } catch (e) {
      print('Error generating excel: $e');
      return null;
    }
  }
}
