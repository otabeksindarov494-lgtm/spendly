import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/models/debt_model.dart';
import 'package:spendly/utils/voice_parser.dart';

void main() {
  group('summa ajratish', () {
    test('"30 ming" → 30000', () {
      expect(VoiceParser.parse('Alisherdan 30 ming so\'m oldim').amount, 30000);
    });

    test('"500 ming" → 500000', () {
      expect(VoiceParser.parse('Boburga 500 ming berdim').amount, 500000);
    });

    test('"bir million" → 1000000', () {
      expect(VoiceParser.parse('Nodirdan bir million oldim').amount, 1000000);
    });

    test('"o\'n besh ming" → 15000', () {
      expect(VoiceParser.parse('Akmaldan o\'n besh ming oldim').amount, 15000);
    });

    test('"ikki yuz ming" → 200000', () {
      expect(VoiceParser.parse('Sardorga ikki yuz ming berdim').amount, 200000);
    });

    test('"bir million ikki yuz ming" → 1200000', () {
      expect(
        VoiceParser.parse('Jasurdan bir million ikki yuz ming oldim').amount,
        1200000,
      );
    });

    test('bo\'lingan raqam "2 500 000" birlashtiriladi', () {
      expect(VoiceParser.parse('Otabekka 2 500 000 berdim').amount, 2500000);
    });

    test('summa yo\'q bo\'lsa null', () {
      expect(VoiceParser.parse('Alisherdan qarz oldim').amount, isNull);
    });
  });

  group('yo\'nalish ajratish', () {
    test('"oldim" → men qarzdorman (i_owe)', () {
      expect(
        VoiceParser.parse('Alisherdan 30 ming so\'m oldim').type,
        DebtType.iOwe,
      );
    });

    test('"berdim" → menga qarz (owed_to_me)', () {
      expect(
        VoiceParser.parse('Boburga 500 ming berdim').type,
        DebtType.owedToMe,
      );
    });

    test('"u menga berdi" → men qarzdorman', () {
      expect(
        VoiceParser.parse('Alisher menga 30 ming berdi').type,
        DebtType.iOwe,
      );
    });

    test('"u mendan oldi" → menga qarz', () {
      expect(
        VoiceParser.parse('Alisher mendan 30 ming oldi').type,
        DebtType.owedToMe,
      );
    });

    test('fe\'lsiz "-dan" qo\'shimchasi → men qarzdorman', () {
      expect(VoiceParser.parse('Alisherdan 30 ming').type, DebtType.iOwe);
    });

    test('fe\'lsiz "-ga" qo\'shimchasi → menga qarz', () {
      expect(VoiceParser.parse('Alisherga 30 ming').type, DebtType.owedToMe);
    });

    test('belgi topilmasa null (foydalanuvchi o\'zi tanlaydi)', () {
      expect(VoiceParser.parse('30 ming').type, isNull);
    });
  });

  group('ism ajratish', () {
    test('"-dan" qo\'shimchasi olib tashlanadi', () {
      expect(
        VoiceParser.parse('Alisherdan 30 ming oldim').personName,
        'Alisher',
      );
    });

    test('"-ga" qo\'shimchasi olib tashlanadi', () {
      expect(
        VoiceParser.parse('Boburga 500 ming berdim').personName,
        'Bobur',
      );
    });

    test('"-ka" qo\'shimchasi olib tashlanadi', () {
      expect(
        VoiceParser.parse('Otabekka 100 ming berdim').personName,
        'Otabek',
      );
    });

    test('qo\'shimchasiz ism ham topiladi', () {
      expect(
        VoiceParser.parse('Alisher menga 30 ming berdi').personName,
        'Alisher',
      );
    });

    test('olmoshlar ism deb olinmaydi', () {
      expect(VoiceParser.parse('menga 30 ming berdi').personName, isNull);
    });

    test('bosh harf bilan qaytariladi', () {
      expect(
        VoiceParser.parse('alisherdan 30 ming oldim').personName,
        'Alisher',
      );
    });
  });

  group('to\'liq natija', () {
    test('to\'liq gap uchta maydonni ham beradi', () {
      final ParsedDebt result =
          VoiceParser.parse('Alisherdan 30 ming so\'m oldim');
      expect(result.personName, 'Alisher');
      expect(result.amount, 30000);
      expect(result.type, DebtType.iOwe);
      expect(result.isComplete, isTrue);
      expect(result.needsReview, isFalse);
    });

    test('bo\'sh matn hech narsa qaytarmaydi va crash bo\'lmaydi', () {
      final ParsedDebt result = VoiceParser.parse('');
      expect(result.personName, isNull);
      expect(result.amount, isNull);
      expect(result.type, isNull);
      expect(result.needsReview, isTrue);
    });

    test('tinish belgilari va turli apostroflar buzmaydi', () {
      final ParsedDebt result =
          VoiceParser.parse('Alisherdan 30 ming so‘m oldim!');
      expect(result.personName, 'Alisher');
      expect(result.amount, 30000);
      expect(result.type, DebtType.iOwe);
    });
  });

  enhancedParserTests();
}

/// Kuchaytirilgan parser: kirill, "yarim", qo'shilib yozilgan raqamlar,
/// izoh va ishonch darajasi.
void enhancedParserTests() {
  group('kirill alifbo', () {
    test('kirillcha gap ham tahlil qilinadi', () {
      final ParsedDebt result = VoiceParser.parse('Алишердан 30 минг олдим');
      expect(result.personName, 'Alisher');
      expect(result.amount, 30000);
      expect(result.type, DebtType.iOwe);
    });

    test('ў va қ harflari to\'g\'ri o\'giriladi', () {
      expect(VoiceParser.tokenize('ўн'), <String>['o\'n']);
      expect(VoiceParser.tokenize('қирқ'), <String>['qirq']);
    });
  });

  group('"yarim" bilan summalar', () {
    test('"yarim million" → 500 000', () {
      expect(VoiceParser.parse('Alisherga yarim million berdim').amount, 500000);
    });

    test('"bir yarim million" → 1 500 000', () {
      expect(
        VoiceParser.parse('Alisherdan bir yarim million oldim').amount,
        1500000,
      );
    });

    test('"yarim ming" → 500', () {
      expect(VoiceParser.parse('Alisherga yarim ming berdim').amount, 500);
    });
  });

  group('qo\'shilib yozilgan raqamlar', () {
    test('"30ming" ajratiladi', () {
      expect(VoiceParser.parse('Alisherdan 30ming oldim').amount, 30000);
    });

    test('"5mln" ajratiladi', () {
      expect(VoiceParser.parse('Alisherga 5mln berdim').amount, 5000000);
    });
  });

  group('yangi fe\'l shakllari', () {
    test('"olganman" → men qarzdorman', () {
      expect(
        VoiceParser.parse('Alisherdan 30 ming olganman').type,
        DebtType.iOwe,
      );
    });

    test('"berganman" → menga qarz', () {
      expect(
        VoiceParser.parse('Alisherga 30 ming berganman').type,
        DebtType.owedToMe,
      );
    });

    test('"olishdi" → menga qarz', () {
      expect(
        VoiceParser.parse('Alisher mendan 30 ming olishdi').type,
        DebtType.owedToMe,
      );
    });
  });

  group('qo\'shimcha kelishiklar', () {
    test('"-ni" qo\'shimchasi olib tashlanadi', () {
      expect(
        VoiceParser.parse('Alisherni 30 ming qarzi bor').personName,
        'Alisher',
      );
    });

    test('"-ning" qo\'shimchasi olib tashlanadi', () {
      expect(
        VoiceParser.parse('Alisherning 30 ming qarzi bor').personName,
        'Alisher',
      );
    });
  });

  group('izoh ajratish', () {
    test('"kitob uchun" izoh sifatida olinadi', () {
      final ParsedDebt result =
          VoiceParser.parse('Alisherga 50 ming kitob uchun berdim');
      expect(result.description, 'Kitob uchun');
      expect(result.amount, 50000);
      expect(result.personName, 'Alisher');
    });

    test('"uchun" bo\'lmasa izoh null', () {
      expect(
        VoiceParser.parse('Alisherga 50 ming berdim').description,
        isNull,
      );
    });
  });

  group('ishonch darajasi', () {
    test('to\'liq va fe\'lli gap yuqori ishonch beradi', () {
      final ParsedDebt result =
          VoiceParser.parse('Alisherdan 30 ming so\'m oldim');
      expect(result.confidence, greaterThanOrEqualTo(0.95));
      expect(result.needsReview, isFalse);
    });

    test('fe\'lsiz gapda ishonch pasayadi', () {
      final ParsedDebt result = VoiceParser.parse('Alisherdan 30 ming');
      expect(result.confidence, lessThan(0.95));
      expect(result.needsReview, isTrue);
    });

    test('bo\'sh matnda ishonch 0', () {
      expect(VoiceParser.parse('').confidence, 0);
    });

    test('faqat summa bo\'lsa ishonch past', () {
      final ParsedDebt result = VoiceParser.parse('30 ming');
      expect(result.confidence, lessThan(0.6));
    });
  });
}
