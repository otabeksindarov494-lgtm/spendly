import 'model_utils.dart';

/// Kunlik davomat holati.
enum AttendanceStatus {
  /// Kelgan va ketgan — kun yopilgan.
  present('present'),

  /// Ish kuni bo'lgan, lekin yozuv yo'q.
  absent('absent'),

  /// Kelgan, hali ketmagan.
  inProgress('in_progress');

  const AttendanceStatus(this.value);

  final String value;

  static AttendanceStatus fromValue(String? value) {
    return AttendanceStatus.values.firstWhere(
      (AttendanceStatus s) => s.value == value,
      orElse: () => AttendanceStatus.absent,
    );
  }
}

/// `users/{userId}/attendance/{attendanceId}` (PROJECT.md 3.2).
///
/// Hujjat ID sifatida `date` kaliti ("2026-09-02") ishlatiladi — shunda
/// bir kunga ikkita yozuv tushib qolishi mumkin emas.
class Attendance {
  const Attendance({
    required this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInPhotoBase64,
    this.checkOutPhotoBase64,
    this.workedHours = 0,
    this.lateMinutes = 0,
    this.earlyLeaveMinutes = 0,
    this.penaltyAmount = 0,
    this.dailyEarning = 0,
    this.status = AttendanceStatus.absent,
  });

  final String id;

  /// "2026-09-02" (YYYY-MM-DD).
  final String date;

  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInPhotoBase64;
  final String? checkOutPhotoBase64;
  final double workedHours;
  final int lateMinutes;
  final int earlyLeaveMinutes;
  final double penaltyAmount;
  final double dailyEarning;
  final AttendanceStatus status;

  bool get hasCheckedIn => checkInTime != null;
  bool get hasCheckedOut => checkOutTime != null;
  bool get isLate => lateMinutes > 0;

  factory Attendance.fromMap(String id, Map<String, dynamic> map) {
    return Attendance(
      id: id,
      date: asString(map['date']) ?? id,
      checkInTime: asDateTime(map['checkInTime']),
      checkOutTime: asDateTime(map['checkOutTime']),
      checkInPhotoBase64: asString(map['checkInPhotoBase64']),
      checkOutPhotoBase64: asString(map['checkOutPhotoBase64']),
      workedHours: asDouble(map['workedHours']) ?? 0,
      lateMinutes: asInt(map['lateMinutes']) ?? 0,
      earlyLeaveMinutes: asInt(map['earlyLeaveMinutes']) ?? 0,
      penaltyAmount: asDouble(map['penaltyAmount']) ?? 0,
      dailyEarning: asDouble(map['dailyEarning']) ?? 0,
      status: AttendanceStatus.fromValue(asString(map['status'])),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': date,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'checkInPhotoBase64': checkInPhotoBase64,
      'checkOutPhotoBase64': checkOutPhotoBase64,
      'workedHours': workedHours,
      'lateMinutes': lateMinutes,
      'earlyLeaveMinutes': earlyLeaveMinutes,
      'penaltyAmount': penaltyAmount,
      'dailyEarning': dailyEarning,
      'status': status.value,
    };
  }

  Attendance copyWith({
    String? id,
    String? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? checkInPhotoBase64,
    String? checkOutPhotoBase64,
    double? workedHours,
    int? lateMinutes,
    int? earlyLeaveMinutes,
    double? penaltyAmount,
    double? dailyEarning,
    AttendanceStatus? status,
  }) {
    return Attendance(
      id: id ?? this.id,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInPhotoBase64: checkInPhotoBase64 ?? this.checkInPhotoBase64,
      checkOutPhotoBase64: checkOutPhotoBase64 ?? this.checkOutPhotoBase64,
      workedHours: workedHours ?? this.workedHours,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      earlyLeaveMinutes: earlyLeaveMinutes ?? this.earlyLeaveMinutes,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      dailyEarning: dailyEarning ?? this.dailyEarning,
      status: status ?? this.status,
    );
  }
}
