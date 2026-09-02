import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

/// Kirish va ro'yxatdan o'tish (PROJECT.md 1-bosqich).
///
/// Bitta ekranda ikkala rejim — foydalanuvchi bitta shaxs bo'lgani uchun
/// alohida sahifaga ajratish ortiqcha.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AuthService auth = ref.read(authServiceProvider);
      if (_isRegisterMode) {
        final user = await auth.register(
          email: _emailController.text,
          password: _passwordController.text,
        );
        // Yangi foydalanuvchi uchun bo'sh profil hujjatini tayyorlaymiz.
        await ref.read(profileServiceProvider).createIfMissing(user.uid);
      } else {
        await auth.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      // Muvaffaqiyatli bo'lsa AuthGate o'zi keyingi ekranga o'tkazadi.
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Kutilmagan xatolik: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Spendly',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: theme.mainDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegisterMode
                        ? 'Yangi hisob yarating'
                        : 'Hisobingizga kiring',
                    style: TextStyle(fontSize: 13, color: theme.textGray),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email manzil',
                    hint: 'ism@example.com',
                    prefixIcon: BootstrapIcons.envelope,
                    keyboardType: TextInputType.emailAddress,
                    validator: (String? value) {
                      final String text = (value ?? '').trim();
                      if (text.isEmpty) return 'Email kiriting';
                      if (!text.contains('@') || !text.contains('.')) {
                        return 'Email manzili noto\'g\'ri';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Parol',
                    hint: 'Kamida 6 ta belgi',
                    prefixIcon: BootstrapIcons.lock,
                    obscureText: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? BootstrapIcons.eye_slash
                            : BootstrapIcons.eye,
                        size: 20,
                        color: theme.textGray,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                    validator: (String? value) {
                      if ((value ?? '').isEmpty) return 'Parol kiriting';
                      if ((value ?? '').length < 6) {
                        return 'Parol kamida 6 ta belgi bo\'lsin';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            BootstrapIcons.exclamation_circle,
                            size: 18,
                            color: theme.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(fontSize: 12, color: theme.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AppButton(
                    label: _isRegisterMode ? 'Ro\'yxatdan o\'tish' : 'Kirish',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: _isRegisterMode
                        ? 'Hisobim bor — kirish'
                        : 'Hisobim yo\'q — ro\'yxatdan o\'tish',
                    variant: AppButtonVariant.text,
                    height: 44,
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _isRegisterMode = !_isRegisterMode;
                              _errorMessage = null;
                            }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
