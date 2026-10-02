import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/widgets/common/app_text_field.dart';

void main() {
  String f(String input) => UzPhoneFormatter.format(input);

  test('mahalliy raqam guruhlanadi va +998 qo\'shiladi', () {
    expect(f('901234567'), '+998 90 123 45 67');
  });

  test('to\'liq raqam (998 bilan) ham to\'g\'ri', () {
    expect(f('+998901234567'), '+998 90 123 45 67');
    expect(f('998 90 123 45 67'), '+998 90 123 45 67');
  });

  test('yozish jarayonida qisman guruhlash', () {
    expect(f('9'), '+998 9');
    expect(f('90'), '+998 90');
    expect(f('9012'), '+998 90 12');
    expect(f('9012345'), '+998 90 123 45');
  });

  test('ortiqcha raqamlar kesiladi', () {
    expect(f('90123456789'), '+998 90 123 45 67');
  });

  test('bo\'sh yoki faqat prefiks — maydon tozalanadi', () {
    expect(f(''), '');
    expect(f('+998 '), '');
    expect(f('+'), '');
  });

  test('99 bilan boshlanuvchi operator kodi yo\'qolmaydi', () {
    // "+998 9" ga yana 9 yozilganda matn "+998 99" bo'ladi.
    expect(f('+998 99'), '+998 99');
    expect(f('+998 99 8'), '+998 99 8');
  });

  test('formatter kursorni oxiriga qo\'yadi', () {
    const UzPhoneFormatter formatter = UzPhoneFormatter();
    final TextEditingValue result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '901'),
    );
    expect(result.text, '+998 90 1');
    expect(result.selection.baseOffset, result.text.length);
  });
}
