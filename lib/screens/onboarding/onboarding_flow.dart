import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile_model.dart';
import '../../providers/core_providers.dart';
import '../../services/image_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'steps/choice_step.dart';
import 'steps/date_step.dart';
import 'steps/lunch_break_step.dart';
import 'steps/pay_day_step.dart';
import 'steps/salary_range_step.dart';
import 'steps/photo_step.dart';
import 'steps/summary_step.dart';
import 'steps/text_input_step.dart';
import 'steps/welcome_step.dart';
import 'steps/work_days_step.dart';
import 'steps/work_time_step.dart';

/// 10 qadamli onboarding (PROJECT.md 4-bo'lim).
///
/// Ma'lumotlar faqat oxirgi qadamda, bir marta Firestore'ga yoziladi —
/// shunda yarim to'ldirilgan profil saqlanib qolmaydi.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  static const int _stepCount = 18;

  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  int _index = 0;
  bool _isPhotoBusy = false;
  bool _isSaving = false;
  String? _errorMessage;

  // --- Onboarding qoralamasi ----------------------------------------------
  String _fullName = '';
  DateTime? _birthDate;
  String _phone = '';
  String? _photoBase64;
  String _company = '';
  String _position = '';
  DateTime? _employmentStart;
  SalaryType _salaryType = SalaryType.calculated;
  String _currency = 'so\'m';
  double _salaryMin = 0;
  double _salaryMax = 0;
  String _workStart = '09:00';
  String _workEnd = '18:00';
  int _lunchBreak = 60;
  List<int> _workDays = <int>[1, 2, 3, 4, 5];
  int _payDay = 5;
  bool _penaltyEnabled = true;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  // --- Navigatsiya ---------------------------------------------------------

  void _goTo(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_index < _stepCount - 1) _goTo(_index + 1);
  }

  void _back() {
    if (_index > 0) _goTo(_index - 1);
  }

  /// Joriy qadamda "Davom etish" bosilishi mumkinmi?
  bool get _canContinue {
    switch (_index) {
      case 1:
        return _fullName.trim().isNotEmpty;
      case 2:
        return _birthDate != null;
      case 10:
        return _salaryMin > 0 || _salaryMax > 0;
      case 14:
        return _workDays.isNotEmpty;
      default:
        return true;
    }
  }

  /// Majburiy bo'lmagan qadamlar: telefon, rasm, ish joyi, lavozim,
  /// ishga kirgan sana.
  bool get _canSkip => const <int>{3, 4, 5, 6, 7}.contains(_index);

  // --- Rasm ----------------------------------------------------------------

  Future<void> _pickPhoto({required bool fromCamera}) async {
    setState(() {
      _isPhotoBusy = true;
      _errorMessage = null;
    });
    try {
      final String? encoded = fromCamera
          ? await ref.read(imageServiceProvider).captureSelfieBase64()
          : await ref.read(imageServiceProvider).pickFromGalleryBase64();
      if (!mounted) return;
      if (encoded != null) setState(() => _photoBase64 = encoded);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Rasmni olishda xatolik: $e');
    } finally {
      if (mounted) setState(() => _isPhotoBusy = false);
    }
  }

  // --- Saqlash -------------------------------------------------------------

  Future<void> _finish() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      setState(() => _errorMessage = 'Sessiya tugagan. Qayta kiring.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final UserProfile profile = UserProfile(
        fullName: _fullName.trim(),
        birthDate: _birthDate,
        phoneNumber: _phone.trim(),
        profilePhotoBase64: _photoBase64,
        salaryType: _salaryType,
        salaryMin: _salaryMin,
        salaryMax: _salaryMax,
        // Hisob-kitobda oraliqning o'rtachasi ishlatiladi.
        salaryAmount: UserProfile.averageOf(_salaryMin, _salaryMax),
        currency: _currency,
        companyName: _company.trim(),
        position: _position.trim(),
        employmentStartDate: _employmentStart,
        workStartTime: _workStart,
        workEndTime: _workEnd,
        lunchBreakMinutes: _lunchBreak,
        salaryPayDay: _payDay,
        workDays: _workDays,
        penaltyEnabled: _penaltyEnabled,
        onboardingCompleted: true,
        createdAt: DateTime.now(),
      );

      await ref.read(profileServiceProvider).save(userId, profile);

      // Chat ro'yxatida ko'rinishi uchun ochiq profil ham yoziladi.
      await ref
          .read(profileServiceProvider)
          .syncPublicProfile(
            userId,
            fullName: _fullName,
            avatarBase64: await ImageService.avatarThumbnailBase64(
              _photoBase64,
            ),
          );
      // Saqlangach `profileProvider` o'zi yangilanadi va AuthGate
      // foydalanuvchini asosiy ekranga o'tkazadi.
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Saqlashda xatolik: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- Qurish --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final bool isLastStep = _index == _stepCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildHeader(theme),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _buildSteps(),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: theme.red),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: <Widget>[
                  AppButton(
                    label: isLastStep
                        ? 'Tasdiqlash va boshlash'
                        : (_index == 0 ? 'Boshlash' : 'Davom etish'),
                    isLoading: _isSaving,
                    onPressed: _canContinue
                        ? (isLastStep ? _finish : _next)
                        : null,
                  ),
                  if (_canSkip) ...<Widget>[
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'O\'tkazib yuborish',
                      variant: AppButtonVariant.text,
                      height: 44,
                      onPressed: _next,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CustomTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 24, 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 40,
            child: _index == 0
                ? null
                : IconButton(
                    icon: Icon(
                      IconsaxPlusLinear.arrow_left,
                      color: theme.mainDarkBlue,
                    ),
                    onPressed: _isSaving ? null : _back,
                  ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_index + 1) / _stepCount,
                minHeight: 6,
                backgroundColor: theme.borderGray,
                valueColor: AlwaysStoppedAnimation<Color>(theme.blue),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${_index + 1}/$_stepCount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSteps() {
    final DateTime now = DateTime.now();

    return <Widget>[
      // 1
      const WelcomeStep(),
      // 2
      TextInputStep(
        title: 'Ismingiz nima?',
        subtitle: 'Ism va familiyangizni kiriting.',
        controller: _nameController,
        hint: 'Masalan: Azizbek Erkinov',
        onChanged: (String value) => setState(() => _fullName = value),
      ),
      // 3
      DateStep(
        title: 'Tug\'ilgan kuningiz qachon?',
        subtitle: 'Bu ma\'lumot faqat profilingizda ko\'rinadi.',
        value: _birthDate,
        firstDate: DateTime(now.year - 100),
        lastDate: now,
        initialWhenEmpty: DateTime(now.year - 25, now.month, now.day),
        icon: IconsaxPlusLinear.cake,
        onChanged: (DateTime value) => setState(() => _birthDate = value),
      ),
      // 4
      TextInputStep(
        title: 'Telefon raqamingiz',
        subtitle: 'Ixtiyoriy — faqat profilingizda saqlanadi.',
        controller: _phoneController,
        hint: '+998 90 123 45 67',
        textCapitalization: TextCapitalization.none,
        keyboardType: TextInputType.phone,
        inputFormatters: const <TextInputFormatter>[UzPhoneFormatter()],
        onChanged: (String value) => setState(() => _phone = value),
      ),
      // 5
      PhotoStep(
        base64: _photoBase64,
        isBusy: _isPhotoBusy,
        onCamera: () => _pickPhoto(fromCamera: true),
        onGallery: () => _pickPhoto(fromCamera: false),
        onRemove: () => setState(() => _photoBase64 = null),
      ),
      // 6
      TextInputStep(
        title: 'Qayerda ishlaysiz?',
        subtitle: 'Kompaniya yoki tashkilot nomi.',
        controller: _companyController,
        hint: 'Masalan: Chaqqon',
        onChanged: (String value) => setState(() => _company = value),
      ),
      // 7
      TextInputStep(
        title: 'Lavozimingiz nima?',
        subtitle: 'Ixtiyoriy.',
        controller: _positionController,
        hint: 'Masalan: Flutter dasturchi',
        onChanged: (String value) => setState(() => _position = value),
      ),
      // 8
      DateStep(
        title: 'Qachon ishga kirgansiz?',
        subtitle: 'Ixtiyoriy — ish stajini ko\'rsatish uchun.',
        value: _employmentStart,
        firstDate: DateTime(now.year - 50),
        lastDate: now,
        initialWhenEmpty: DateTime(now.year, now.month, 1),
        icon: IconsaxPlusLinear.building,
        onChanged: (DateTime value) => setState(() => _employmentStart = value),
      ),
      // 9 — eng muhim savol: butun hisob-kitob shunga bog'liq
      ChoiceStep<SalaryType>(
        title: 'Maoshingiz qanday kelishilgan?',
        subtitle: 'Bu tanlov oylik qanday hisoblanishini belgilaydi.',
        options: <ChoiceOption<SalaryType>>[
          for (final SalaryType type in SalaryType.values)
            ChoiceOption<SalaryType>(
              value: type,
              label: type.label,
              description: type.description,
            ),
        ],
        selected: _salaryType,
        onChanged: (SalaryType value) => setState(() => _salaryType = value),
      ),
      // 10
      ChoiceStep<String>(
        title: 'Maosh qaysi valyutada?',
        options: const <ChoiceOption<String>>[
          ChoiceOption<String>(value: 'so\'m', label: 'So\'m (UZS)'),
          ChoiceOption<String>(value: 'USD', label: 'Dollar (USD)'),
        ],
        selected: _currency,
        onChanged: (String value) => setState(() => _currency = value),
      ),
      // 11
      SalaryRangeStep(
        min: _salaryMin,
        max: _salaryMax,
        currency: _currency,
        onChanged: (double min, double max) => setState(() {
          _salaryMin = min;
          _salaryMax = max;
        }),
      ),
      // 12
      WorkTimeStep(
        title: 'Ish nechada boshlanadi?',
        subtitle: 'Kechikish shu vaqtdan hisoblanadi.',
        value: _workStart,
        icon: IconsaxPlusLinear.login,
        onChanged: (String value) => setState(() => _workStart = value),
      ),
      // 13
      WorkTimeStep(
        title: 'Ish nechada tugaydi?',
        subtitle: 'Erta ketish shu vaqtga nisbatan hisoblanadi.',
        value: _workEnd,
        icon: IconsaxPlusLinear.logout,
        onChanged: (String value) => setState(() => _workEnd = value),
      ),
      // 14
      LunchBreakStep(
        minutes: _lunchBreak,
        onChanged: (int value) => setState(() => _lunchBreak = value),
      ),
      // 15
      WorkDaysStep(
        selected: _workDays,
        onToggle: (int weekday) {
          setState(() {
            final List<int> updated = List<int>.of(_workDays);
            if (updated.contains(weekday)) {
              updated.remove(weekday);
            } else {
              updated.add(weekday);
            }
            updated.sort();
            _workDays = updated;
          });
        },
      ),
      // 16
      PayDayStep(
        selected: _payDay,
        onChanged: (int day) => setState(() => _payDay = day),
      ),
      // 17
      ChoiceStep<bool>(
        title: 'Kechikkanda pul ushlanadimi?',
        subtitle: 'Ba\'zi ish joylarida kechikish uchun jarima yo\'q.',
        options: const <ChoiceOption<bool>>[
          ChoiceOption<bool>(
            value: true,
            label: 'Ha, ushlanadi',
            description:
                'Kechikkan va erta ketgan daqiqalar uchun soatlik '
                'stavkadan pul ayiriladi.',
          ),
          ChoiceOption<bool>(
            value: false,
            label: 'Yo\'q, ushlanmaydi',
            description:
                'Kechikish faqat statistika uchun yoziladi, '
                'maoshga ta\'sir qilmaydi.',
          ),
        ],
        selected: _penaltyEnabled,
        onChanged: (bool value) => setState(() => _penaltyEnabled = value),
      ),
      // 18
      SummaryStep(entries: _summaryEntries(), onEdit: _goTo),
    ];
  }

  List<SummaryEntry> _summaryEntries() {
    final double average = UserProfile.averageOf(_salaryMin, _salaryMax);

    String orDash(String value) => value.trim().isEmpty ? '—' : value.trim();

    return <SummaryEntry>[
      SummaryEntry(
        label: 'Ism-familiya',
        value: orDash(_fullName),
        stepIndex: 1,
        icon: IconsaxPlusLinear.user,
      ),
      SummaryEntry(
        label: 'Tug\'ilgan kun',
        value: _birthDate == null ? '—' : Formatters.longDate(_birthDate!),
        stepIndex: 2,
        icon: IconsaxPlusLinear.cake,
      ),
      SummaryEntry(
        label: 'Telefon',
        value: orDash(_phone),
        stepIndex: 3,
        icon: IconsaxPlusLinear.call,
      ),
      SummaryEntry(
        label: 'Profil rasmi',
        value: _photoBase64 == null ? 'Qo\'yilmagan' : 'Qo\'yilgan',
        stepIndex: 4,
        icon: IconsaxPlusLinear.camera,
      ),
      SummaryEntry(
        label: 'Ish joyi',
        value: orDash(_company),
        stepIndex: 5,
        icon: IconsaxPlusLinear.building,
      ),
      SummaryEntry(
        label: 'Lavozim',
        value: orDash(_position),
        stepIndex: 6,
        icon: IconsaxPlusLinear.personalcard,
      ),
      SummaryEntry(
        label: 'Ishga kirgan sana',
        value: _employmentStart == null
            ? '—'
            : Formatters.longDate(_employmentStart!),
        stepIndex: 7,
        icon: IconsaxPlusLinear.calendar_tick,
      ),
      SummaryEntry(
        label: 'Maosh turi',
        value: _salaryType.label,
        stepIndex: 8,
        icon: IconsaxPlusLinear.empty_wallet,
      ),
      SummaryEntry(
        label: 'Maosh oralig\'i',
        value: _salaryMin <= 0 && _salaryMax <= 0
            ? '—'
            : '${Formatters.number(_salaryMin)} – '
                  '${Formatters.money(_salaryMax, currency: _currency)}',
        stepIndex: 10,
        icon: IconsaxPlusLinear.moneys,
      ),
      SummaryEntry(
        label: 'Hisobda ishlatiladi',
        value: Formatters.money(average, currency: _currency),
        stepIndex: 10,
        icon: IconsaxPlusLinear.calculator,
      ),
      SummaryEntry(
        label: 'Ish vaqti',
        value: '$_workStart – $_workEnd',
        stepIndex: 11,
        icon: IconsaxPlusLinear.clock,
      ),
      SummaryEntry(
        label: 'Tushlik tanaffusi',
        value: _lunchBreak == 0 ? 'Yo\'q' : Formatters.minutes(_lunchBreak),
        stepIndex: 13,
        icon: IconsaxPlusLinear.coffee,
      ),
      SummaryEntry(
        label: 'Ish kunlari',
        value: _workDays.isEmpty ? '—' : Formatters.workDays(_workDays),
        stepIndex: 14,
        icon: IconsaxPlusLinear.calendar,
      ),
      SummaryEntry(
        label: 'Maosh kuni',
        value: 'Oyning $_payDay-kuni',
        stepIndex: 15,
        icon: IconsaxPlusLinear.calendar_tick,
      ),
      SummaryEntry(
        label: 'Kechikish jarimasi',
        value: _penaltyEnabled ? 'Ushlanadi' : 'Ushlanmaydi',
        stepIndex: 16,
        icon: IconsaxPlusLinear.alarm,
      ),
    ];
  }
}
