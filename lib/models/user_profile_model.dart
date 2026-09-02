import 'model_utils.dart';

/// `users/{userId}` hujjatidagi profil maydonlari (PROJECT.md 3.2).
///
/// Firestore'da profil alohida sub-hujjat emas, balki `users/{userId}`
/// hujjatining o'zidagi maydonlar sifatida saqlanadi — 3.3-bo'limdagi
/// xavfsizlik qoidalari ham aynan shu strukturaga mos keladi.
class UserProfile {
  const UserProfile({
    this.fullName = '',
    this.birthDate,
    this.profilePhotoBase64,
    this.salaryAmount = 0,
    this.currency = 'so\'m',
    this.companyName = '',
    this.workStartTime = '09:00',
    this.workEndTime = '18:00',
    this.salaryPayDay = 5,
    this.workDays = const <int>[1, 2, 3, 4, 5],
    this.onboardingCompleted = false,
    this.themeMode = 'light',
    this.createdAt,
  });

  final String fullName;
  final DateTime? birthDate;
  final String? profilePhotoBase64;
  final double salaryAmount;
  final String currency;
  final String companyName;

  /// "09:00" formatida.
  final String workStartTime;

  /// "18:00" formatida.
  final String workEndTime;

  /// Oyning nechinchi kuni maosh beriladi (1–31).
  final int salaryPayDay;

  /// `DateTime.weekday` konvensiyasi: 1 = Dushanba … 7 = Yakshanba.
  final List<int> workDays;

  final bool onboardingCompleted;

  /// "light" | "dark" (sukut bo'yicha "light").
  final String themeMode;

  final DateTime? createdAt;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      fullName: asString(map['fullName']) ?? '',
      birthDate: asDateTime(map['birthDate']),
      profilePhotoBase64: asString(map['profilePhotoBase64']),
      salaryAmount: asDouble(map['salaryAmount']) ?? 0,
      currency: asString(map['currency']) ?? 'so\'m',
      companyName: asString(map['companyName']) ?? '',
      workStartTime: asString(map['workStartTime']) ?? '09:00',
      workEndTime: asString(map['workEndTime']) ?? '18:00',
      salaryPayDay: asInt(map['salaryPayDay']) ?? 5,
      workDays: asIntList(map['workDays']) ?? const <int>[1, 2, 3, 4, 5],
      onboardingCompleted: asBool(map['onboardingCompleted']) ?? false,
      themeMode: asString(map['themeMode']) ?? 'light',
      createdAt: asDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fullName': fullName,
      'birthDate': birthDate,
      'profilePhotoBase64': profilePhotoBase64,
      'salaryAmount': salaryAmount,
      'currency': currency,
      'companyName': companyName,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
      'salaryPayDay': salaryPayDay,
      'workDays': workDays,
      'onboardingCompleted': onboardingCompleted,
      'themeMode': themeMode,
      'createdAt': createdAt,
    };
  }

  UserProfile copyWith({
    String? fullName,
    DateTime? birthDate,
    String? profilePhotoBase64,
    bool clearProfilePhoto = false,
    double? salaryAmount,
    String? currency,
    String? companyName,
    String? workStartTime,
    String? workEndTime,
    int? salaryPayDay,
    List<int>? workDays,
    bool? onboardingCompleted,
    String? themeMode,
    DateTime? createdAt,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      profilePhotoBase64: clearProfilePhoto
          ? null
          : (profilePhotoBase64 ?? this.profilePhotoBase64),
      salaryAmount: salaryAmount ?? this.salaryAmount,
      currency: currency ?? this.currency,
      companyName: companyName ?? this.companyName,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      salaryPayDay: salaryPayDay ?? this.salaryPayDay,
      workDays: workDays ?? this.workDays,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
