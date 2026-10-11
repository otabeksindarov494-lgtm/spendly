import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/glass.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer()
    ..onTap = () =>
        _showLegalSheet(title: 'auth_terms'.tr(), body: _termsText);

  late final TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer()
    ..onTap = () =>
        _showLegalSheet(title: 'auth_privacy'.tr(), body: _privacyText);

  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
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
        await ref.read(profileServiceProvider).createIfMissing(user.uid);
      } else {
        await auth.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '${'error'.tr()}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(
        () => _errorMessage = 'Parolni tiklash uchun avval email manzilingizni kiriting.'.tr(),
      );
      return;
    }

    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _errorMessage = null);
      AppToast.show(context, '$email manziliga tiklash havolasi yuborildi.');
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 44,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildHeader(),
                          const SizedBox(height: 32),
                          GlassPanel(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(AppRadius.xl),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                _buildForm(),
                                const SizedBox(height: 24),
                                AppButton(
                                  label: _isRegisterMode
                                      ? 'register'.tr()
                                      : 'login'.tr(),
                                  isLoading: _isLoading,
                                  onPressed: _submit,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final CustomTheme theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppLogo(size: 56),
        const SizedBox(height: 24),
        Text(
          _isRegisterMode
              ? 'auth_header_register'.tr()
              : 'auth_header_login'.tr(),
          style: context.text.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          _isRegisterMode
              ? 'auth_subtitle_register'.tr()
              : 'auth_subtitle_login'.tr(),
          style: context.text.bodyMedium?.copyWith(color: theme.textGray),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final CustomTheme theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: _emailController,
          label: 'email_label'.tr(),
          hint: 'email_hint'.tr(),
          prefixIcon: IconsaxPlusLinear.sms,
          keyboardType: TextInputType.emailAddress,
          validator: (String? value) {
            final String text = (value ?? '').trim();
            if (text.isEmpty) return 'email_empty'.tr();
            if (!text.contains('@') || !text.contains('.')) {
              return 'email_invalid'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppTextField(
          controller: _passwordController,
          label: 'password_label'.tr(),
          hint: 'password_hint'.tr(),
          prefixIcon: IconsaxPlusLinear.lock,
          obscureText: _obscurePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword
                  ? IconsaxPlusLinear.eye_slash
                  : IconsaxPlusLinear.eye,
              size: 18,
              color: theme.textGray,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (String? value) {
            if ((value ?? '').isEmpty) return 'password_empty'.tr();
            if ((value ?? '').length < 6) {
              return 'password_short'.tr();
            }
            return null;
          },
        ),
        if (!_isRegisterMode)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'forgot_password'.tr(),
                style: context.text.labelMedium?.copyWith(color: theme.blue),
              ),
            ),
          ),
        if (_errorMessage != null) ...<Widget>[
          const SizedBox(height: 14),
          _buildErrorBanner(theme),
        ],
      ],
    );
  }

  Widget _buildErrorBanner(CustomTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: theme.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(IconsaxPlusLinear.information, size: 16, color: theme.red),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _errorMessage!,
              style: context.text.bodySmall?.copyWith(color: theme.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final CustomTheme theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Divider(color: theme.borderGray, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or_text'.tr(), style: context.text.labelSmall),
            ),
            Expanded(child: Divider(color: theme.borderGray, height: 1)),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _isLoading ? null : _toggleMode,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text.rich(
              TextSpan(
                style: context.text.bodyMedium?.copyWith(color: theme.textGray),
                children: <InlineSpan>[
                  TextSpan(
                    text: _isRegisterMode
                        ? 'have_account'.tr()
                        : 'no_account'.tr(),
                  ),
                  TextSpan(
                    text: _isRegisterMode
                        ? 'login_link'.tr()
                        : 'register_link'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.blue,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildLegalText(theme),
        ),
      ],
    );
  }

  Widget _buildLegalText(CustomTheme theme) {
    final TextStyle linkStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: theme.mainDarkBlue,
    );

    return Text.rich(
      TextSpan(
        style: context.text.labelSmall?.copyWith(height: 1.6),
        children: <InlineSpan>[
          TextSpan(
            text: _isRegisterMode
                ? 'terms_prefix_register'.tr()
                : 'terms_prefix_login'.tr(),
          ),
          TextSpan(
            text: 'auth_terms'.tr(),
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),
          TextSpan(text: 'auth_and'.tr()),
          TextSpan(
            text: 'auth_privacy'.tr(),
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
          TextSpan(text: 'terms_suffix'.tr()),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  static const String _termsText =
      'Spendly — shaxsiy foydalanish uchun mo\'ljallangan ilova. Siz kiritgan '
      'ma\'lumotlar (ish vaqti, maosh, qarzlar) faqat sizning hisobingizga '
      'bog\'lanadi va boshqa foydalanuvchilarga ko\'rinmaydi.\n\n'
      'Ilovadagi hisob-kitoblar siz ko\'rsatgan sozlamalar asosida taxminiy '
      'tarzda amalga oshiriladi va rasmiy moliyaviy hujjat o\'rnini bosmaydi.\n\n'
      'Hisobingiz xavfsizligi uchun parolingizni boshqalarga bermang.';

  static const String _privacyText =
      'Ma\'lumotlaringiz Google Firebase serverlarida saqlanadi va faqat '
      'sizning hisobingiz orqali ochiladi. Xavfsizlik qoidalari boshqa '
      'foydalanuvchining ma\'lumotlaringizni o\'qishiga yo\'l qo\'ymaydi.\n\n'
      'Kelish-ketish rasmlari qurilmangizda siqiladi va hisobingizga '
      'biriktirilgan holda saqlanadi. Ular hech kimga ko\'rsatilmaydi va '
      'uchinchi tomonlarga uzatilmaydi.\n\n'
      'Mikrofon faqat siz ovoz orqali qarz qo\'shganingizda ishlaydi; '
      'nutq qurilmangizning o\'z tizimi orqali matnga o\'giriladi.\n\n'
      'Hisobingizni o\'chirishni istasangiz, ma\'lumotlaringiz ham '
      'butunlay o\'chiriladi.';

  Future<void> _showLegalSheet({required String title, required String body}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final CustomTheme theme = sheetContext.theme;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
            ),
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
                  const SizedBox(height: 18),
                  Text(title, style: context.text.titleMedium),
                  const SizedBox(height: 14),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        body,
                        style: context.text.bodyMedium?.copyWith(
                          height: 1.6,
                          color: theme.textGray,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'understand'.tr(),
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
