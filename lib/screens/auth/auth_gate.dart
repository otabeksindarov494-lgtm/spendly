import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile_model.dart';
import '../../providers/core_providers.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/error_view.dart';
import '../main_navigation.dart';
import '../onboarding/onboarding_flow.dart';
import 'login_screen.dart';
import '../../widgets/common/app_logo.dart';

/// Kirish holatiga qarab to'g'ri ekranni ko'rsatadi.
///
/// Kirilmagan → [LoginScreen]
/// Kirilgan, onboarding tugamagan → [OnboardingFlow]
/// Kirilgan, onboarding tugagan → [MainNavigation]
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<User?> authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _SplashScreen(),
      error: (Object error, StackTrace _) => Scaffold(
        body: Center(
          child: ErrorView(message: 'Kirishda xatolik: $error'),
        ),
      ),
      data: (User? user) {
        if (user == null) return const LoginScreen();

        final AsyncValue<UserProfile?> profile = ref.watch(profileProvider);
        return profile.when(
          loading: () => const _SplashScreen(),
          error: (Object error, StackTrace _) => Scaffold(
            body: Center(
              child: ErrorView(message: 'Profil yuklanmadi: $error'),
            ),
          ),
          data: (UserProfile? data) {
            // Profil hujjati yo'q yoki onboarding tugallanmagan.
            if (data == null || !data.onboardingCompleted) {
              return const OnboardingFlow();
            }
            return const MainNavigation();
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AppLogo(size: 76),
            const SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: theme.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
