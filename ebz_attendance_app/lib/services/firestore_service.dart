import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_account.dart';
import '../models/attendance_record.dart';
import '../models/app_rules.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Methods ---

  Future<void> saveUser(UserAccount user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserAccount?> getUser(String uid) async {
    var doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserAccount.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateFirstLoginFlag(String uid, bool isFirstLogin) async {
    await _db.collection('users').doc(uid).update({'isFirstLogin': isFirstLogin});
  }

  Stream<List<UserAccount>> getMembers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: UserRole.member.index)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserAccount.fromMap(doc.data())).toList());
  }

  // --- Attendance Methods ---

  Future<void> saveAttendance(AttendanceRecord record) async {
    await _db.collection('attendance').doc(record.id).set(record.toMap());
  }

  Stream<List<AttendanceRecord>> getUserAttendance(String userId, DateTime start, DateTime end) {
    return _db
        .collection('attendance')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AttendanceRecord.fromMap(doc.data())).toList());
  }

  Stream<List<AttendanceRecord>> getAllAttendance(DateTime date) {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _db
        .collection('attendance')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AttendanceRecord.fromMap(doc.data())).toList());
  }

  Future<List<AttendanceRecord>> getAttendanceRange(DateTime start, DateTime end) async {
    var snapshot = await _db
        .collection('attendance')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return snapshot.docs.map((doc) => AttendanceRecord.fromMap(doc.data())).toList();
  }

  // --- Rules Methods ---

  Future<void> saveRules(AppRules rules) async {
    await _db.collection('settings').doc('app_rules').set(rules.toMap());
  }

  Future<AppRules?> getRules() async {
    var doc = await _db.collection('settings').doc('app_rules').get();
    if (doc.exists) {
      return AppRules.fromMap(doc.data()!);
    }
    return null;
  }
}
