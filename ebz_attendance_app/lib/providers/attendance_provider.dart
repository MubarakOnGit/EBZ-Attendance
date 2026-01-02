import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance_record.dart';
import '../models/user_account.dart';
import '../models/app_rules.dart';
import '../services/firestore_service.dart';
import '../services/wifi_service.dart';

class AttendanceProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final WifiService _wifiService = WifiService();
  
  AttendanceRecord? _todayRecord;
  bool _isLoading = false;
  StreamSubscription? _attendanceSub;

  AttendanceRecord? get todayRecord => _todayRecord;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _attendanceSub?.cancel();
    super.dispose();
  }

  Future<void> loadTodayRecord(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    await _attendanceSub?.cancel();
    
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    _attendanceSub = _firestoreService.getUserAttendance(userId, start, end).listen((records) {
      if (records.isNotEmpty) {
        _todayRecord = records.first;
      } else {
        _todayRecord = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<String?> checkIn(UserAccount user) async {
    _isLoading = true;
    notifyListeners();

    try {
      final rules = await _firestoreService.getRules();
      if (rules != null && rules.isWifiRestrictionEnabled && rules.allowedSsids.isNotEmpty) {
        bool isWifiValid = await _wifiService.validateWifi(rules.allowedSsids);
        if (!isWifiValid) {
          _isLoading = false;
          notifyListeners();
          return 'Access Denied: You must be connected to the Office WiFi ("${rules.allowedSsids.join(', ')}") to check in.';
        }
      }

      final now = DateTime.now();
      final ssid = await _wifiService.getWifiSsid();
      
      AttendanceStatus status = AttendanceStatus.present;
      // Basic late calculation (actual logic would be more complex)
      if (rules != null) {
        final startTime = DateTime(now.year, now.month, now.day, rules.officeStartTime.hour, rules.officeStartTime.minute);
        if (now.isAfter(startTime.add(Duration(minutes: rules.gracePeriodMinutes)))) {
          status = AttendanceStatus.late;
        }
      }

      final record = AttendanceRecord(
        id: const Uuid().v4(),
        userId: user.uid,
        date: now,
        checkIn: now,
        status: status,
        ssid: ssid,
      );

      await _firestoreService.saveAttendance(record);
      _todayRecord = record;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Error: $e';
    }
  }

  // Admin clear status
  Future<void> clearMemberStatus(String userId, DateTime date) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.deleteAttendance(userId, date);
      if (_todayRecord?.userId == userId) {
        _todayRecord = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> checkOut() async {
    if (_todayRecord == null) return 'No active check-in found.';
    
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final updatedRecord = AttendanceRecord(
        id: _todayRecord!.id,
        userId: _todayRecord!.userId,
        date: _todayRecord!.date,
        checkIn: _todayRecord!.checkIn,
        checkOut: now,
        lunchOut: _todayRecord!.lunchOut,
        lunchIn: _todayRecord!.lunchIn,
        status: _todayRecord!.status,
        ssid: _todayRecord!.ssid,
      );

      await _firestoreService.saveAttendance(updatedRecord);
      _todayRecord = updatedRecord;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Error: $e';
    }
  }

  Future<String?> lunchOut() async {
    if (_todayRecord == null) return 'Not checked in.';
    _isLoading = true;
    notifyListeners();
    try {
      final record = AttendanceRecord(
        id: _todayRecord!.id,
        userId: _todayRecord!.userId,
        date: _todayRecord!.date,
        checkIn: _todayRecord!.checkIn,
        lunchOut: DateTime.now(),
        status: _todayRecord!.status,
        ssid: _todayRecord!.ssid,
      );
      await _firestoreService.saveAttendance(record);
      _todayRecord = record;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Error: $e';
    }
  }

  Future<String?> lunchIn() async {
    if (_todayRecord == null || _todayRecord!.lunchOut == null) return 'Lunch break not started.';
    _isLoading = true;
    notifyListeners();
    try {
      final record = AttendanceRecord(
        id: _todayRecord!.id,
        userId: _todayRecord!.userId,
        date: _todayRecord!.date,
        checkIn: _todayRecord!.checkIn,
        lunchOut: _todayRecord!.lunchOut,
        lunchIn: DateTime.now(),
        status: _todayRecord!.status,
        ssid: _todayRecord!.ssid,
      );
      await _firestoreService.saveAttendance(record);
      _todayRecord = record;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Error: $e';
    }
  }
}
