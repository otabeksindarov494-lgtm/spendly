import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/time_utils.dart';
import '../../../widgets/common/app_card.dart';
import 'onboarding_step.dart';

/// 6- va 7-qadamlar: ish boshlanish / tugash vaqti.
///
/// Ikkala qadam bir xil ko'rinishda bo'lgani uchun bitta widget
/// parametrlar bilan qayta ishlatiladi.
class WorkTimeStep extends StatelessWidget {
  const WorkTimeStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  final String title;
  final String subtitle;

  /// "09:00" formatida.
  final String value;

  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return OnboardingStep(
      title: title,
      subtitle: subtitle,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        onTap: () => _pick(context),
        child: Row(
          children: <Widget>[
            Icon(icon, color: theme.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: theme.mainDarkBlue,
                ),
              ),
            ),
            Icon(BootstrapIcons.chevron_right, color: theme.textGray),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final int minutes = TimeUtils.minutesFromHmOr(value, 9 * 60);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: title,
      cancelText: 'Bekor qilish',
      confirmText: 'Tanlash',
      builder: (BuildContext context, Widget? child) => MediaQuery(
        // 24 soatlik format — o'zbekcha interfeys uchun tabiiyroq.
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      onChanged(TimeUtils.hmFromMinutes(picked.hour * 60 + picked.minute));
    }
  }
}
