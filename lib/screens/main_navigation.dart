import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'chat/chat_list_screen.dart';
import 'debts/debts_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'report/report_screen.dart';

/// Asosiy ilova konteyneri — 4 ta tab (PROJECT.md 5-bo'lim).
///
/// `IndexedStack` ishlatilgan: tab almashganda ekranlar qayta qurilmaydi,
/// scroll holati va Firestore oqimlari saqlanib qoladi.
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _index = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    ReportScreen(),
    ChatListScreen(),
    DebtsScreen(),
    ProfileScreen(),
  ];

  static const List<(IconData, IconData, String)> _tabs =
      <(IconData, IconData, String)>[
        (IconsaxPlusLinear.home_2, IconsaxPlusBold.home_2, 'Bosh sahifa'),
        (IconsaxPlusLinear.chart, IconsaxPlusBold.chart, 'Hisobot'),
        (IconsaxPlusLinear.message, IconsaxPlusBold.message, 'Chat'),
        (
          IconsaxPlusLinear.empty_wallet,
          IconsaxPlusBold.empty_wallet,
          'Qarzlar',
        ),
        (IconsaxPlusLinear.user, IconsaxPlusBold.user, 'Profil'),
      ];

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        // Shisha panel: yarim shaffof, tepasida yorug' chiziq.
        decoration: BoxDecoration(
          color: theme.glassFill,
          border: Border(top: BorderSide(color: theme.glassBorder)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.glassShadow,
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          // Ikki chetdan ozgina ichkariga — chetki tablar ekran qirrasiga
          // yopishmaydi.
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                for (int i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _tabs[i].$1,
                      activeIcon: _tabs[i].$2,
                      label: _tabs[i].$3,
                      isActive: _index == i,
                      onTap: () => setState(() => _index = i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Color color = isActive ? theme.blue : theme.bottomNavBlue;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(isActive ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // labelSmall (12) — eng kichik shkala darajasi; 10 px o'qishga
              // qiyin edi.
              style: context.text.labelSmall?.copyWith(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
