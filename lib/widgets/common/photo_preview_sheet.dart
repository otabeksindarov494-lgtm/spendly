import 'dart:typed_data';

import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../services/image_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/time_utils.dart';
import 'empty_state.dart';

/// Kunning check-in / check-out rasmlarini ko'rsatuvchi bottom sheet.
///
/// Ishlatilishi: Home ("Oxirgi 7 kun") va Hisobot (kunlik yozuvlar) —
/// ikkalasida ham bir xil ko'rinish bo'lishi uchun umumiy widget.
class PhotoPreviewSheet extends StatelessWidget {
  const PhotoPreviewSheet({super.key, required this.attendance});

  final Attendance attendance;

  /// Bottom sheet'ni ochish uchun qulaylik metodi.
  static Future<void> show(BuildContext context, Attendance attendance) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) =>
          PhotoPreviewSheet(attendance: attendance),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final DateTime? date = TimeUtils.dateFromKey(attendance.date);
    final bool hasAnyPhoto =
        attendance.checkInPhotoBase64 != null ||
        attendance.checkOutPhotoBase64 != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.borderGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              date == null ? attendance.date : Formatters.longDate(date),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.mainDarkBlue,
              ),
            ),
            const SizedBox(height: 16),
            if (!hasAnyPhoto)
              const EmptyState(
                icon: IconsaxPlusLinear.camera,
                title: 'Bu kun uchun rasm yo\'q',
                message: 'Check-in yoki check-out paytida rasm olinmagan.',
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _PhotoTile(
                      label: 'Kelgan',
                      time: attendance.checkInTime,
                      base64: attendance.checkInPhotoBase64,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PhotoTile(
                      label: 'Ketgan',
                      time: attendance.checkOutTime,
                      base64: attendance.checkOutPhotoBase64,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.label,
    required this.time,
    required this.base64,
  });

  final String label;
  final DateTime? time;
  final String? base64;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Uint8List? bytes = ImageService.decode(base64);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: bytes == null
                ? Container(
                    color: theme.gray,
                    alignment: Alignment.center,
                    child: Icon(
                      IconsaxPlusLinear.image,
                      color: theme.favoriteGray,
                    ),
                  )
                : GestureDetector(
                    onTap: () => _openFullScreen(context, bytes),
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.mainDarkBlue,
          ),
        ),
        Text(
          time == null ? '—' : Formatters.time(time!),
          style: TextStyle(fontSize: 12, color: theme.textGray),
        ),
      ],
    );
  }

  void _openFullScreen(BuildContext context, Uint8List bytes) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => Scaffold(
          backgroundColor: CustomTheme.viewerBackground,
          appBar: AppBar(
            backgroundColor: CustomTheme.viewerBackground,
            foregroundColor: CustomTheme.onAccent,
            title: Text(label),
          ),
          body: Center(
            child: InteractiveViewer(maxScale: 4, child: Image.memory(bytes)),
          ),
        ),
      ),
    );
  }
}
