import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/glass.dart';

/// Kirish va ro'yxatdan o'tish (PROJECT.md 1-bosqich).
///
/// Kompozitsiya uch zonaga bo'lingan: yuqorida brend va sarlavha,
/// o'rtada forma, pastda harakatlar va huquqiy matn. Zonalar orasidagi
/// bo'shliq `MainAxisAlignment.spaceBetween` bilan taqsimlanadi —
/// `Spacer` bu yerda ishlamaydi, chunki scroll ichida balandlik cheksiz.
/// `ConstrainedBox(minHeight: ...)` esa klaviatura ochilganda kontentni
/// siqib emas, scroll qilib ko'rsatadi.
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
        _showLegalSheet(title: 'Foydalanish shartlari', body: _termsText);

  late final TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer()
    ..onTap = () =>
        _showLegalSheet(title: 'Maxfiylik siyosati', body: _privacyText);

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

  // --- Harakatlar ----------------------------------------------------------

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

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(
        () => _errorMessage =
            'Parolni tiklash uchun avval email manzilingizni kiriting.',
      );
      return;
    }

    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _errorMessage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$email manziliga tiklash havolasi yuborildi.')),
      );
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

  // --- Qurish --------------------------------------------------------------

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
                    // Planshet/katta ekranda forma cho'zilib ketmasin.
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        // `spaceBetween` emas: baland ekranda u bo'shliqni
                        // 150dp gacha cho'zib yuborardi. Bo'shliq qat'iy,
                        // blok esa markazda — kontent o'sganda scroll bo'ladi.
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildHeader(),
                          const SizedBox(height: 32),
                          // Forma va asosiy tugma — haqiqiy blur'li shisha
                          // panelda; orqadagi rangli nurlar xiralashib
                          // ko'rinadi.
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
                                      ? 'Hisob yaratish'
                                      : 'Kirish',
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

  /// 1-zona: brend belgisi, sarlavha va tushuntirish.
  Widget _buildHeader() {
    final CustomTheme theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppLogo(size: 56),
        const SizedBox(height: 24),
        Text(
          _isRegisterMode ? 'Keling, boshlaymiz' : 'Xush kelibsiz',
          style: context.text.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          _isRegisterMode
              ? 'Bir daqiqada hisob yarating — ish vaqtingiz va '
                    'moliyangiz shu yerda yig\'iladi.'
              : 'Davomat, maosh va qarzlaringiz sizni kutmoqda.',
          style: context.text.bodyMedium?.copyWith(color: theme.textGray),
        ),
      ],
    );
  }

  /// 2-zona: kiritish maydonlari va xato xabari.
  Widget _buildForm() {
    final CustomTheme theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: _emailController,
          label: 'Email manzil',
          hint: 'ism@example.com',
          prefixIcon: IconsaxPlusLinear.sms,
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
        const SizedBox(height: 18),
        AppTextField(
          controller: _passwordController,
          label: 'Parol',
          hint: 'Kamida 6 ta belgi',
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
            if ((value ?? '').isEmpty) return 'Parol kiriting';
            if ((value ?? '').length < 6) {
              return 'Parol kamida 6 ta belgi bo\'lsin';
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
                'Parolni unutdingizmi?',
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

  /// 3-zona: rejim almashtirish va huquqiy matn.
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
              child: Text('yoki', style: context.text.labelSmall),
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
                        ? 'Hisobingiz bormi? '
                        : 'Hisobingiz yo\'qmi? ',
                  ),
                  TextSpan(
                    text: _isRegisterMode ? 'Kirish' : 'Ro\'yxatdan o\'tish',
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
                ? 'Hisob yaratish orqali siz '
                : 'Davom etish orqali siz ',
          ),
          TextSpan(
            text: 'Foydalanish shartlari',
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),
          const TextSpan(text: ' va '),
          TextSpan(
            text: 'Maxfiylik siyosati',
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
          const TextSpan(text: 'ga rozilik bildirasiz.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  // --- Huquqiy matnlar -----------------------------------------------------

  /// Bu matnlar — o'rinbosar. Haqiqiy hujjatlar tayyor bo'lgach shu ikki
  /// konstantani almashtirish kifoya (yoki ularni veb-sahifaga ulash).
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
                    label: 'Tushunarli',
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
