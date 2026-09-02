import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/debt_model.dart';
import '../../providers/core_providers.dart';
import '../../services/speech_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/voice_parser.dart';
import '../../widgets/common/app_button.dart';
import 'debt_form.dart';

/// Ovoz orqali qarz qo'shish (PROJECT.md 5.3).
///
/// Oqim: tinglash → matnni tahlil qilish → **tasdiqlash formasi** → saqlash.
/// Tasdiqlash bosqichi majburiy (PROJECT.md 10.8) — mahalliy parsing
/// xato qilishi mumkin.
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
  ParsedDebt? _parsed;
  bool _isSaving = false;
  String? _errorMessage;

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

    final String? localeId = await _speech.resolveLocaleId();
    if (!mounted) return;

    setState(() {
      _phase = _Phase.listening;
      _recognizedText = '';
    });

    await _speech.listen(
      localeId: localeId,
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      switch (_phase) {
                        _Phase.review => 'Tekshiring va tasdiqlang',
                        _Phase.unavailable => 'Ovoz mavjud emas',
                        _ => 'Gapiring...',
                      },
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: theme.mainDarkBlue,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(BootstrapIcons.x_lg, color: theme.textGray),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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

  Widget _buildPreparing(CustomTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator(color: theme.blue)),
    );
  }

  Widget _buildListening(CustomTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Masalan: "Alisherdan 30 ming so\'m oldim"',
          style: TextStyle(fontSize: 12, color: theme.textGray),
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: theme.blue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(BootstrapIcons.mic_fill, size: 44, color: theme.blue),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.inputColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _recognizedText.isEmpty ? 'Tinglanmoqda...' : _recognizedText,
            style: TextStyle(
              fontSize: 14,
              color: _recognizedText.isEmpty
                  ? theme.textGray
                  : theme.mainDarkBlue,
            ),
          ),
        ),
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
          style: TextStyle(fontSize: 13, color: theme.textGray, height: 1.45),
        ),
        const SizedBox(height: 20),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.inputColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Icon(BootstrapIcons.soundwave, size: 16, color: theme.textGray),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    parsed.rawText,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: theme.textGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (parsed.needsReview)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: <Widget>[
                Icon(BootstrapIcons.info_circle, size: 16, color: theme.yellow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ba\'zi maydonlar aniqlanmadi — qo\'lda to\'ldiring.',
                    style: TextStyle(fontSize: 11, color: theme.textGray),
                  ),
                ),
              ],
            ),
          ),
        DebtForm(
          initialName: parsed.personName,
          initialAmount: parsed.amount,
          initialType: parsed.type,
          submitLabel: 'Tasdiqlash va saqlash',
          isSaving: _isSaving,
          onSubmit: _save,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Qaytadan gapirish',
          variant: AppButtonVariant.text,
          height: 44,
          onPressed: _isSaving ? null : _start,
        ),
      ],
    );
  }
}
