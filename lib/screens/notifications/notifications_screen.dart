import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/notification_history.dart';
import '../../utils/time_utils.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';

/// Kelgan bildirishnomalar ro'yxati (Bosh sahifadagi qo'ng'iroqchadan).
///
/// Ochilganda hammasi o'qilgan deb belgilanadi — qo'ng'iroqchadagi raqam
/// yo'qoladi.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const NotificationsScreen(),
      ),
    );
  }

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationHistoryProvider.notifier).markAllSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final List<NotificationRecord> received = NotificationHistory.received(
      ref.watch(notificationHistoryProvider),
      DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirishnomalar'),
        actions: <Widget>[
          if (received.isNotEmpty)
            TextButton(
              onPressed: () => ref
                  .read(notificationHistoryProvider.notifier)
                  .clearReceived(),
              child: Text(
                'Tozalash',
                style: context.text.labelLarge?.copyWith(color: theme.blue),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: received.isEmpty
            ? const Center(
                child: EmptyState(
                  icon: IconsaxPlusLinear.notification,
                  title: 'Hozircha bildirishnoma yo\'q',
                  message: 'Ish vaqti eslatmalari shu yerda ko\'rinadi.',
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                itemCount: received.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) =>
                    _NotificationTile(record: received[index]),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.record});

  final NotificationRecord record;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final (IconData icon, Color color) = switch (record.kind) {
      ReminderKind.beforeStart => (IconsaxPlusLinear.timer_1, theme.yellow),
      ReminderKind.start => (IconsaxPlusLinear.login, theme.blue),
      ReminderKind.end => (IconsaxPlusLinear.logout, theme.green),
    };

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(record.title, style: context.text.titleSmall),
                    ),
                    const SizedBox(width: 8),
                    Text(_when(record.at), style: context.text.labelSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(record.body, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "09:00" (bugun), "Kecha, 09:00" yoki "Dush, 1-sen, 09:00".
  static String _when(DateTime at) {
    final DateTime now = DateTime.now();
    final String time = Formatters.time(at);
    if (TimeUtils.isSameDay(at, now)) return time;
    if (TimeUtils.isSameDay(at, now.subtract(const Duration(days: 1)))) {
      return 'Kecha, $time';
    }
    return '${Formatters.shortDayLabel(at)}, $time';
  }
}
