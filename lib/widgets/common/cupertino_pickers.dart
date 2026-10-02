import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// iOS uslubidagi yumshoq sana va vaqt tanlagichlar.
///
/// Material'ning `showDatePicker` / `showTimePicker` oynalari qo'pol va
/// og'ir chiqadi. Bu yerda `CupertinoDatePicker` g'ildiragi pastdan
/// chiqadigan varaqda ko'rsatiladi — barmoq bilan surish yengil,
/// harakat silliq.
///
/// **Eslatma:** matn klaviaturasining o'zini ilova almashtira olmaydi —
/// u tizim IME'si (Gboard va h.k.). Bu yerda ilova boshqaradigan
/// hamma narsa iOS uslubiga keltirilgan.
abstract final class SoftPickers {
  /// Sana tanlash. Bekor qilinsa `null`.
  static Future<DateTime?> pickDate({
    required BuildContext context,
    required String title,
    required DateTime initial,
    required DateTime first,
    required DateTime last,
  }) {
    DateTime selected = initial.isBefore(first)
        ? first
        : (initial.isAfter(last) ? last : initial);

    return _showWheel<DateTime>(
      context: context,
      title: title,
      onDone: () => selected,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: selected,
        minimumDate: first,
        maximumDate: last,
        onDateTimeChanged: (DateTime value) => selected = value,
      ),
    );
  }

  /// Vaqt tanlash. Yarim tundan boshlab daqiqalarda qaytaradi.
  static Future<int?> pickTimeMinutes({
    required BuildContext context,
    required String title,
    required int initialMinutes,
  }) {
    final DateTime base = DateTime(
      2026,
      1,
      1,
      initialMinutes ~/ 60,
      initialMinutes % 60,
    );
    DateTime selected = base;

    return _showWheel<int>(
      context: context,
      title: title,
      onDone: () => selected.hour * 60 + selected.minute,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: base,
        use24hFormat: true,
        minuteInterval: 1,
        onDateTimeChanged: (DateTime value) => selected = value,
      ),
    );
  }

  static Future<T?> _showWheel<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    required T Function() onDone,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final CustomTheme theme = sheetContext.theme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.borderGray)),
                ),
                child: Row(
                  children: <Widget>[
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(
                        'Bekor qilish',
                        style: TextStyle(fontSize: 15, color: theme.textGray),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.mainDarkBlue,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(sheetContext).pop(onDone());
                      },
                      child: Text(
                        'Tayyor',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 216,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(sheetContext).brightness,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 20,
                        color: theme.mainDarkBlue,
                      ),
                    ),
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
