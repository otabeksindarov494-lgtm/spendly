import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile_model.dart';
import '../../providers/core_providers.dart';
import '../../services/image_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'steps/birth_date_step.dart';
import 'steps/pay_day_step.dart';
import 'steps/photo_step.dart';
import 'steps/salary_step.dart';
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
  static const int _stepCount = 10;

  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  int _index = 0;
  bool _isPhotoBusy = false;
  bool _isSaving = false;
  String? _errorMessage;

  // --- Onboarding qoralamasi ----------------------------------------------
  String _fullName = '';
  DateTime? _birthDate;
  String? _photoBase64;
  double _salary = 0;
  String _workStart = '09:00';
  String _workEnd = '18:00';
  List<int> _workDays = <int>[1, 2, 3, 4, 5];
  int _payDay = 5;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _salaryController.dispose();
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
      case 4:
        return _salary > 0;
      case 7:
        return _workDays.isNotEmpty;
      default:
        return true;
    }
  }

  /// Faqat profil rasmi qadamini o'tkazib yuborish mumkin.
  bool get _canSkip => _index == 3;

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
        profilePhotoBase64: _photoBase64,
        salaryAmount: _salary,
        workStartTime: _workStart,
        workEndTime: _workEnd,
        salaryPayDay: _payDay,
        workDays: _workDays,
        onboardingCompleted: true,
        createdAt: DateTime.now(),
      );

      await ref.read(profileServiceProvider).save(userId, profile);

      // Chat ro'yxatida ko'rinishi uchun ochiq profil ham yoziladi.
      await ref.read(profileServiceProvider).syncPublicProfile(
            userId,
            fullName: _fullName,
            avatarBase64:
                await ImageService.avatarThumbnailBase64(_photoBase64),
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
                  style: TextStyle(fontSize: 12, color: theme.red),
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
                      BootstrapIcons.arrow_left,
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSteps() {
    return <Widget>[
      const WelcomeStep(),
      TextInputStep(
        title: 'Ismingiz nima?',
        subtitle: 'Ism va familiyangizni kiriting.',
        controller: _nameController,
        hint: 'Masalan: Azizbek Erkinov',
        onChanged: (String value) => setState(() => _fullName = value),
      ),
      BirthDateStep(
        value: _birthDate,
        onChanged: (DateTime value) => setState(() => _birthDate = value),
      ),
      PhotoStep(
        base64: _photoBase64,
        isBusy: _isPhotoBusy,
        onCamera: () => _pickPhoto(fromCamera: true),
        onGallery: () => _pickPhoto(fromCamera: false),
        onRemove: () => setState(() => _photoBase64 = null),
      ),
      SalaryStep(
        controller: _salaryController,
        currency: 'so\'m',
        onChanged: (String value) =>
            setState(() => _salary = ThousandsFormatter.parse(value)),
      ),
      WorkTimeStep(
        title: 'Ish nechada boshlanadi?',
        subtitle: 'Kechikish shu vaqtdan hisoblanadi.',
        value: _workStart,
        icon: BootstrapIcons.box_arrow_in_right,
        onChanged: (String value) => setState(() => _workStart = value),
      ),
      WorkTimeStep(
        title: 'Ish nechada tugaydi?',
        subtitle: 'Erta ketish shu vaqtga nisbatan hisoblanadi.',
        value: _workEnd,
        icon: BootstrapIcons.box_arrow_right,
        onChanged: (String value) => setState(() => _workEnd = value),
      ),
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
      PayDayStep(
        selected: _payDay,
        onChanged: (int day) => setState(() => _payDay = day),
      ),
      SummaryStep(entries: _summaryEntries(), onEdit: _goTo),
    ];
  }

  List<SummaryEntry> _summaryEntries() {
    return <SummaryEntry>[
      SummaryEntry(
        label: 'Ism-familiya',
        value: _fullName.trim().isEmpty ? '—' : _fullName.trim(),
        stepIndex: 1,
        icon: BootstrapIcons.person,
      ),
      SummaryEntry(
        label: 'Tug\'ilgan kun',
        value: _birthDate == null ? '—' : Formatters.longDate(_birthDate!),
        stepIndex: 2,
        icon: BootstrapIcons.cake2,
      ),
      SummaryEntry(
        label: 'Profil rasmi',
        value: _photoBase64 == null ? 'Qo\'yilmagan' : 'Qo\'yilgan',
        stepIndex: 3,
        icon: BootstrapIcons.camera,
      ),
      SummaryEntry(
        label: 'Oylik maosh',
        value: Formatters.money(_salary),
        stepIndex: 4,
        icon: BootstrapIcons.cash_coin,
      ),
      SummaryEntry(
        label: 'Ish vaqti',
        value: '$_workStart – $_workEnd',
        stepIndex: 5,
        icon: BootstrapIcons.clock,
      ),
      SummaryEntry(
        label: 'Ish kunlari',
        value: _workDays.isEmpty ? '—' : Formatters.workDays(_workDays),
        stepIndex: 7,
        icon: BootstrapIcons.calendar3,
      ),
      SummaryEntry(
        label: 'Maosh kuni',
        value: 'Oyning $_payDay-kuni',
        stepIndex: 8,
        icon: BootstrapIcons.calendar_check,
      ),
    ];
  }
}
