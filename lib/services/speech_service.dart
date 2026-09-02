import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Nutqni matnga o'girish (PROJECT.md 5.3).
///
/// Qurilmaning o'z tanish tizimidan foydalanadi. O'zbek tili mavjud
/// bo'lmasa, [resolveLocaleId] mavjud tillardan eng mosini tanlaydi —
/// ekranda esa foydalanuvchiga qo'lda kiritish taklif qilinadi.
class SpeechService {
  SpeechService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  bool _available = false;

  bool get isAvailable => _available;

  bool get isListening => _speech.isListening;

  /// Afzal ko'riladigan tillar tartibi: o'zbek → rus → qurilma tili.
  static const List<String> preferredLocales = <String>['uz', 'ru'];

  /// Bir marta ishga tushiradi. Mikrofon ruxsati shu yerda so'raladi.
  Future<bool> initialize({void Function(String message)? onError}) async {
    if (_available) return true;
    _available = await _speech.initialize(
      onError: (SpeechRecognitionError error) =>
          onError?.call(_messageFor(error)),
    );
    return _available;
  }

  /// Tanlangan til haqida ma'lumot — foydalanuvchiga ko'rsatish uchun.
  Future<SpeechLocale> resolveLocale() async {
    if (!_available) return const SpeechLocale.systemDefault();

    final List<LocaleName> locales = await _speech.locales();
    for (final String preferred in preferredLocales) {
      for (final LocaleName locale in locales) {
        if (locale.localeId.toLowerCase().startsWith(preferred)) {
          return SpeechLocale(
            id: locale.localeId,
            name: locale.name,
            isUzbek: preferred == 'uz',
          );
        }
      }
    }
    return const SpeechLocale.systemDefault();
  }

  /// Tinglashni boshlaydi.
  ///
  /// [onResult] qisman va yakuniy natijalarni oladi.
  /// [onSoundLevel] mikrofon darajasini beradi — ekrandagi to'lqin
  /// animatsiyasi shu qiymatga qarab harakatlanadi, foydalanuvchi ilova
  /// uni eshitayotganini ko'rib turadi.
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
    void Function(double level)? onSoundLevel,
    String? localeId,
  }) async {
    if (!_available) return;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) =>
          onResult(result.recognizedWords, result.finalResult),
      onSoundLevelChange: onSoundLevel,
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();

  static String _messageFor(SpeechRecognitionError error) {
    switch (error.errorMsg) {
      case 'error_permission':
      case 'error_speech_timeout':
        return 'Mikrofon ruxsati berilmagan yoki ovoz eshitilmadi.';
      case 'error_no_match':
        return 'Nutq tanilmadi. Qaytadan gapiring yoki qo\'lda kiriting.';
      case 'error_network':
        return 'Nutqni tanish uchun internet kerak.';
      default:
        return 'Ovozni tanishda xatolik: ${error.errorMsg}';
    }
  }
}

/// Nutqni tanish uchun tanlangan til.
class SpeechLocale {
  const SpeechLocale({
    required this.id,
    required this.name,
    required this.isUzbek,
  });

  /// Mos til topilmadi — qurilmaning tizim tili ishlatiladi.
  const SpeechLocale.systemDefault()
      : id = null,
        name = 'Qurilma tili',
        isUzbek = false;

  final String? id;
  final String name;
  final bool isUzbek;
}
