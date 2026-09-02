import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Amalning joriy bosqichi.
class TaskStep {
  const TaskStep(this.label, this.value);

  final String label;

  /// 0.0 – 1.0.
  final double value;
}

/// Bosqich haqida xabar beruvchi funksiya tipi.
typedef ProgressReporter = void Function(String label, double value);

/// Uzoq davom etadigan amalni progress oynasi bilan bajaradi.
///
/// Foiz ataylab "soxta" emas: har bir bosqich haqiqiy ish birligiga mos
/// keladi (masalan rasmni siqish, so'ng Firestore'ga yozish). Shuning
/// uchun bosqichlarni chaqiruvchi kod o'zi e'lon qiladi.
///
/// Amal tugaguncha oyna yopilmaydi va orqa fon bosilmaydi — foydalanuvchi
/// "hech narsa bo'lmadi" deb o'ylab qolmaydi.
Future<T?> runWithProgress<T>({
  required BuildContext context,
  required String title,
  required Future<T> Function(ProgressReporter report) task,
}) async {
  final ValueNotifier<TaskStep> step = ValueNotifier<TaskStep>(
    const TaskStep('Boshlanmoqda...', 0.05),
  );

  final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
  bool dialogOpen = true;

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: _ProgressDialog(title: title, step: step),
      ),
    ).then((_) => dialogOpen = false),
  );

  try {
    final T result = await task(
      (String label, double value) =>
          step.value = TaskStep(label, value.clamp(0.0, 1.0)),
    );
    step.value = const TaskStep('Tayyor', 1);
    // Foydalanuvchi 100% ni ko'rib ulgursin.
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return result;
  } finally {
    if (dialogOpen && navigator.canPop()) navigator.pop();
    step.dispose();
  }
}

class _ProgressDialog extends StatelessWidget {
  const _ProgressDialog({required this.title, required this.step});

  final String title;
  final ValueNotifier<TaskStep> step;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return Dialog(
      backgroundColor: theme.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: ValueListenableBuilder<TaskStep>(
          valueListenable: step,
          builder: (BuildContext context, TaskStep current, Widget? child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.mainDarkBlue,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    tween: Tween<double>(begin: 0, end: current.value),
                    builder: (BuildContext context, double value, Widget? _) =>
                        LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: theme.borderGray,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.blue),
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        current.label,
                        style: TextStyle(fontSize: 12, color: theme.textGray),
                      ),
                    ),
                    Text(
                      '${(current.value * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.blue,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
