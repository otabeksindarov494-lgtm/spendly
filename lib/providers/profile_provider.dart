import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile_model.dart';
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
