/// Firestore'dan kelgan `dynamic` qiymatlarni xavfsiz o'girish.
///
/// Bu fayl ataylab `cloud_firestore`ni import qilmaydi — modellar sof
/// Dart bo'lib qolsin, ularni unit-test qilish oson bo'lsin uchun.
/// `Timestamp` "duck typing" orqali (`.toDate()`) qo'llab-quvvatlanadi.
library;

String? asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

double? asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return null;
}

List<int>? asIntList(dynamic value) {
  if (value is! List) return null;
  final List<int> result = <int>[];
  for (final dynamic item in value) {
    final int? parsed = asInt(item);
    if (parsed != null) result.add(parsed);
  }
  return result;
}

/// `Timestamp`, [DateTime] yoki ISO-8601 matnni [DateTime]ga o'giradi.
DateTime? asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  try {
    // `cloud_firestore`ning `Timestamp` obyekti.
    final dynamic converted = (value as dynamic).toDate();
    return converted is DateTime ? converted : null;
  } catch (_) {
    return null;
  }
}
