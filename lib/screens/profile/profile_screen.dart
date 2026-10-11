import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile?> profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text('profile_title'.tr())),
      body: SafeArea(
        top: false,
        child: profileAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(itemCount: 5, itemHeight: 74),
          ),
          error: (Object e, StackTrace _) =>
              ErrorView(message: 'profile_load_error'.tr(args: [e.toString()])),
          data: (UserProfile? profile) => profile == null
              ? ErrorView(message: 'profile_not_found'.tr())
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
              ? 'no_name'.tr()
              : profile.fullName.trim(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.mainDarkBlue,
          ),
        ),
        if (_subtitle(profile).isNotEmpty) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            _subtitle(profile),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: theme.textGray),
          ),
        ],
        const SizedBox(height: 30),
        MenuCard(
          icon: IconsaxPlusLinear.personalcard,
          title: 'menu_all_data_title'.tr(),
          subtitle: 'menu_all_data_subtitle'.tr(),
          onTap: () => AllDataScreen.open(context),
        ),
        MenuCard(
          icon: IconsaxPlusLinear.calendar_add,
          title: 'menu_attendance_title'.tr(),
          subtitle: 'menu_attendance_subtitle'.tr(),
          accentColor: theme.green,
          onTap: () => ManualAttendanceScreen.open(context),
        ),
        MenuCard(
          icon: IconsaxPlusLinear.setting_2,
          title: 'menu_settings_title'.tr(),
          subtitle: 'menu_settings_subtitle'.tr(),
          onTap: () => SettingsScreen.open(context),
        ),
        MenuCard(
          icon: IconsaxPlusLinear.logout,
          title: 'menu_logout_title'.tr(),
          subtitle: 'menu_logout_subtitle'.tr(),
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
                color: theme.glassFill,
                shape: BoxShape.circle,
                border: Border.all(color: theme.borderGray, width: 2),
              ),
              child: photo == null
                  ? Icon(
                      IconsaxPlusLinear.user,
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
                  IconsaxPlusBold.camera,
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
        title: Text('logout_dialog_title'.tr()),
        content: Text('logout_dialog_content'.tr()),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('logout_button'.tr(), style: TextStyle(color: theme.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(authServiceProvider).signOut();
      await ref
          .read(sharedPreferencesProvider)
          .remove(ThemeModeNotifier.storageKey);
    }
  }
}
