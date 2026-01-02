import '../models/attendance_record.dart';
import '../models/app_rules.dart';
import '../models/user_account.dart';

class SalaryEngine {
  static double calculateDailySalary({
    required AttendanceRecord record,
    required UserAccount user,
    required AppRules rules,
  }) {
    if (record.status == AttendanceStatus.absent || record.status == AttendanceStatus.offDay) {
      return 0.0;
    }

    double baseDailySalary = 0.0;
    if (user.salaryType == SalaryType.monthly) {
      baseDailySalary = user.baseSalary / 30; // Simplified
    } else if (user.salaryType == SalaryType.daily) {
      baseDailySalary = user.baseSalary;
    } else {
      // Hourly logic could be more complex
      baseDailySalary = user.baseSalary * 8; 
    }

    double deductions = calculateDeductions(record: record, rules: rules);
    
    double netSalary = baseDailySalary - deductions;
    return netSalary < 0 ? 0 : netSalary;
  }

  static double calculateDeductions({
    required AttendanceRecord record,
    required AppRules rules,
  }) {
    double totalDeduction = 0.0;

    if (record.checkIn != null) {
      final startTime = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
        rules.officeStartTime.hour,
        rules.officeStartTime.minute,
      );

      if (record.checkIn!.isAfter(startTime.add(Duration(minutes: rules.gracePeriodMinutes)))) {
        final lateMinutes = record.checkIn!.difference(startTime).inMinutes;
        totalDeduction += lateMinutes * rules.deductionPerMinute;
      }
    }

    if (record.checkOut != null) {
      final endTime = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
        rules.officeEndTime.hour,
        rules.officeEndTime.minute,
      );

      if (record.checkOut!.isBefore(endTime)) {
        final earlyMinutes = endTime.difference(record.checkOut!).inMinutes;
        totalDeduction += earlyMinutes * rules.deductionPerMinute;
      }
    }

    return totalDeduction;
  }

  static Duration calculateWorkedHours(AttendanceRecord record) {
    if (record.checkIn == null || record.checkOut == null) return Duration.zero;
    
    Duration totalBreak = Duration.zero;
    if (record.lunchOut != null && record.lunchIn != null) {
      totalBreak = record.lunchIn!.difference(record.lunchOut!);
    }
    
    return record.checkOut!.difference(record.checkIn!) - totalBreak;
  }
}
