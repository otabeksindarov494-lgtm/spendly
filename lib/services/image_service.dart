import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Rasm olish, siqish va Base64'ga o'girish (PROJECT.md 10.1–10.2).
///
/// Firebase Storage ISHLATILMAYDI — rasm Firestore hujjatida Base64 matn
/// sifatida saqlanadi. Firestore hujjat chegarasi 1 MB bo'lgani uchun
/// rasm shu chegaradan ancha pastda ushlab turiladi.
class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Siqilgandan keyingi maksimal xom hajm (baytda).
  ///
  /// Base64 hajmni ~4/3 barobar oshiradi, ya'ni 220 KB → ~293 KB matn.
  /// Bu PRD'dagi "200–300 KB" oralig'iga to'g'ri keladi.
  static const int maxBytes = 220 * 1024;

  /// Kameradan selfie oladi. Foydalanuvchi bekor qilsa `null`.
  Future<String?> captureSelfieBase64() =>
      _pickAndEncode(ImageSource.camera, CameraDevice.front);

  /// Kameradan oddiy rasm oladi.
  Future<String?> captureBase64() =>
      _pickAndEncode(ImageSource.camera, CameraDevice.rear);

  /// Galereyadan rasm tanlaydi.
  Future<String?> pickFromGalleryBase64() =>
      _pickAndEncode(ImageSource.gallery, CameraDevice.rear);

  Future<String?> _pickAndEncode(
    ImageSource source,
    CameraDevice preferredCamera,
  ) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      preferredCameraDevice: preferredCamera,
      // Birlamchi kichraytirish — siqishdan oldin xotirani tejaydi.
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (file == null) return null;

    final Uint8List original = await file.readAsBytes();
    final Uint8List compressed = await compressToLimit(original);
    return base64Encode(compressed);
  }

  /// Rasmni [maxBytes] chegarasiga tushguncha bosqichma-bosqich siqadi.
  ///
  /// Har bosqichda sifat va o'lcham pasaytiriladi. Chegaraga yetib
  /// bo'lmasa, eng oxirgi (eng kichik) natija qaytariladi — bu holda ham
  /// hujjat 1 MB chegarasidan oshmasligi uchun o'lcham juda kichik bo'ladi.
  static Future<Uint8List> compressToLimit(Uint8List source) async {
    const List<(int quality, int width)> steps = <(int, int)>[
      (80, 1080),
      (65, 900),
      (50, 720),
      (40, 600),
      (30, 480),
    ];

    Uint8List result = source;
    for (final (int quality, int width) step in steps) {
      result = await FlutterImageCompress.compressWithList(
        source,
        quality: step.$1,
        minWidth: step.$2,
        minHeight: step.$2,
        format: CompressFormat.jpeg,
      );
      if (result.lengthInBytes <= maxBytes) return result;
    }
    return result;
  }

  /// Base64 matnni baytlarga qaytaradi. Buzuq matnda `null`.
  static Uint8List? decode(String? base64Text) {
    if (base64Text == null || base64Text.isEmpty) return null;
    try {
      return base64Decode(base64Text);
    } on FormatException {
      return null;
    }
  }
}
