import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/excel_service.dart';
import '../models/attendance_record.dart';
import '../models/user_account.dart';

class ReportProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ExcelService _excelService = ExcelService();

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  Future<String?> exportMonthlyReport(DateTime month) async {
    _isExporting = true;
    notifyListeners();

    try {
      // Logic to fetch all records for the month and all users
      // This is a simplified version
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0);
      
      // We'd need a way to get all records from Firestore for a range
      // For now, let's assume we have a method in FirestoreService
      // list of records:
      final users = await _firestoreService.getMembers().first;
      // Fetching all attendance records for all users in a month can be heavy.
      // Usually done per day or per month with query limits.
      
      // Mocking record fetch for now as FirestoreService needs a range-all method
      List<AttendanceRecord> records = []; 
      
      final filePath = await _excelService.generateAttendanceReport(records, users);
      
      _isExporting = false;
      notifyListeners();
      return filePath;
    } catch (e) {
      _isExporting = false;
      notifyListeners();
      return null;
    }
  }
}
