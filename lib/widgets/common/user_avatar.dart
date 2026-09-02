import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/image_service.dart';
import '../../theme/app_theme.dart';

/// Foydalanuvchi avatari: rasm bo'lsa rasm, bo'lmasa bosh harflar.
///
/// Ishlatilishi: chat ro'yxati, chat sarlavhasi.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.base64,
    this.size = 48,
  });

  final String initials;
  final String? base64;
  final double size;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Uint8List? bytes = ImageService.decode(base64);

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.blue.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: bytes == null
          ? Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: theme.blue,
              ),
            )
          : Image.memory(bytes, fit: BoxFit.cover, width: size, height: size),
    );
  }
}
