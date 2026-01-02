import 'package:flutter/material.dart';

class AppRules {
  final List<String> allowedSsids;
  final List<String> allowedBssids;
  final int gracePeriodMinutes;
  final double deductionPerMinute;
  final TimeOfDay officeStartTime;
  final TimeOfDay officeEndTime;
  final TimeOfDay lunchStartTime;
  final TimeOfDay lunchEndTime;
  final bool isWifiRestrictionEnabled;
  final bool isOvertimeEnabled;
  final bool isDeductionEnabled;
  final bool isLunchDeductionEnabled;
  final int lunchLimitMinutes;
  final Map<int, DaySchedule> weeklySchedule; // 1 = Monday, 7 = Sunday

  AppRules({
    required this.allowedSsids,
    required this.allowedBssids,
    required this.gracePeriodMinutes,
    required this.deductionPerMinute,
    required this.officeStartTime,
    required this.officeEndTime,
    required this.lunchStartTime,
    required this.lunchEndTime,
    this.isWifiRestrictionEnabled = false,
    this.isOvertimeEnabled = false,
    this.isDeductionEnabled = false,
    this.isLunchDeductionEnabled = false,
    this.lunchLimitMinutes = 60,
    required this.weeklySchedule,
  });

  Map<String, dynamic> toMap() {
    return {
      'allowedSsids': allowedSsids,
      'allowedBssids': allowedBssids,
      'gracePeriodMinutes': gracePeriodMinutes,
      'deductionPerMinute': deductionPerMinute,
      'officeStartTime': '${officeStartTime.hour}:${officeStartTime.minute}',
      'officeEndTime': '${officeEndTime.hour}:${officeEndTime.minute}',
      'lunchStartTime': '${lunchStartTime.hour}:${lunchStartTime.minute}',
      'lunchEndTime': '${lunchEndTime.hour}:${lunchEndTime.minute}',
      'isWifiRestrictionEnabled': isWifiRestrictionEnabled,
      'isOvertimeEnabled': isOvertimeEnabled,
      'isDeductionEnabled': isDeductionEnabled,
      'isLunchDeductionEnabled': isLunchDeductionEnabled,
      'lunchLimitMinutes': lunchLimitMinutes,
      'weeklySchedule': weeklySchedule.map((key, value) => MapEntry(key.toString(), value.toMap())),
    };
  }

  factory AppRules.fromMap(Map<String, dynamic> map) {
    TimeOfDay parseTime(String time) {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return AppRules(
      allowedSsids: List<String>.from(map['allowedSsids'] ?? []),
      allowedBssids: List<String>.from(map['allowedBssids'] ?? []),
      gracePeriodMinutes: map['gracePeriodMinutes'] ?? 0,
      deductionPerMinute: (map['deductionPerMinute'] ?? 0).toDouble(),
      officeStartTime: parseTime(map['officeStartTime'] ?? '09:00'),
      officeEndTime: parseTime(map['officeEndTime'] ?? '18:00'),
      lunchStartTime: parseTime(map['lunchStartTime'] ?? '13:00'),
      lunchEndTime: parseTime(map['lunchEndTime'] ?? '14:00'),
      isWifiRestrictionEnabled: map['isWifiRestrictionEnabled'] ?? false,
      isOvertimeEnabled: map['isOvertimeEnabled'] ?? false,
      isDeductionEnabled: map['isDeductionEnabled'] ?? false,
      isLunchDeductionEnabled: map['isLunchDeductionEnabled'] ?? false,
      lunchLimitMinutes: map['lunchLimitMinutes'] ?? 60,
      weeklySchedule: (map['weeklySchedule'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(int.parse(key), DaySchedule.fromMap(value)),
      ),
    );
  }
}

class DaySchedule {
  final bool isWorkDay;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  DaySchedule({
    required this.isWorkDay,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'isWorkDay': isWorkDay,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
    };
  }

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    TimeOfDay parseTime(String time) {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return DaySchedule(
      isWorkDay: map['isWorkDay'] ?? true,
      startTime: parseTime(map['startTime'] ?? '09:00'),
      endTime: parseTime(map['endTime'] ?? '18:00'),
    );
  }
}
