import '../models/debt_model.dart';

/// Ovozdan matnga o'girilgan gapdan ajratib olingan qarz ma'lumoti.
class ParsedDebt {
  const ParsedDebt({
    required this.rawText,
    this.personName,
    this.amount,
    this.type,
  });

  /// Nutqni tanish qaytargan asl matn.
  final String rawText;

  final String? personName;
  final double? amount;
  final DebtType? type;

  /// Uchala maydon ham topilganmi?
  bool get isComplete =>
      personName != null && amount != null && type != null;

  /// Foydalanuvchi tasdiqlash ekranida qo'lda to'ldirishi kerak bo'lgan
  /// maydonlar bor-yo'qligi.
  bool get needsReview => !isComplete;
}

/// O'zbekcha gapdan ism, summa va qarz yo'nalishini ajratadi.
///
/// **Yo'nalish mantig'i haqida muhim eslatma.**
/// PROJECT.md 5.3-bo'limida `"oldim" → owed_to_me` deb yozilgan (savol
/// belgisi bilan). Bu semantik jihatdan teskari: agar men Alisherdan pul
/// **olgan** bo'lsam, qarzdor — men, ya'ni `i_owe`. Shu sabab bu yerda
/// mantiqan to'g'ri variant qo'llanilgan:
///
///   * "Alisherdan 30 ming oldim"  → [DebtType.iOwe]      (men qarzdorman)
///   * "Alisherga 30 ming berdim"  → [DebtType.owedToMe]  (menga qarz)
///
/// Agar boshqacha kerak bo'lsa — [_detectType] ichidagi ikki qiymatni
/// almashtirish kifoya. Har holda PRD 10.8-bandiga ko'ra natija har doim
/// foydalanuvchiga tasdiqlash ekranida ko'rsatiladi.
abstract final class VoiceParser {
  static const Map<String, int> _units = <String, int>{
    'bir': 1,
    'ikki': 2,
    'uch': 3,
    'to\'rt': 4,
    'tort': 4,
    'besh': 5,
    'olti': 6,
    'yetti': 7,
    'etti': 7,
    'sakkiz': 8,
    'to\'qqiz': 9,
    'toqqiz': 9,
    'o\'n': 10,
    'on': 10,
    'yigirma': 20,
    'o\'ttiz': 30,
    'ottiz': 30,
    'qirq': 40,
    'ellik': 50,
    'oltmish': 60,
    'yetmish': 70,
    'sakson': 80,
    'to\'qson': 90,
    'toqson': 90,
  };

  static const Map<String, int> _scales = <String, int>{
    'yuz': 100,
    'ming': 1000,
    'million': 1000000,
    'milion': 1000000,
    'mln': 1000000,
    'milliard': 1000000000,
    'mlrd': 1000000000,
  };

  /// Ism bo'la olmaydigan so'zlar.
  static const Set<String> _stopWords = <String>{
    'men', 'menga', 'mendan', 'mening', 'meni',
    'sen', 'senga', 'sendan', 'sening',
    'siz', 'sizga', 'sizdan', 'sizning',
    'u', 'unga', 'undan', 'uning',
    'biz', 'bizga', 'bizdan', 'bizning',
    'ular', 'ularga', 'ulardan',
    'qarz', 'qarzga', 'qarzdan', 'qarzim', 'qarzi', 'qarzdor', 'qarzdorman',
    'qarzman', 'pul', 'pulni', 'pulga', 'summa',
    'so\'m', 'som', 'sum', 'sumga', 'so\'mga', 'so\'mni',
    'berdim', 'berdi', 'berdik', 'berishdi', 'bergan', 'berganman',
    'bergandim', 'ber', 'beraman',
    'oldim', 'oldi', 'oldik', 'olishdi', 'olgan', 'olganman', 'olgandim',
    'ol', 'olaman',
    'bugun', 'kecha', 'ertaga', 'uchun', 'edi', 'bo\'ldi', 'boldi', 'ham',
    'va', 'yana', 'bir', 'yarim',
  };

  static const Set<String> _iOweVerbs = <String>{
    'oldim', 'olganman', 'olgandim', 'olaman',
    'qarzman', 'qarzdorman', 'qarzim',
  };

  static const Set<String> _theyGaveMeVerbs = <String>{
    'berdi', 'berishdi', 'bergan', 'beribdi',
  };

  static const Set<String> _owedToMeVerbs = <String>{
    'berdim', 'berganman', 'bergandim', 'beraman',
  };

  static const Set<String> _theyTookVerbs = <String>{
    'oldi', 'olishdi', 'olibdi', 'qarzdor',
  };

  /// Asosiy kirish nuqtasi.
  static ParsedDebt parse(String rawText) {
    final List<String> tokens = _tokenize(rawText);
    if (tokens.isEmpty) return ParsedDebt(rawText: rawText);

    final String? name = _detectName(tokens);
    return ParsedDebt(
      rawText: rawText,
      personName: name,
      amount: _detectAmount(tokens),
      type: _detectType(tokens),
    );
  }

  // --- Matnni tozalash -----------------------------------------------------

  /// Apostrof variantlarini bittaga keltiradi va so'zlarga bo'ladi.
  static List<String> _tokenize(String text) {
    final String normalized = text
        .toLowerCase()
        .replaceAll(RegExp('[‘’ʻʼ`´]'), '\'')
        .replaceAll(RegExp('[^a-z0-9\'Ѐ-ӿ ]'), ' ');

    final List<String> raw = normalized
        .split(RegExp(r'\s+'))
        .where((String t) => t.isNotEmpty)
        .toList();

    return _mergeDigitGroups(raw);
  }

  /// "2 500 000" kabi bo'lingan raqamlarni bitta songa birlashtiradi.
  ///
  /// Faqat keyingi bo'lak roppa-rosa 3 xonali bo'lsa birlashtiriladi,
  /// shunda "30 ming" kabi holatlar buzilmaydi.
  static List<String> _mergeDigitGroups(List<String> tokens) {
    final List<String> result = <String>[];
    for (final String token in tokens) {
      final bool isDigits = RegExp(r'^\d+$').hasMatch(token);
      if (isDigits &&
          result.isNotEmpty &&
          token.length == 3 &&
          RegExp(r'^\d+$').hasMatch(result.last)) {
        result[result.length - 1] = result.last + token;
      } else {
        result.add(token);
      }
    }
    return result;
  }

  // --- Summa ---------------------------------------------------------------

  static double? _detectAmount(List<String> tokens) {
    int total = 0;
    int current = 0;
    bool found = false;

    for (final String token in tokens) {
      if (RegExp(r'^\d+$').hasMatch(token)) {
        current += int.parse(token);
        found = true;
        continue;
      }

      final int? unit = _units[token];
      if (unit != null) {
        current += unit;
        found = true;
        continue;
      }

      final int? scale = _scales[token];
      if (scale != null) {
        found = true;
        if (scale == 100) {
          current = (current == 0 ? 1 : current) * 100;
        } else {
          total += (current == 0 ? 1 : current) * scale;
          current = 0;
        }
      }
    }

    total += current;
    return (found && total > 0) ? total.toDouble() : null;
  }

  // --- Yo'nalish -----------------------------------------------------------

  static DebtType? _detectType(List<String> tokens) {
    final Set<String> set = tokens.toSet();

    // 1) Men haqimdagi fe'l — eng ishonchli belgi.
    if (set.any(_iOweVerbs.contains)) return DebtType.iOwe;
    if (set.any(_owedToMeVerbs.contains)) return DebtType.owedToMe;

    // 2) Uchinchi shaxs fe'li: "u menga berdi" / "u mendan oldi".
    if (set.any(_theyGaveMeVerbs.contains)) return DebtType.iOwe;
    if (set.any(_theyTookVerbs.contains)) return DebtType.owedToMe;

    // 3) Fe'l topilmasa — ismdagi kelishik qo'shimchasi.
    for (final String token in tokens) {
      if (_stopWords.contains(token)) continue;
      if (_hasSuffix(token, 'dan')) return DebtType.iOwe;
      if (_hasSuffix(token, 'ga') ||
          _hasSuffix(token, 'ka') ||
          _hasSuffix(token, 'qa')) {
        return DebtType.owedToMe;
      }
    }

    return null;
  }

  // --- Ism -----------------------------------------------------------------

  static String? _detectName(List<String> tokens) {
    // Avval kelishik qo'shimchali so'zni qidiramiz: "Alisherdan", "Boburga".
    for (final String token in tokens) {
      if (_stopWords.contains(token)) continue;
      if (_isNumberWord(token)) continue;

      for (final String suffix in const <String>['dan', 'ga', 'ka', 'qa']) {
        if (_hasSuffix(token, suffix)) {
          final String stem = token.substring(0, token.length - suffix.length);
          if (stem.length >= 2 && !_stopWords.contains(stem)) {
            return _capitalize(stem);
          }
        }
      }
    }

    // Topilmasa — qo'shimchasiz birinchi mos so'z.
    for (final String token in tokens) {
      if (_stopWords.contains(token)) continue;
      if (_isNumberWord(token)) continue;
      if (token.length < 2) continue;
      return _capitalize(token);
    }

    return null;
  }

  static bool _isNumberWord(String token) =>
      RegExp(r'^\d+$').hasMatch(token) ||
      _units.containsKey(token) ||
      _scales.containsKey(token);

  /// So'z [suffix] bilan tugaganini va o'zagi yetarlicha uzunligini tekshiradi.
  static bool _hasSuffix(String token, String suffix) =>
      token.length >= suffix.length + 2 && token.endsWith(suffix);

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
