import 'dart:typed_data';

import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile_model.dart';
import '../../providers/core_providers.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/image_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/menu_card.dart';
import '../../widgets/common/shimmer_box.dart';
import 'all_data_screen.dart';
import 'manual_attendance_screen.dart';
import 'profile_edit_sheets.dart';
import 'settings_screen.dart';

/// 5-tab: profil.
///
/// Ataylab sodda: dumaloq avatar, ism va bir nechta karta. Har bir
/// bo'lim o'z ekraniga chiqarilgan — bitta ekranga hamma narsani
/// tiqishtirish o'qishni qiyinlashtiradi.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile?> profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        top: false,
        child: profileAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(itemCount: 5, itemHeight: 74),
          ),
          error: (Object e, StackTrace _) =>
              ErrorView(message: 'Profil yuklanmadi: $e'),
          data: (UserProfile? profile) => profile == null
              ? const ErrorView(message: 'Profil topilmadi.')
              : _buildBody(context, ref, profile),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, UserProfile profile) {
    final CustomTheme theme = context.theme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: <Widget>[
        _buildAvatar(context, ref, theme, profile),
        const SizedBox(height: 16),
        Text(
          profile.fullName.trim().isEmpty
              ? 'Ism kiritilmagan'
              : profile.fullName.trim(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: theme.mainDarkBlue,
          ),
        ),
        if (_subtitle(profile).isNotEmpty) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            _subtitle(profile),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: theme.textGray),
          ),
        ],
        const SizedBox(height: 30),
        MenuCard(
          icon: BootstrapIcons.person_vcard,
          title: 'Barcha ma\'lumotlar',
          subtitle: 'Shaxsiy, ish joyi, maosh va ish jadvali',
          onTap: () => AllDataScreen.open(context),
        ),
        MenuCard(
          icon: BootstrapIcons.calendar_plus,
          title: 'Davomat',
          subtitle: 'Qo\'lda kiritish yoki vaqtni tuzatish',
          accentColor: theme.green,
          onTap: () => ManualAttendanceScreen.open(context),
        ),
        MenuCard(
          icon: BootstrapIcons.gear,
          title: 'Sozlamalar',
          subtitle: 'Mavzu, til va ilova versiyasi',
          onTap: () => SettingsScreen.open(context),
        ),
        MenuCard(
          icon: BootstrapIcons.box_arrow_right,
          title: 'Chiqish',
          subtitle: 'Ma\'lumotlaringiz o\'chirilmaydi',
          accentColor: theme.red,
          showChevron: false,
          onTap: () => _confirmLogout(context, ref, theme),
        ),
      ],
    );
  }

  static String _subtitle(UserProfile profile) {
    final List<String> parts = <String>[
      if (profile.position.trim().isNotEmpty) profile.position.trim(),
      if (profile.companyName.trim().isNotEmpty) profile.companyName.trim(),
    ];
    return parts.join(' · ');
  }

  Widget _buildAvatar(
    BuildContext context,
    WidgetRef ref,
    CustomTheme theme,
    UserProfile profile,
  ) {
    final Uint8List? photo = ImageService.decode(profile.profilePhotoBase64);

    return Center(
      child: GestureDetector(
        onTap: () => ProfileEditSheets.changePhoto(context, ref, profile),
        child: Stack(
          children: <Widget>[
            Container(
              width: 104,
              height: 104,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.gray,
                shape: BoxShape.circle,
                border: Border.all(color: theme.borderGray, width: 2),
              ),
              child: photo == null
                  ? Icon(
                      BootstrapIcons.person,
                      size: 42,
                      color: theme.favoriteGray,
                    )
                  : Image.memory(photo, fit: BoxFit.cover),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: theme.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.inputColor, width: 2),
                ),
                child: const Icon(
                  BootstrapIcons.camera_fill,
                  size: 12,
                  color: CustomTheme.onAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    CustomTheme theme,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text(
          'Hisobingizdan chiqmoqchimisiz? Ma\'lumotlaringiz saqlanib '
          'qoladi — qayta kirganingizda hammasi o\'z holicha tiklanadi.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Chiqish', style: TextStyle(color: theme.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(authServiceProvider).signOut();
      // Faqat qurilmadagi keshni tozalaymiz. Firestore'dagi profil,
      // davomat, qarzlar va yozishmalar JOYIDA QOLADI.
      await ref
          .read(sharedPreferencesProvider)
          .remove(ThemeModeNotifier.storageKey);
    }
  }
}
