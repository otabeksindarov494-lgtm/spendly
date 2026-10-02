import 'dart:typed_data';

import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';

import '../../../services/image_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_button.dart';
import 'onboarding_step.dart';

/// 4-qadam: profil rasmi (ixtiyoriy).
class PhotoStep extends StatelessWidget {
  const PhotoStep({
    super.key,
    required this.base64,
    required this.isBusy,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final String? base64;
  final bool isBusy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Uint8List? bytes = ImageService.decode(base64);

    return OnboardingStep(
      title: 'Profil rasmingiz',
      subtitle: 'Bu qadamni o\'tkazib yuborsangiz ham bo\'ladi.',
      child: Column(
        children: <Widget>[
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: theme.gray,
                shape: BoxShape.circle,
                border: Border.all(color: theme.borderGray, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: isBusy
                  ? Center(child: CircularProgressIndicator(color: theme.blue))
                  : bytes == null
                  ? Icon(
                      IconsaxPlusLinear.user,
                      size: 56,
                      color: theme.favoriteGray,
                    )
                  : Image.memory(bytes, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: 'Kamera',
                  icon: IconsaxPlusLinear.camera,
                  variant: AppButtonVariant.secondary,
                  onPressed: isBusy ? null : onCamera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Galereya',
                  icon: IconsaxPlusLinear.gallery,
                  variant: AppButtonVariant.secondary,
                  onPressed: isBusy ? null : onGallery,
                ),
              ),
            ],
          ),
          if (bytes != null) ...<Widget>[
            const SizedBox(height: 12),
            AppButton(
              label: 'Rasmni olib tashlash',
              variant: AppButtonVariant.text,
              height: 44,
              onPressed: isBusy ? null : onRemove,
            ),
          ],
        ],
      ),
    );
  }
}
