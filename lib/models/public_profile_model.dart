import 'model_utils.dart';

/// `publicProfiles/{userId}` — chat ro'yxatida ko'rinadigan ochiq ma'lumot.
///
/// Ataylab `users/{userId}` dan alohida: u yerda maosh, davomat va qarzlar
/// bor, ular boshqa foydalanuvchilarga ko'rinmasligi kerak. Bu yerda esa
/// faqat ism va kichraytirilgan avatar saqlanadi.
class PublicProfile {
  const PublicProfile({
    required this.userId,
    required this.fullName,
    this.avatarBase64,
    this.updatedAt,
  });

  final String userId;
  final String fullName;

  /// Kichraytirilgan avatar (~128px). To'liq rasm bu yerda saqlanmaydi —
  /// ro'yxatda o'nlab foydalanuvchi bo'lsa trafik juda oshib ketardi.
  final String? avatarBase64;

  final DateTime? updatedAt;

  /// Avatar bo'lmaganda ko'rsatiladigan bosh harflar.
  String get initials {
    final List<String> parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  factory PublicProfile.fromMap(String userId, Map<String, dynamic> map) {
    return PublicProfile(
      userId: userId,
      fullName: asString(map['fullName']) ?? 'Foydalanuvchi',
      avatarBase64: asString(map['avatarBase64']),
      updatedAt: asDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'fullName': fullName,
        'avatarBase64': avatarBase64,
        'updatedAt': updatedAt,
      };
}
