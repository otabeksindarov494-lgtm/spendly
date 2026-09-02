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
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/info_row.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/shimmer_box.dart';
import 'all_data_screen.dart';
import 'manual_attendance_screen.dart';
import 'profile_edit_sheets.dart';

/// 4-tab: profil, sozlamalar va chiqish (PROJECT.md 5.4).
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
            child: ShimmerList(itemCount: 6),
          ),
          error: (Object e, StackTrace _) =>
              ErrorView(message: 'Profil yuklanmadi: $e'),
          data: (UserProfile? profile) {
            if (profile == null) {
              return const ErrorView(message: 'Profil topilmadi.');
            }
            return _ProfileBody(profile: profile);
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CustomTheme theme = context.theme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        _buildHeader(context, ref, theme),
        const SizedBox(height: 28),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              InfoRow(
                icon: BootstrapIcons.person_vcard,
                label: 'Barcha ma\'lumotlar',
                value: 'Shaxsiy, ish joyi, maosh va jadval',
                onTap: (WidgetRef ref) => AllDataScreen.open(context),
              ),
              InfoRow(
                icon: BootstrapIcons.calendar_plus,
                label: 'Davomat',
                value: 'Qo\'lda kiritish yoki vaqtni tuzatish',
                isLast: true,
                onTap: (WidgetRef ref) => ManualAttendanceScreen.open(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionTitle(title: 'Sozlamalar'),
        _buildSettings(context, ref, theme),
        const SizedBox(height: 28),
        const SectionTitle(title: 'Ilova haqida'),
        _buildAbout(ref, theme),
        const SizedBox(height: 28),
        AppButton(
          label: 'Chiqish',
          icon: BootstrapIcons.box_arrow_right,
          variant: AppButtonVariant.danger,
          onPressed: () => _confirmLogout(context, ref, theme),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, CustomTheme theme) {
    final Uint8List? photo = ImageService.decode(profile.profilePhotoBase64);

    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () => ProfileEditSheets.changePhoto(context, ref, profile),
          child: Stack(
            children: <Widget>[
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: theme.gray,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.borderGray, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: photo == null
                    ? Icon(
                        BootstrapIcons.person,
                        size: 46,
                        color: theme.favoriteGray,
                      )
                    : Image.memory(photo, fit: BoxFit.cover),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: theme.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.inputColor, width: 2),
                  ),
                  child: const Icon(
                    BootstrapIcons.camera_fill,
                    size: 14,
                    color: CustomTheme.onAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          profile.fullName.isEmpty ? 'Ism kiritilmagan' : profile.fullName,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.mainDarkBlue,
          ),
        ),
        if (profile.companyName.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            profile.companyName,
            style: TextStyle(fontSize: 12, color: theme.textGray),
          ),
        ],
      ],
    );
  }

  Widget _buildSettings(
    BuildContext context,
    WidgetRef ref,
    CustomTheme theme,
  ) {
    final ThemeMode mode = ref.watch(themeModeProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(BootstrapIcons.palette, size: 20, color: theme.textGray),
              const SizedBox(width: 12),
              Text(
                'Mavzu',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.mainDarkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              for (final ThemeMode option in ThemeModeNotifier.selectable)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: option == ThemeModeNotifier.selectable.last
                          ? 0
                          : 8,
                    ),
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(themeModeProvider.notifier).setMode(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: mode == option ? theme.blue : theme.inputColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ThemeModeNotifier.label(option),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: mode == option
                                ? CustomTheme.onAccent
                                : theme.mainDarkBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: theme.borderGray, height: 1),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Icon(BootstrapIcons.globe2, size: 20, color: theme.textGray),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Til',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.mainDarkBlue,
                  ),
                ),
              ),
              Text(
                'O\'zbekcha',
                style: TextStyle(fontSize: 12, color: theme.textGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbout(WidgetRef ref, CustomTheme theme) {
    final AsyncValue<String> version = ref.watch(appVersionProvider);

    return AppCard(
      child: Row(
        children: <Widget>[
          Icon(BootstrapIcons.info_circle, size: 20, color: theme.textGray),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ilova versiyasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.mainDarkBlue,
              ),
            ),
          ),
          Text(
            version.when(
              loading: () => '...',
              error: (Object _, StackTrace _) => '—',
              data: (String value) => value,
            ),
            style: TextStyle(fontSize: 12, color: theme.textGray),
          ),
        ],
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
        content: const Text('Hisobingizdan chiqmoqchimisiz?'),
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
      // davomat, qarzlar va yozishmalar JOYIDA QOLADI — qayta kirganda
      // hammasi o'z holicha tiklanadi.
      await ref
          .read(sharedPreferencesProvider)
          .remove(ThemeModeNotifier.storageKey);
    }
  }
}
