import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/debt_model.dart';
import '../../providers/core_providers.dart';
import '../../services/speech_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/voice_parser.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/voice_waveform.dart';
import 'debt_form.dart';

/// Ovoz orqali qarz qo'shish (PROJECT.md 5.3).
///
/// Oqim: tinglash → matnni tahlil qilish → **tasdiqlash formasi** → saqlash.
/// Tasdiqlash bosqichi majburiy (PROJECT.md 10.8).
///
/// Butunlay tekin ishlaydi: nutqni qurilmaning o'z tizimi taniydi,
/// tahlilni [VoiceParser] mahalliy bajaradi. Ovoz qurilmadan chiqmaydi.
class VoiceDebtSheet extends ConsumerStatefulWidget {
  const VoiceDebtSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) => const VoiceDebtSheet(),
    );
  }

  @override
  ConsumerState<VoiceDebtSheet> createState() => _VoiceDebtSheetState();
}

enum _Phase { preparing, listening, review, unavailable }

class _VoiceDebtSheetState extends ConsumerState<VoiceDebtSheet> {
  late final SpeechService _speech = ref.read(speechServiceProvider);

  _Phase _phase = _Phase.preparing;
  String _recognizedText = '';
  double _soundLevel = 0;
  SpeechLocale _locale = const SpeechLocale.systemDefault();
  ParsedDebt? _parsed;
  bool _isSaving = false;
  String? _errorMessage;

  /// Foydalanuvchiga ko'rsatiladigan misollar — nima deyish mumkinligi
  /// aniq bo'lsin.
  static const List<String> _examples = <String>[
    'Alisherdan 30 ming so\'m oldim',
    'Boburga yarim million berdim',
    'Nodirga 50 ming kitob uchun berdim',
  ];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    // Oyna yopilganda mikrofon bo'sh qolishi shart.
    _speech.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.preparing;
      _errorMessage = null;
      _recognizedText = '';
      _soundLevel = 0;
    });

    final bool ready = await _speech.initialize(
      onError: (String message) {
        if (!mounted) return;
        setState(() => _errorMessage = message);
      },
    );

    if (!mounted) return;
    if (!ready) {
      setState(() => _phase = _Phase.unavailable);
      return;
    }

    final SpeechLocale locale = await _speech.resolveLocale();
    if (!mounted) return;

    setState(() {
      _locale = locale;
      _phase = _Phase.listening;
    });

    await _speech.listen(
      localeId: locale.id,
      onSoundLevel: (double level) {
        if (mounted) setState(() => _soundLevel = level);
      },
      onResult: (String text, bool isFinal) {
        if (!mounted) return;
        setState(() => _recognizedText = text);
        if (isFinal) _review(text);
      },
    );
  }

  Future<void> _stopAndReview() async {
    await _speech.stop();
    if (!mounted) return;
    _review(_recognizedText);
  }

  void _review(String text) {
    setState(() {
      _parsed = VoiceParser.parse(text);
      _phase = _Phase.review;
      _soundLevel = 0;
    });
  }

  Future<void> _save({
    required String personName,
    required double amount,
    required DebtType type,
    String? description,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(debtServiceProvider).add(
            userId: userId,
            personName: personName,
            amount: amount,
            type: type,
            description: description,
            createdVia: DebtSource.voice,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Saqlashda xatolik: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- Qurish ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeader(theme),
              const SizedBox(height: 14),
              switch (_phase) {
                _Phase.preparing => _buildPreparing(theme),
                _Phase.listening => _buildListening(theme),
                _Phase.unavailable => _buildUnavailable(theme),
                _Phase.review => _buildReview(theme),
              },
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(fontSize: 12, color: theme.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CustomTheme theme) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                switch (_phase) {
                  _Phase.review => 'Tekshiring va tasdiqlang',
                  _Phase.unavailable => 'Ovoz mavjud emas',
                  _Phase.preparing => 'Tayyorlanmoqda...',
                  _Phase.listening => 'Tinglayapman',
                },
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.mainDarkBlue,
                ),
              ),
              if (_phase == _Phase.listening) ...<Widget>[
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Icon(
                      BootstrapIcons.globe2,
                      size: 11,
                      color: _locale.isUzbek ? theme.green : theme.yellow,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _locale.isUzbek
                          ? 'O\'zbek tili'
                          : '${_locale.name} — o\'zbek tili topilmadi',
                      style: TextStyle(fontSize: 11, color: theme.textGray),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: Icon(BootstrapIcons.x_lg, size: 16, color: theme.textGray),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildPreparing(CustomTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Center(child: CircularProgressIndicator(color: theme.blue)),
    );
  }

  Widget _buildListening(CustomTheme theme) {
    final bool hasText = _recognizedText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        VoiceWaveform(level: _soundLevel),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.inputColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderGray),
          ),
          child: Text(
            hasText ? _recognizedText : 'Gapiring...',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              fontWeight: hasText ? FontWeight.w600 : FontWeight.w400,
              color: hasText ? theme.mainDarkBlue : theme.textGray,
            ),
          ),
        ),
        if (!hasText) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            'Masalan:',
            style: TextStyle(fontSize: 11, color: theme.textGray),
          ),
          const SizedBox(height: 6),
          for (final String example in _examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '· $example',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.favoriteGray,
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
        AppButton(
          label: 'Tugatdim',
          icon: BootstrapIcons.stop_fill,
          onPressed: _stopAndReview,
        ),
      ],
    );
  }

  Widget _buildUnavailable(CustomTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Qurilmangizda nutqni tanish ishlamadi. Mikrofon ruxsatini '
          'tekshiring yoki qarzni qo\'lda kiriting.',
          style: TextStyle(fontSize: 13, color: theme.textGray, height: 1.5),
        ),
        const SizedBox(height: 18),
        AppButton(
          label: 'Qayta urinish',
          icon: BootstrapIcons.mic_fill,
          variant: AppButtonVariant.secondary,
          onPressed: _start,
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Qo\'lda kiritish',
          icon: BootstrapIcons.pencil_square,
          onPressed: () => setState(() {
            _parsed = const ParsedDebt(rawText: '');
            _phase = _Phase.review;
          }),
        ),
      ],
    );
  }

  Widget _buildReview(CustomTheme theme) {
    final ParsedDebt parsed = _parsed ?? const ParsedDebt(rawText: '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (parsed.rawText.isNotEmpty) ...<Widget>[
          _buildTranscript(theme, parsed),
          const SizedBox(height: 12),
        ],
        if (parsed.needsReview) _buildReviewWarning(theme, parsed),
        DebtForm(
          initialName: parsed.personName,
          initialAmount: parsed.amount,
          initialType: parsed.type,
          initialDescription: parsed.description,
          submitLabel: 'Tasdiqlash va saqlash',
          isSaving: _isSaving,
          onSubmit: _save,
        ),
        const SizedBox(height: 6),
        AppButton(
          label: 'Qaytadan gapirish',
          icon: BootstrapIcons.mic_fill,
          variant: AppButtonVariant.text,
          height: 44,
          onPressed: _isSaving ? null : _start,
        ),
      ],
    );
  }

  /// Tanilgan matn va ishonch darajasi.
  Widget _buildTranscript(CustomTheme theme, ParsedDebt parsed) {
    final Color confidenceColor = parsed.confidence >= 0.9
        ? theme.green
        : (parsed.confidence >= 0.6 ? theme.yellow : theme.red);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.inputColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                BootstrapIcons.soundwave,
                size: 13,
                color: theme.textGray,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Eshitilgan matn',
                  style: TextStyle(fontSize: 11, color: theme.textGray),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: confidenceColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Aniqlik ${(parsed.confidence * 100).round()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: confidenceColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            parsed.rawText,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontStyle: FontStyle.italic,
              color: theme.mainDarkBlue,
            ),
          ),
          if (parsed.isComplete) ...<Widget>[
            const SizedBox(height: 10),
            Divider(color: theme.borderGray, height: 1),
            const SizedBox(height: 10),
            Text(
              '${parsed.personName} · '
              '${Formatters.money(parsed.amount!)} · '
              '${parsed.type == DebtType.iOwe ? 'Men qarzdorman' : 'Menga qarz'}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: parsed.type == DebtType.iOwe
                    ? theme.red
                    : theme.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewWarning(CustomTheme theme, ParsedDebt parsed) {
    final String message = parsed.isComplete
        ? 'Yo\'nalish gapdagi qo\'shimchadan taxmin qilindi — to\'g\'riligini '
            'tekshiring.'
        : 'Ba\'zi maydonlar aniqlanmadi — qo\'lda to\'ldiring.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            BootstrapIcons.exclamation_triangle,
            size: 13,
            color: theme.yellow,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: theme.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
