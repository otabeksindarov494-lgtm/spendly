import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/models/public_profile_model.dart';
import 'package:spendly/services/chat_service.dart';

void main() {
  group('chatIdFor', () {
    test('tartibdan qat\'i nazar bir xil id beradi', () {
      expect(
        ChatService.chatIdFor('aaa', 'bbb'),
        ChatService.chatIdFor('bbb', 'aaa'),
      );
    });

    test('id ikkala uid\'ni ham o\'z ichiga oladi', () {
      final String id = ChatService.chatIdFor('bbb', 'aaa');
      expect(id, 'aaa__bbb');
    });

    test('turli juftliklar turli id beradi', () {
      expect(
        ChatService.chatIdFor('aaa', 'bbb'),
        isNot(ChatService.chatIdFor('aaa', 'ccc')),
      );
    });
  });

  group('participantsFor', () {
    test('har doim saralangan qaytadi', () {
      expect(ChatService.participantsFor('zzz', 'aaa'), <String>['aaa', 'zzz']);
      expect(ChatService.participantsFor('aaa', 'zzz'), <String>['aaa', 'zzz']);
    });
  });

  group('PublicProfile.initials', () {
    PublicProfile named(String name) =>
        PublicProfile(userId: 'u', fullName: name);

    test('ism va familiyadan ikki harf', () {
      expect(named('Azizbek Erkinov').initials, 'AE');
    });

    test('bitta so\'zdan bitta harf', () {
      expect(named('Azizbek').initials, 'A');
    });

    test('ortiqcha bo\'shliqlar buzmaydi', () {
      expect(named('  azizbek   erkinov  ').initials, 'AE');
    });

    test('bo\'sh ism uchun savol belgisi', () {
      expect(named('').initials, '?');
      expect(named('   ').initials, '?');
    });
  });
}
