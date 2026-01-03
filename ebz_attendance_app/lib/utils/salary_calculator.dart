import 'package:flutter/material.dart';
import '../models/app_rules.dart';
import '../models/attendance_record.dart';
import '../models/user_account.dart';

class SalarySummary {
  final double baseSalary;
  final double lateDeductions;
  final double lunchDeductions;
  final double totalDeductions;
  final double netSalary;
  final int totalDays;
  final int presentDays;
  final int lateDays;

  SalarySummary({
    required this.baseSalary,
    required this.lateDeductions,
    required this.lunchDeductions,
    required this.totalDeductions,
    required this.netSalary,
    required this.totalDays,
    required this.presentDays,
    required this.lateDays,
  });
}

class SalaryCalculator {
  static SalarySummary calculateMonthlySummary({
    required UserAccount user,
    required AppRules rules,
    required List<AttendanceRecord> records,
    required DateTime month,
  }) {
    double lateDeductions = 0;
    double lunchDeductions = 0;
    int presentDays = 0;
    int lateDays = 0;

    for (var record in records) {
      if (record.status != AttendanceStatus.absent && record.status != AttendanceStatus.offDay) {
        presentDays++;
        
        if (record.status == AttendanceStatus.late) {
          lateDays++;
          if (rules.isDeductionEnabled && record.checkIn != null) {
            final targetStartTime = rules.getStartTimeForDay(record.date.weekday);
            final officeStartTime = DateTime(
              record.date.year,
              record.date.month,
              record.date.day,
              targetStartTime.hour,
              targetStartTime.minute,
            );
            
            final lateMinutes = record.checkIn!.difference(officeStartTime).inMinutes;
            final effectiveLateMinutes = (lateMinutes - rules.gracePeriodMinutes).clamp(0, 1440);
            lateDeductions += effectiveLateMinutes * rules.deductionPerMinute;
          }
        }

        // Lunch Deductions
        if (rules.isLunchDeductionEnabled && record.lunchOut != null && record.lunchIn != null) {
          final lunchDuration = record.lunchIn!.difference(record.lunchOut!).inMinutes;
          if (lunchDuration > rules.lunchLimitMinutes) {
            final excessMinutes = lunchDuration - rules.lunchLimitMinutes;
            lunchDeductions += excessMinutes * rules.deductionPerMinute;
          }
        }
      }
    }

    double calculatedBase = 0;
    switch (user.salaryType) {
      case SalaryType.monthly:
        calculatedBase = user.baseSalary;
        break;
      case SalaryType.daily:
        calculatedBase = user.baseSalary * presentDays;
        break;
      case SalaryType.hourly:
        double totalHours = 0;
        for (var record in records) {
          if (record.checkIn != null && record.checkOut != null) {
            totalHours += record.checkOut!.difference(record.checkIn!).inMinutes / 60;
          }
        }
        calculatedBase = user.baseSalary * totalHours;
        break;
    }

    final totalDeductions = lateDeductions + lunchDeductions;
    final netSalary = (calculatedBase - totalDeductions).clamp(0.0, double.infinity);

    return SalarySummary(
      baseSalary: user.baseSalary,
      lateDeductions: lateDeductions,
      lunchDeductions: lunchDeductions,
      totalDeductions: totalDeductions,
      netSalary: netSalary,
      totalDays: DateTime(month.year, month.month + 1, 0).day,
      presentDays: presentDays,
      lateDays: lateDays,
    );
  }
}
