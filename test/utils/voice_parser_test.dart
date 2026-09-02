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
}
