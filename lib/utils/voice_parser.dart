import '../models/debt_model.dart';

/// Ovozdan matnga o'girilgan gapdan ajratib olingan qarz ma'lumoti.
class ParsedDebt {
  const ParsedDebt({
    required this.rawText,
    this.personName,
    this.amount,
    this.type,
    this.description,
    this.confidence = 0,
  });

  /// Nutqni tanish qaytargan asl matn.
  final String rawText;

  final String? personName;
  final double? amount;
  final DebtType? type;

  /// Gapdan ajratib olingan izoh ("kitob uchun" kabi).
  final String? description;

  /// 0.0 – 1.0. Uchala maydon ham ishonchli topilsa 1.0 ga yaqin bo'ladi.
  ///
  /// Yo'nalish fe'l orqali aniqlangan bo'lsa ishonch yuqori; faqat
  /// kelishik qo'shimchasidan taxmin qilingan bo'lsa pastroq.
  final double confidence;

  /// Uchala asosiy maydon ham topilganmi?
  bool get isComplete =>
      personName != null && amount != null && type != null;

  /// Foydalanuvchi diqqat bilan tekshirishi kerakmi.
  ///
  /// Chegara 0.9: yo'nalish faqat kelishik qo'shimchasidan taxmin
  /// qilingan bo'lsa (fe'l topilmagan) ball 0.85 chiqadi va ogohlantirish
  /// ko'rsatiladi. Tasdiqlash ekrani esa har doim ochiladi (PRD 10.8).
  bool get needsReview => !isComplete || confidence < 0.9;
}

/// O'zbekcha gapdan ism, summa, qarz yo'nalishi va izohni ajratadi.
///
/// Butunlay mahalliy ishlaydi — hech qanday pullik xizmat yoki internet
/// so'rovi yo'q. Nutqni matnga o'girishni qurilmaning o'z tizimi
/// bajaradi (`speech_to_text`), bu fayl esa faqat matnni tahlil qiladi.
///
/// **Yo'nalish mantig'i haqida.**
/// PROJECT.md 5.3-bo'limida `"oldim" → owed_to_me` deb yozilgan (savol
/// belgisi bilan). Bu semantik jihatdan teskari: Alisherdan pul
/// **olgan** bo'lsam, qarzdor — men. Shu sabab bu yerda:
///
///   * "Alisherdan 30 ming oldim"  → [DebtType.iOwe]      (men qarzdorman)
///   * "Alisherga 30 ming berdim"  → [DebtType.owedToMe]  (menga qarz)
///
/// Natija har doim tasdiqlash ekranida ko'rsatiladi (PRD 10.8).
abstract final class VoiceParser {
  // --- Raqam so'zlari --------------------------------------------------------

  static const Map<String, double> _units = <String, double>{
    'bir': 1, 'bitta': 1,
    'ikki': 2, 'ikkita': 2,
    'uch': 3, 'uchta': 3,
    'to\'rt': 4, 'tort': 4, 'turt': 4, 'to\'rtta': 4,
    'besh': 5, 'beshta': 5,
    'olti': 6, 'oltita': 6,
    'yetti': 7, 'etti': 7, 'yettita': 7,
    'sakkiz': 8, 'sakkizta': 8,
    'to\'qqiz': 9, 'toqqiz': 9, 'to\'qqizta': 9,
    'o\'n': 10, 'on': 10,
    'yigirma': 20,
    'o\'ttiz': 30, 'ottiz': 30,
    'qirq': 40,
    'ellik': 50,
    'oltmish': 60,
    'yetmish': 70, 'etmish': 70,
    'sakson': 80,
    'to\'qson': 90, 'toqson': 90,
  };

  static const Map<String, double> _scales = <String, double>{
    'yuz': 100, 'yuzta': 100,
    'ming': 1000, 'mingta': 1000, 'ming\'': 1000,
    'million': 1000000, 'milion': 1000000, 'mln': 1000000,
    'millon': 1000000, 'milyon': 1000000,
    'milliard': 1000000000, 'mlrd': 1000000000, 'milyard': 1000000000,
  };

  /// "yarim million" = 500 000, "bir yarim million" = 1 500 000.
  static const Set<String> _halfWords = <String>{'yarim', 'yarm'};

  // --- Fe'l shakllari --------------------------------------------------------

  /// Men oldim → men qarzdorman.
  static const Set<String> _iTookVerbs = <String>{
    'oldim', 'oldik', 'olganman', 'olgandim', 'olaman', 'olyapman',
    'olibman', 'olvoldim', 'qarzman', 'qarzdorman', 'qarzimman',
  };

  /// Men berdim → menga qarz.
  static const Set<String> _iGaveVerbs = <String>{
    'berdim', 'berdik', 'berganman', 'bergandim', 'beraman', 'beryapman',
    'beribman', 'qarzimga', 'qarzga',
  };

  /// U menga berdi → men qarzdorman.
  static const Set<String> _theyGaveVerbs = <String>{
    'berdi', 'berishdi', 'bergan', 'beribdi', 'bergandi', 'beradi',
  };

  /// U mendan oldi → menga qarz.
  static const Set<String> _theyTookVerbs = <String>{
    'oldi', 'olishdi', 'olibdi', 'olgandi', 'oladi', 'qarzdor', 'qarzi',
  };

  /// Ism bo'la olmaydigan so'zlar.
  static const Set<String> _stopWords = <String>{
    'men', 'menga', 'mendan', 'mening', 'meni', 'menda',
    'sen', 'senga', 'sendan', 'sening', 'seni', 'senda',
    'siz', 'sizga', 'sizdan', 'sizning', 'sizni', 'sizda',
    'u', 'unga', 'undan', 'uning', 'uni', 'unda',
    'biz', 'bizga', 'bizdan', 'bizning', 'bizni', 'bizda',
    'ular', 'ularga', 'ulardan', 'ularning',
    'qarz', 'qarzga', 'qarzdan', 'qarzim', 'qarzi', 'qarzini',
    'qarzdor', 'qarzdorman', 'qarzman',
    'pul', 'pulni', 'pulga', 'puldan', 'summa', 'summani',
    'so\'m', 'som', 'sum', 'sumga', 'so\'mga', 'so\'mni', 'so\'mlik',
    'dollar', 'dollarni', 'dollarga', 'usd',
    'bugun', 'kecha', 'ertaga', 'kechqurun', 'ertalab',
    'uchun', 'edi', 'bo\'ldi', 'boldi', 'ham', 'va', 'yana', 'keyin',
    'hozir', 'endi', 'lekin', 'ammo',
  };

  /// Ismdan ajratiladigan kelishik qo'shimchalari (uzunroqlari birinchi).
  static const List<String> _caseSuffixes = <String>[
    'lardan', 'larga', 'ning', 'niki', 'dan', 'tan', 'ga', 'ka', 'qa', 'ni',
  ];

  /// Kirill alifbosidan lotinga (o'zbekcha).
  static const Map<String, String> _cyrillic = <String, String>{
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
    'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'sh',
    'ъ': '\'', 'ы': 'i', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
    'ў': 'o\'', 'қ': 'q', 'ғ': 'g\'', 'ҳ': 'h',
  };

  // --- Kirish nuqtasi --------------------------------------------------------

  static ParsedDebt parse(String rawText) {
    final List<String> tokens = tokenize(rawText);
    if (tokens.isEmpty) return ParsedDebt(rawText: rawText);

    final String? name = _detectName(tokens);
    final double? amount = _detectAmount(tokens);
    final (DebtType?, double) direction = _detectType(tokens);

    return ParsedDebt(
      rawText: rawText,
      personName: name,
      amount: amount,
      type: direction.$1,
      description: _detectDescription(tokens),
      confidence: _score(
        hasName: name != null,
        hasAmount: amount != null,
        directionScore: direction.$2,
      ),
    );
  }

  /// Ishonch darajasi: har bir maydon o'z ulushini qo'shadi.
  static double _score({
    required bool hasName,
    required bool hasAmount,
    required double directionScore,
  }) {
    double score = 0;
    if (hasAmount) score += 0.4;
    if (hasName) score += 0.3;
    score += directionScore * 0.3;
    return score.clamp(0.0, 1.0);
  }

  // --- Matnni tozalash -------------------------------------------------------

  /// Kirillni lotinga o'giradi, apostroflarni bittaga keltiradi va
  /// so'zlarga bo'ladi. Testlar uchun ochiq.
  static List<String> tokenize(String text) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in text.toLowerCase().runes) {
      final String ch = String.fromCharCode(rune);
      buffer.write(_cyrillic[ch] ?? ch);
    }

    final String normalized = buffer
        .toString()
        .replaceAll(RegExp('[‘’ʻʼ`´]'), '\'')
        // Raqam va harf yopishib qolgan bo'lsa ajratamiz: "30ming" -> "30 ming"
        .replaceAllMapped(
          RegExp(r"(\d)([a-z'])"),
          (Match m) => '${m[1]} ${m[2]}',
        )
        .replaceAllMapped(
          RegExp(r"([a-z'])(\d)"),
          (Match m) => '${m[1]} ${m[2]}',
        )
        .replaceAll(RegExp('[^a-z0-9\' ]'), ' ');

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

  // --- Summa -----------------------------------------------------------------

  static double? _detectAmount(List<String> tokens) {
    double total = 0;
    double current = 0;
    bool found = false;

    for (final String token in tokens) {
      if (RegExp(r'^\d+$').hasMatch(token)) {
        current += double.parse(token);
        found = true;
        continue;
      }

      if (_halfWords.contains(token)) {
        current += 0.5;
        found = true;
        continue;
      }

      final double? unit = _units[token];
      if (unit != null) {
        current += unit;
        found = true;
        continue;
      }

      final double? scale = _scales[token];
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
    return (found && total > 0) ? total : null;
  }

  // --- Yo'nalish -------------------------------------------------------------

  /// Yo'nalish va uni qanchalik ishonchli aniqlaganimiz (0.0 – 1.0).
  static (DebtType?, double) _detectType(List<String> tokens) {
    final Set<String> set = tokens.toSet();

    // 1) Men haqimdagi fe'l — eng ishonchli belgi.
    if (set.any(_iTookVerbs.contains)) return (DebtType.iOwe, 1);
    if (set.any(_iGaveVerbs.contains)) return (DebtType.owedToMe, 1);

    // 2) Uchinchi shaxs fe'li: "u menga berdi" / "u mendan oldi".
    if (set.any(_theyGaveVerbs.contains)) return (DebtType.iOwe, 0.85);
    if (set.any(_theyTookVerbs.contains)) return (DebtType.owedToMe, 0.85);

    // 3) Fe'l topilmasa — ismdagi kelishik qo'shimchasi. Ishonch pastroq.
    for (final String token in tokens) {
      if (_stopWords.contains(token)) continue;
      if (_hasSuffix(token, 'dan') || _hasSuffix(token, 'tan')) {
        return (DebtType.iOwe, 0.5);
      }
      if (_hasSuffix(token, 'ga') ||
          _hasSuffix(token, 'ka') ||
          _hasSuffix(token, 'qa')) {
        return (DebtType.owedToMe, 0.5);
      }
    }

    return (null, 0);
  }

  // --- Ism -------------------------------------------------------------------

  static String? _detectName(List<String> tokens) {
    // Avval kelishik qo'shimchali so'zni qidiramiz: "Alisherdan", "Boburga".
    for (final String token in tokens) {
      if (_stopWords.contains(token) || _isNumberWord(token)) continue;

      for (final String suffix in _caseSuffixes) {
        if (!_hasSuffix(token, suffix)) continue;
        final String stem = token.substring(0, token.length - suffix.length);
        if (stem.length >= 2 && !_stopWords.contains(stem)) {
          return _capitalize(stem);
        }
      }
    }

    // Topilmasa — qo'shimchasiz birinchi mos so'z.
    for (final String token in tokens) {
      if (_stopWords.contains(token) || _isNumberWord(token)) continue;
      if (_isVerb(token) || token.length < 2) continue;
      return _capitalize(token);
    }

    return null;
  }

  // --- Izoh ------------------------------------------------------------------

  /// "uchun" dan oldingi so'zlarni izoh sifatida oladi.
  ///
  /// Masalan "Alisherga 50 ming kitob uchun berdim" → "kitob".
  static String? _detectDescription(List<String> tokens) {
    final int index = tokens.indexOf('uchun');
    if (index <= 0) return null;

    final List<String> words = <String>[];
    for (int i = index - 1; i >= 0 && words.length < 3; i--) {
      final String token = tokens[i];
      if (_isNumberWord(token) || _stopWords.contains(token)) break;
      if (_isVerb(token)) break;
      words.insert(0, token);
    }

    if (words.isEmpty) return null;
    return '${_capitalize(words.join(' '))} uchun';
  }

  // --- Yordamchilar ----------------------------------------------------------

  static bool _isNumberWord(String token) =>
      RegExp(r'^\d+$').hasMatch(token) ||
      _units.containsKey(token) ||
      _scales.containsKey(token) ||
      _halfWords.contains(token);

  static bool _isVerb(String token) =>
      _iTookVerbs.contains(token) ||
      _iGaveVerbs.contains(token) ||
      _theyGaveVerbs.contains(token) ||
      _theyTookVerbs.contains(token);

  /// So'z [suffix] bilan tugaganini va o'zagi yetarlicha uzunligini tekshiradi.
  static bool _hasSuffix(String token, String suffix) =>
      token.length >= suffix.length + 2 && token.endsWith(suffix);

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
