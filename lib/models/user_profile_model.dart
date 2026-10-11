import 'package:easy_localization/easy_localization.dart';

import 'model_utils.dart';

/// Maosh kelishuvi turi.
///
/// Bu tanlov butun hisob-kitobni belgilaydi — 5.2-bo'limdagi formula
/// faqat [calculated] uchun ishlaydi.
enum SalaryType {
  /// **Fixed** — kelishilgan summa har oy to'liq beriladi.
  ///
  /// Kelmagan kun uchun pul ushlanmaydi, dam olish kunida ishlasa ham
  /// qo'shilmaydi. Ko'p ish joylarida shunday.
  fixed('fixed'),

  /// **Kunlik hisob** — oylik ish kunlariga bo'linadi, har kun uchun
  /// alohida hisoblanadi (PROJECT.md 5.2).
  calculated('calculated');

  const SalaryType(this.value);

  final String value;

  static SalaryType fromValue(String? value) {
    return SalaryType.values.firstWhere(
      (SalaryType t) => t.value == value,
      // Eski profillarda bu maydon yo'q — ular kunlik hisobda yaratilgan.
      orElse: () => SalaryType.calculated,
    );
  }

  String get label => switch (this) {
        SalaryType.fixed => 'salary_type_fixed_label'.tr(),
        SalaryType.calculated => 'salary_type_calculated_label'.tr(),
      };

  String get description => switch (this) {
        SalaryType.fixed => 'salary_type_fixed_desc'.tr(),
        SalaryType.calculated => 'salary_type_calculated_desc'.tr(),
      };
}

/// `users/{userId}` hujjatidagi profil maydonlari (PROJECT.md 3.2).
///
/// Firestore'da profil alohida sub-hujjat emas, balki `users/{userId}`
/// hujjatining o'zidagi maydonlar sifatida saqlanadi — 3.3-bo'limdagi
/// xavfsizlik qoidalari ham aynan shu strukturaga mos keladi.
class UserProfile {
  const UserProfile({
    this.fullName = '',
    this.birthDate,
    this.phoneNumber = '',
    this.profilePhotoBase64,
    this.salaryType = SalaryType.calculated,
    this.salaryMin = 0,
    this.salaryMax = 0,
    this.salaryAmount = 0,
    this.currency = 'so\'m',
    this.companyName = '',
    this.position = '',
    this.employmentStartDate,
    this.workStartTime = '09:00',
    this.workEndTime = '18:00',
    this.lunchBreakMinutes = 60,
    this.salaryPayDay = 5,
    this.workDays = const <int>[1, 2, 3, 4, 5],
    this.penaltyEnabled = true,
    this.onboardingCompleted = false,
    this.themeMode = 'light',
    this.createdAt,
  });

  final String fullName;
  final DateTime? birthDate;
  final String phoneNumber;
  final String? profilePhotoBase64;

  /// Maosh kelishuvi turi — hisob-kitob shunga qarab tanlanadi.
  final SalaryType salaryType;

  /// Kelishilgan oraliqning quyi chegarasi.
  final double salaryMin;

  /// Kelishilgan oraliqning yuqori chegarasi.
  final double salaryMax;

  /// Hisob-kitobda ishlatiladigan summa — oraliqning o'rtachasi.
  ///
  /// Alohida saqlanadi: oraliq keyin o'zgarsa ham eski oylar o'z
  /// qiymati bilan qolsin.
  final double salaryAmount;

  final String currency;
  final String companyName;

  /// Lavozim.
  final String position;

  /// Ishga kirgan sana.
  final DateTime? employmentStartDate;

  /// "09:00" formatida.
  final String workStartTime;

  /// "18:00" formatida.
  final String workEndTime;

  /// Tushlik tanaffusi (daqiqa). Ish soatidan ayiriladi, shuning uchun
  /// soatlik stavkaga ham ta'sir qiladi. 0 — tanaffus yo'q.
  final int lunchBreakMinutes;

  /// Kechikish va erta ketish uchun pul ushlab qolinadimi.
  ///
  /// Ba'zi ish joylarida kechikkanda jarima yo'q — bunda kechikish
  /// faqat statistika uchun yoziladi, pulga ta'sir qilmaydi.
  final bool penaltyEnabled;

  /// Oyning nechinchi kuni maosh beriladi (1–31).
  final int salaryPayDay;

  /// `DateTime.weekday` konvensiyasi: 1 = Dushanba … 7 = Yakshanba.
  final List<int> workDays;

  final bool onboardingCompleted;

  /// "light" | "dark" (sukut bo'yicha "light").
  final String themeMode;

  final DateTime? createdAt;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final double min = asDouble(map['salaryMin']) ?? 0;
    final double max = asDouble(map['salaryMax']) ?? 0;
    final double? stored = asDouble(map['salaryAmount']);

    return UserProfile(
      fullName: asString(map['fullName']) ?? '',
      birthDate: asDateTime(map['birthDate']),
      phoneNumber: asString(map['phoneNumber']) ?? '',
      profilePhotoBase64: asString(map['profilePhotoBase64']),
      salaryType: SalaryType.fromValue(asString(map['salaryType'])),
      salaryMin: min,
      salaryMax: max,
      // Eski profillarda oraliq yo'q — o'sha paytdagi aniq summa qoladi.
      salaryAmount: stored ?? averageOf(min, max),
      currency: asString(map['currency']) ?? 'so\'m',
      companyName: asString(map['companyName']) ?? '',
      position: asString(map['position']) ?? '',
      employmentStartDate: asDateTime(map['employmentStartDate']),
      workStartTime: asString(map['workStartTime']) ?? '09:00',
      workEndTime: asString(map['workEndTime']) ?? '18:00',
      lunchBreakMinutes: asInt(map['lunchBreakMinutes']) ?? 60,
      salaryPayDay: asInt(map['salaryPayDay']) ?? 5,
      workDays: asIntList(map['workDays']) ?? const <int>[1, 2, 3, 4, 5],
      penaltyEnabled: asBool(map['penaltyEnabled']) ?? true,
      onboardingCompleted: asBool(map['onboardingCompleted']) ?? false,
      themeMode: asString(map['themeMode']) ?? 'light',
      createdAt: asDateTime(map['createdAt']),
    );
  }

  /// Oraliqning o'rtachasi — hisob-kitobda shu summa ishlatiladi.
  static double averageOf(double min, double max) {
    if (min <= 0 && max <= 0) return 0;
    if (min <= 0) return max;
    if (max <= 0) return min;
    return (min + max) / 2;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fullName': fullName,
      'birthDate': birthDate,
      'phoneNumber': phoneNumber,
      'profilePhotoBase64': profilePhotoBase64,
      'salaryType': salaryType.value,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryAmount': salaryAmount,
      'currency': currency,
      'companyName': companyName,
      'position': position,
      'employmentStartDate': employmentStartDate,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
      'lunchBreakMinutes': lunchBreakMinutes,
      'salaryPayDay': salaryPayDay,
      'workDays': workDays,
      'penaltyEnabled': penaltyEnabled,
      'onboardingCompleted': onboardingCompleted,
      'themeMode': themeMode,
      'createdAt': createdAt,
    };
  }

  UserProfile copyWith({
    String? fullName,
    DateTime? birthDate,
    String? phoneNumber,
    String? profilePhotoBase64,
    bool clearProfilePhoto = false,
    SalaryType? salaryType,
    double? salaryMin,
    double? salaryMax,
    double? salaryAmount,
    String? currency,
    String? companyName,
    String? position,
    DateTime? employmentStartDate,
    String? workStartTime,
    String? workEndTime,
    int? lunchBreakMinutes,
    int? salaryPayDay,
    List<int>? workDays,
    bool? penaltyEnabled,
    bool? onboardingCompleted,
    String? themeMode,
    DateTime? createdAt,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhotoBase64: clearProfilePhoto
          ? null
          : (profilePhotoBase64 ?? this.profilePhotoBase64),
      salaryType: salaryType ?? this.salaryType,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      salaryAmount: salaryAmount ?? this.salaryAmount,
      currency: currency ?? this.currency,
      companyName: companyName ?? this.companyName,
      position: position ?? this.position,
      employmentStartDate: employmentStartDate ?? this.employmentStartDate,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      lunchBreakMinutes: lunchBreakMinutes ?? this.lunchBreakMinutes,
      salaryPayDay: salaryPayDay ?? this.salaryPayDay,
      workDays: workDays ?? this.workDays,
      penaltyEnabled: penaltyEnabled ?? this.penaltyEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
