import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, late, absent, halfDay, offDay }

class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final DateTime? lunchOut;
  final DateTime? lunchIn;
  final AttendanceStatus status;
  final String? ssid;
  final String? bssid;
  final double? latitude;
  final double? longitude;
  final String? note;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.lunchOut,
    this.lunchIn,
    required this.status,
    this.ssid,
    this.bssid,
    this.latitude,
    this.longitude,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'checkIn': checkIn != null ? Timestamp.fromDate(checkIn!) : null,
      'checkOut': checkOut != null ? Timestamp.fromDate(checkOut!) : null,
      'lunchOut': lunchOut != null ? Timestamp.fromDate(lunchOut!) : null,
      'lunchIn': lunchIn != null ? Timestamp.fromDate(lunchIn!) : null,
      'status': status.index,
      'ssid': ssid,
      'bssid': bssid,
      'latitude': latitude,
      'longitude': longitude,
      'note': note,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      checkIn: (map['checkIn'] as Timestamp?)?.toDate(),
      checkOut: (map['checkOut'] as Timestamp?)?.toDate(),
      lunchOut: (map['lunchOut'] as Timestamp?)?.toDate(),
      lunchIn: (map['lunchIn'] as Timestamp?)?.toDate(),
      status: AttendanceStatus.values[map['status'] ?? 0],
      ssid: map['ssid'],
      bssid: map['bssid'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      note: map['note'],
    );
  }
}
