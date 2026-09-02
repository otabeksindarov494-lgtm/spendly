import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/user_profile_model.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/app_text_field.dart';
import 'onboarding_step.dart';

/// Maosh oralig'ini kiritish: slider + aniq raqam.
///
/// Hisob-kitobda oraliqning **o'rtachasi** ishlatiladi
/// ([UserProfile.averageOf]) — foydalanuvchi buni ekranda ko'rib turadi.
class SalaryRangeStep extends StatefulWidget {
  const SalaryRangeStep({
    super.key,
    required this.min,
    required this.max,
    required this.currency,
    required this.onChanged,
  });

  final double min;
  final double max;
  final String currency;

  /// (min, max) juftligini qaytaradi.
  final void Function(double min, double max) onChanged;

  @override
  State<SalaryRangeStep> createState() => _SalaryRangeStepState();
}

class _SalaryRangeStepState extends State<SalaryRangeStep> {
  /// Slider chegarasi. Foydalanuvchi qo'lda kattaroq summa yozsa, chegara
  /// o'sha summaga moslashadi.
  static const double _baseCeiling = 30000000;
  static const double _stepSize = 100000;

  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: _format(widget.min));
    _maxController = TextEditingController(text: _format(widget.max));
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  static String _format(double value) =>
      value <= 0 ? '' : Formatters.number(value);

  double get _ceiling {
    final double highest = widget.max > widget.min ? widget.max : widget.min;
    if (highest <= _baseCeiling) return _baseCeiling;
    // Yuqori chegaradan oshsa, keyingi 10 mln ga yaxlitlaymiz.
    return ((highest / 10000000).ceil() * 10000000).toDouble();
  }

  void _emit(double min, double max) {
    // Chegaralar joyini almashtirib yubormasin.
    final double lo = min <= max ? min : max;
    final double hi = min <= max ? max : min;
    widget.onChanged(lo, hi);
  }

  void _onSlider(RangeValues values) {
    setState(() {
      _minController.text = _format(values.start);
      _maxController.text = _format(values.end);
    });
    _emit(values.start, values.end);
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final double ceiling = _ceiling;
    final double average = UserProfile.averageOf(widget.min, widget.max);

    return OnboardingStep(
      title: 'Oylik maoshingiz qancha?',
      subtitle: 'Kelishilgan oraliqni kiriting. Hisob-kitobda shu '
          'oraliqning o\'rtachasi ishlatiladi.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: AppTextField(
                  controller: _minController,
                  label: 'Eng kam',
                  hint: '4 000 000',
                  keyboardType: TextInputType.number,
                  inputFormatters: const <TextInputFormatter>[
                    ThousandsFormatter(),
                  ],
                  onChanged: (String value) => _emit(
                    ThousandsFormatter.parse(value),
                    widget.max,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _maxController,
                  label: 'Eng ko\'p',
                  hint: '5 000 000',
                  keyboardType: TextInputType.number,
                  inputFormatters: const <TextInputFormatter>[
                    ThousandsFormatter(),
                  ],
                  onChanged: (String value) => _emit(
                    widget.min,
                    ThousandsFormatter.parse(value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          RangeSlider(
            values: RangeValues(
              widget.min.clamp(0, ceiling),
              widget.max.clamp(0, ceiling),
            ),
            max: ceiling,
            divisions: (ceiling / _stepSize).round(),
            activeColor: theme.blue,
            inactiveColor: theme.borderGray,
            labels: RangeLabels(
              Formatters.number(widget.min),
              Formatters.number(widget.max),
            ),
            onChanged: _onSlider,
          ),
          Row(
            children: <Widget>[
              Text(
                '0',
                style: TextStyle(fontSize: 11, color: theme.textGray),
              ),
              const Spacer(),
              Text(
                '${(ceiling / 1000000).round()} mln',
                style: TextStyle(fontSize: 11, color: theme.textGray),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.blue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Hisob-kitobda ishlatiladi',
                  style: TextStyle(fontSize: 11, color: theme.textGray),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.money(average, currency: widget.currency),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
