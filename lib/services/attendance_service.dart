import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_model.dart';
import '../models/user_profile_model.dart';
import '../utils/salary_calculator.dart';
import '../utils/time_utils.dart';

/// Davomat yozuvlari va ular ustidagi hisob-kitob (PROJECT.md 4- va
/// 5.2-bo'limlar).
///
/// Hujjat ID sifatida sana kaliti ("2026-09-02") ishlatiladi — bir kunga
/// ikkinchi yozuv qo'shilib qolishi mumkin emas.
class AttendanceService {
  const AttendanceService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _db.collection('users').doc(userId).collection('attendance');

  /// Bitta kunni kuzatish.
  Stream<Attendance?> watchDay(String userId, DateTime date) {
    final String key = TimeUtils.dateKey(date);
    return _collection(userId).doc(key).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return Attendance.fromMap(snapshot.id, data);
    });
  }

  /// Sana oralig'ini kuzatish (ikkala chegara ham kiradi).
  ///
  /// `date` maydoni "YYYY-MM-DD" matn bo'lgani uchun leksikografik
  /// taqqoslash xronologik tartibga to'g'ri keladi.
  Stream<List<Attendance>> watchRange(
    String userId,
    DateTime from,
    DateTime to,
  ) {
    return _collection(userId)
        .where('date', isGreaterThanOrEqualTo: TimeUtils.dateKey(from))
        .where('date', isLessThanOrEqualTo: TimeUtils.dateKey(to))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    Attendance.fromMap(doc.id, doc.data()),
              )
              .toList(),
        );
  }

  /// Butun oyni kuzatish.
  Stream<List<Attendance>> watchMonth(String userId, DateTime month) {
    final DateTime first = DateTime(month.year, month.month, 1);
    final DateTime last = DateTime(
      month.year,
      month.month,
      TimeUtils.daysInMonth(month.year, month.month),
    );
    return watchRange(userId, first, last);
  }

  /// Ishga kelish: vaqt yoziladi, kechikish darhol hisoblanadi.
  ///
  /// [now] test qilish uchun tashqaridan beriladi.
  Future<void> checkIn({
    required String userId,
    required UserProfile profile,
    String? photoBase64,
    DateTime? now,
  }) async {
    final DateTime moment = now ?? DateTime.now();
    final String key = TimeUtils.dateKey(moment);

    final int startMinutes =
        TimeUtils.minutesFromHmOr(profile.workStartTime, 9 * 60);

    final Attendance record = Attendance(
      id: key,
      date: key,
      checkInTime: moment,
      checkInPhotoBase64: photoBase64,
      lateMinutes: SalaryCalculator.lateMinutes(
        checkIn: moment,
        workStartMinutes: startMinutes,
      ),
      status: AttendanceStatus.inProgress,
    );

    await _collection(userId).doc(key).set(
          record.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Ishdan ketish: kun yopiladi va to'liq hisob-kitob yoziladi.
  Future<void> checkOut({
    required String userId,
    required UserProfile profile,
    required Attendance existing,
    String? photoBase64,
    DateTime? now,
  }) async {
    final DateTime moment = now ?? DateTime.now();
    final DateTime checkIn = existing.checkInTime ?? moment;

    final DailyCalculation calculation = calculateFor(
      profile: profile,
      checkIn: checkIn,
      checkOut: moment,
    );

    await _collection(userId).doc(existing.id).set(
      <String, dynamic>{
        'checkOutTime': moment,
        'checkOutPhotoBase64': ?photoBase64,
        'workedHours': calculation.workedHours,
        'lateMinutes': calculation.lateMinutes,
        'earlyLeaveMinutes': calculation.earlyLeaveMinutes,
        'penaltyAmount': calculation.penaltyAmount,
        'dailyEarning': calculation.dailyEarning,
        'status': AttendanceStatus.present.value,
      },
      SetOptions(merge: true),
    );
  }

  /// Davomat yozuvini qo'lda kiritish yoki tuzatish.
  ///
  /// Kerak bo'ladigan holatlar: ilova yangi o'rnatilgan va o'tgan kunlar
  /// yozilmagan; check-in bosish esdan chiqqan; vaqt noto'g'ri qayd etilgan.
  ///
  /// Rasm maydonlariga tegilmaydi — agar kunda selfie bo'lsa, u saqlanib
  /// qoladi ( `merge: true` ).
  Future<void> saveManualEntry({
    required String userId,
    required UserProfile profile,
    required DateTime date,
    required int checkInMinutes,
    int? checkOutMinutes,
  }) async {
    final String key = TimeUtils.dateKey(date);

    final DateTime checkIn = DateTime(
      date.year,
      date.month,
      date.day,
      checkInMinutes ~/ 60,
      checkInMinutes % 60,
    );

    DateTime? checkOut;
    if (checkOutMinutes != null) {
      checkOut = DateTime(
        date.year,
        date.month,
        date.day,
        checkOutMinutes ~/ 60,
        checkOutMinutes % 60,
      );
      // Tungi smena: chiqish kirishdan keyin bo'lmasa, keyingi kunga o'tadi.
      if (!checkOut.isAfter(checkIn)) {
        checkOut = checkOut.add(const Duration(days: 1));
      }
    }

    final DailyCalculation calculation = calculateFor(
      profile: profile,
      checkIn: checkIn,
      checkOut: checkOut,
    );

    await _collection(userId).doc(key).set(
      <String, dynamic>{
        'date': key,
        'checkInTime': checkIn,
        'checkOutTime': checkOut,
        'workedHours': calculation.workedHours,
        'lateMinutes': calculation.lateMinutes,
        'earlyLeaveMinutes': calculation.earlyLeaveMinutes,
        'penaltyAmount': calculation.penaltyAmount,
        'dailyEarning': calculation.dailyEarning,
        'status': (checkOut == null
                ? AttendanceStatus.inProgress
                : AttendanceStatus.present)
            .value,
      },
      SetOptions(merge: true),
    );
  }

  /// Bir kunlik yozuvni butunlay o'chiradi.
  Future<void> deleteDay({required String userId, required DateTime date}) {
    return _collection(userId).doc(TimeUtils.dateKey(date)).delete();
  }

  /// Bitta kunni bir marta o'qish (qo'lda tahrirlashda mavjud qiymatlarni
  /// formaga to'ldirish uchun).
  Future<Attendance?> fetchDay(String userId, DateTime date) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection(userId).doc(TimeUtils.dateKey(date)).get();
    final Map<String, dynamic>? data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return Attendance.fromMap(snapshot.id, data);
  }

  /// Profil sozlamalari asosida bir kunlik hisob-kitob.
  static DailyCalculation calculateFor({
    required UserProfile profile,
    required DateTime checkIn,
    DateTime? checkOut,
  }) {
    final int workDaysCount = SalaryCalculator.workDaysInMonth(
      checkIn.year,
      checkIn.month,
      profile.workDays,
    );
    return SalaryCalculator.calculateDay(
      checkIn: checkIn,
      checkOut: checkOut,
      workStartMinutes:
          TimeUtils.minutesFromHmOr(profile.workStartTime, 9 * 60),
      workEndMinutes: TimeUtils.minutesFromHmOr(profile.workEndTime, 18 * 60),
      lunchBreakMinutes: profile.lunchBreakMinutes,
      dailyRate: SalaryCalculator.dailyRate(
        monthlySalary: profile.salaryAmount,
        workDaysCount: workDaysCount,
      ),
      penaltyEnabled: profile.penaltyEnabled,
      isFixedSalary: profile.salaryType == SalaryType.fixed,
    );
  }

  /// Oylik yig'ma hisobot.
  ///
  /// PROJECT.md 10.7-bandi: ish kuni bo'lib kelinmagan kun uchun maosh ham,
  /// jarima ham yozilmaydi — u faqat "kelmagan kunlar" sonini oshiradi.
  static MonthlySummary summarize({
    required UserProfile profile,
    required List<Attendance> records,
    required DateTime month,
    DateTime? today,
  }) {
    final DateTime reference = today ?? DateTime.now();

    double earned = 0;
    double penalty = 0;
    double hours = 0;
    int late = 0;
    int early = 0;
    int present = 0;

    final Set<String> recordedDays = <String>{};

    for (final Attendance record in records) {
      if (record.checkInTime == null) continue;
      recordedDays.add(record.date);
      present++;
      earned += record.dailyEarning;
      penalty += record.penaltyAmount;
      hours += record.workedHours;
      late += record.lateMinutes;
      early += record.earlyLeaveMinutes;
    }

    final int plannedWorkDays = SalaryCalculator.workDaysInMonth(
      month.year,
      month.month,
      profile.workDays,
    );
    final int elapsedWorkDays = SalaryCalculator.elapsedWorkDaysInMonth(
      month.year,
      month.month,
      profile.workDays,
      reference,
    );

    // Kelmagan kunlar: o'tib ketgan ish kunlari ichida yozuvi yo'qlari.
    final Set<int> workDaySet = profile.workDays.toSet();
    final int daysInMonth = TimeUtils.daysInMonth(month.year, month.month);
    int absent = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime date = DateTime(month.year, month.month, day);
      if (!workDaySet.contains(date.weekday)) continue;
      if (date.isAfter(TimeUtils.startOfDay(reference))) continue;
      if (recordedDays.contains(TimeUtils.dateKey(date))) continue;
      absent++;
    }

    return MonthlySummary(
      earnedAmount: SalaryCalculator.monthlyEarning(
        isFixedSalary: profile.salaryType == SalaryType.fixed,
        monthlySalary: profile.salaryAmount,
        sumOfDailyEarnings: earned,
        totalPenalty: penalty,
      ),
      penaltyAmount: penalty,
      workedHours: hours,
      presentDays: present,
      absentDays: absent,
      lateMinutes: late,
      earlyLeaveMinutes: early,
      plannedWorkDays: plannedWorkDays,
      elapsedWorkDays: elapsedWorkDays,
    );
  }
}
