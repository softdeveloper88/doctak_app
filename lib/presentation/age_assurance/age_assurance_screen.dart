import 'package:doctak_app/core/utils/age_assurance.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/one_ui_confirm_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Full-screen age assurance gate (DOB + policy confirmation).
///
/// Shown after login/splash when the user has not confirmed they are 13+,
/// and can also be used standalone from signup.
class AgeAssuranceScreen extends StatefulWidget {
  const AgeAssuranceScreen({
    super.key,
    this.onConfirmed,
    this.allowExitToLogin = true,
    this.initialDob,
  });

  /// Called after a successful confirmation (instead of popping true).
  final VoidCallback? onConfirmed;

  /// When true, under-age / cancel can return to login.
  final bool allowExitToLogin;

  final DateTime? initialDob;

  @override
  State<AgeAssuranceScreen> createState() => _AgeAssuranceScreenState();
}

class _AgeAssuranceScreenState extends State<AgeAssuranceScreen> {
  late DateTime _dob;
  bool _agreed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dob = widget.initialDob ?? DateTime(now.year - 25, now.month, now.day);
  }

  Future<void> _pickDob() async {
    final theme = OneUITheme.of(context);
    final now = DateTime.now();
    final min = DateTime(now.year - 100, 1, 1);
    final max = now;

    DateTime temp = _dob;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Date of birth',
                          style: theme.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _dob = temp);
                          Navigator.pop(ctx);
                        },
                        style: OneUIButtons.text(theme),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness:
                          theme.isDark ? Brightness.dark : Brightness.light,
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: _dob.isBefore(min)
                          ? min
                          : (_dob.isAfter(max) ? max : _dob),
                      minimumDate: min,
                      maximumDate: max,
                      onDateTimeChanged: (d) => temp = d,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirm() async {
    if (!_agreed) {
      toast('Please confirm you meet the age requirement.');
      return;
    }
    if (!AgeAssurance.meetsMinimumAge(_dob)) {
      await showOneUIConfirmDialog(
        context,
        title: 'Age requirement not met',
        subtitle:
            'DocTak is only available to users age ${AgeAssurance.minimumAge} and older. '
            'You cannot create or use an account at this time.',
        confirmLabel: 'OK',
        cancelLabel: 'Close',
      );
      if (!mounted) return;
      if (widget.allowExitToLogin) {
        const LoginScreen().launch(context, isNewTask: true);
      }
      return;
    }

    setState(() => _saving = true);
    try {
      await AgeAssurance.markConfirmed(
        dateOfBirth: _dob,
        userId: AppData.logInUserId?.toString(),
      );
      if (!mounted) return;
      if (widget.onConfirmed != null) {
        widget.onConfirmed!();
      } else {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final age = AgeAssurance.ageFromDateOfBirth(_dob);
    final eligible = AgeAssurance.meetsMinimumAge(_dob);
    final canContinue = _agreed && !_saving;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        color: theme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Age verification',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AgeAssurance.policySummary,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.5,
                        height: 1.5,
                        color: theme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Date of birth',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: theme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _pickDob,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.cake_outlined,
                                  color: theme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AgeAssurance.formatDob(_dob),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tap to change',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: theme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: (eligible ? theme.success : theme.error)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Age $age',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: eligible ? theme.success : theme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AgeAgreementTile(
                      theme: theme,
                      agreed: _agreed,
                      onChanged: (value) => setState(() => _agreed = value),
                      label:
                          'I confirm I am at least ${AgeAssurance.minimumAge} years old and agree to DocTak’s age policy.',
                    ),
                    if (!eligible) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'You must be ${AgeAssurance.minimumAge}+ to use DocTak. Update your date of birth if it is incorrect.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            height: 1.4,
                            color: theme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: canContinue ? _confirm : null,
                  style: OneUIButtons.filled(theme),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeAgreementTile extends StatelessWidget {
  const _AgeAgreementTile({
    required this.theme,
    required this.agreed,
    required this.onChanged,
    required this.label,
  });

  final OneUITheme theme;
  final bool agreed;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: agreed
          ? theme.primary.withValues(alpha: 0.06)
          : theme.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onChanged(!agreed),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: agreed ? theme.primary : theme.border,
              width: agreed ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: _VisibleCheckbox(
                  theme: theme,
                  value: agreed,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Larger, high-contrast checkbox so the control is obvious on light surfaces.
class _VisibleCheckbox extends StatelessWidget {
  const _VisibleCheckbox({
    required this.theme,
    required this.value,
    required this.onChanged,
  });

  final OneUITheme theme;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      button: true,
      label: 'Confirm age requirement',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: value ? theme.primary : theme.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value ? theme.primary : theme.textSecondary,
              width: value ? 0 : 2,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: value
              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

/// Ensures age assurance before opening [destination] (typically the dashboard).
Future<void> openAfterAgeAssurance(
  BuildContext context, {
  required Widget destination,
}) async {
  final confirmed = await AgeAssurance.isConfirmedForCurrentUser();
  if (!context.mounted) return;
  if (confirmed) {
    destination.launch(context, isNewTask: true);
    return;
  }
  await Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (gateCtx) => AgeAssuranceScreen(
        allowExitToLogin: true,
        onConfirmed: () {
          Navigator.of(gateCtx).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => destination),
            (_) => false,
          );
        },
      ),
    ),
    (_) => false,
  );
}
