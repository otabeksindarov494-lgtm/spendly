import 'package:bootstrap_icons/bootstrap_icons.dart';
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
        (BootstrapIcons.house, BootstrapIcons.house_fill, 'Bosh sahifa'),
        (BootstrapIcons.bar_chart, BootstrapIcons.bar_chart_fill, 'Hisobot'),
        (BootstrapIcons.chat_dots, BootstrapIcons.chat_dots_fill, 'Chat'),
        (BootstrapIcons.wallet2, BootstrapIcons.wallet_fill, 'Qarzlar'),
        (BootstrapIcons.person, BootstrapIcons.person_fill, 'Profil'),
      ];

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavBg,
          border: Border(top: BorderSide(color: theme.borderGray)),
        ),
        child: SafeArea(
          top: false,
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
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
