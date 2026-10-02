import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile_model.dart';
import '../services/image_service.dart';
import 'core_providers.dart';

/// Joriy foydalanuvchi profili.
final StreamProvider<UserProfile?> profileProvider =
    StreamProvider<UserProfile?>((Ref ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream<UserProfile?>.value(null);
  return ref.watch(profileServiceProvider).watch(userId);
});

/// Onboarding tugaganmi? Ma'lumot hali kelmagan bo'lsa `null`.
final Provider<bool?> onboardingCompletedProvider = Provider<bool?>((Ref ref) {
  final AsyncValue<UserProfile?> profile = ref.watch(profileProvider);
  if (profile.isLoading && !profile.hasValue) return null;
  return profile.value?.onboardingCompleted ?? false;
});

/// Chat ro'yxatida ko'rinish uchun ochiq profilni tekshiradi va kerak
/// bo'lsa yozadi (eski foydalanuvchilarda `publicProfiles` hujjati yo'q edi).
///
/// Faqat ism, rasm yoki onboarding holati o'zgarganda qayta ishlaydi —
/// boshqa maydonlar (maosh, ish vaqti) o'zgarsa ortiqcha so'rov ketmaydi.
/// Xato bo'lsa jim — ilova oqimini to'xtatmaydi, keyingi ochilishda qayta
/// urinadi. `AuthGate` kuzatadi.
final FutureProvider<void> publicProfileSyncProvider =
    FutureProvider<void>((Ref ref) async {
  final String? userId = ref.watch(currentUserIdProvider);
  final ({bool ready, String name, String? photo})? info = ref.watch(
    profileProvider.select(
      (AsyncValue<UserProfile?> p) => p.value == null
          ? null
          : (
              ready: p.value!.onboardingCompleted,
              name: p.value!.fullName,
              photo: p.value!.profilePhotoBase64,
            ),
    ),
  );
  if (userId == null || info == null || !info.ready) return;

  try {
    await ref.read(profileServiceProvider).ensurePublicProfile(
          userId,
          fullName: info.name,
          avatar: () => ImageService.avatarThumbnailBase64(info.photo),
        );
  } catch (_) {
    // Tarmoq yoki ruxsat xatosi — keyingi ochilishda qayta urinadi.
  }
});
