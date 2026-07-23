import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/age_assurance.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/core/utils/common_navigator.dart';
import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/presentation/auth/auth_screen_widgets.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/terms_and_condition_screen/terms_and_condition_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/one_ui_confirm_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart' hide PageRouteAnimation;

import '../home_screen/fragments/profile_screen/bloc/profile_event.dart';
import '../home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'bloc/sign_up_bloc.dart';

// ignore_for_file: must_be_immutable

class SignUpScreen extends StatefulWidget {
  SignUpScreen({this.isSocialLogin = false, this.firstName, this.lastName, this.email, this.token, super.key});
  bool? isSocialLogin;
  String? firstName = '';
  String? lastName = '';
  String? email = '';
  String? token = '';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DropdownBloc dropdownBloc = DropdownBloc();
  final ProfileBloc profileBloc = ProfileBloc();
  bool _isChecked = false;
  bool _autoValidate = false;
  bool _ageConfirmed = false;
  DateTime? _dateOfBirth;
  Map<String, String> _fieldErrors = {};

  TextEditingController? firstnameController;
  TextEditingController? lastNameController;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final FocusNode focusNode1 = FocusNode();
  final FocusNode focusNode2 = FocusNode();
  final FocusNode focusNode3 = FocusNode();
  final FocusNode focusNode4 = FocusNode();
  final FocusNode focusNode5 = FocusNode();

  @override
  void initState() {
    super.initState();
    dropdownBloc.add(LoadDropdownValues());
    profileBloc.add(UpdateFirstDropdownValue(''));
    firstnameController = TextEditingController(text: widget.firstName);
    lastNameController = TextEditingController(text: widget.lastName);
    emailController.text = widget.email ?? '';
    passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    focusNode1.dispose();
    focusNode2.dispose();
    focusNode3.dispose();
    focusNode4.dispose();
    focusNode5.dispose();
    firstnameController?.dispose();
    lastNameController?.dispose();
    emailController.dispose();
    passwordController.removeListener(_onPasswordChanged);
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<String> _getSafeFcmToken() async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) return token;
      } catch (e) {
        if (e.toString().contains('FIS_AUTH_ERROR')) {
          try {
            await FirebaseMessaging.instance.deleteToken();
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (_) {}
        }
        if (attempt < maxRetries) await Future.delayed(retryDelay);
      }
    }
    return '';
  }

  Future<void> _pickDateOfBirth() async {
    final theme = OneUITheme.of(context);
    final now = DateTime.now();
    final min = DateTime(now.year - 100, now.month, now.day);
    // Cap picker at minimum age so underage dates cannot be chosen.
    final max = DateTime(now.year - AgeAssurance.minimumAge, now.month, now.day);
    DateTime temp = _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);
    if (temp.isAfter(max)) temp = max;
    if (temp.isBefore(min)) temp = min;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 280,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Date of birth',
                          style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _dateOfBirth = temp);
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
                      brightness: theme.isDark ? Brightness.dark : Brightness.light,
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: temp.isBefore(min)
                          ? min
                          : (temp.isAfter(max) ? max : temp),
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

  Widget _dobField(OneUITheme theme) {
    final dob = _dateOfBirth;
    final age = dob != null ? AgeAssurance.ageFromDateOfBirth(dob) : null;
    final eligible = dob != null && AgeAssurance.meetsMinimumAge(dob);
    final error = _fieldErrors['dob'];

    return AuthField(
      label: 'Date of birth *',
      error: error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _pickDateOfBirth,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: error != null
                        ? theme.error
                        : (!eligible && dob != null)
                            ? theme.error
                            : theme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.calendar, size: 20, color: theme.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dob != null ? AgeAssurance.formatDob(dob) : 'Select date of birth',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          color: dob != null ? theme.textPrimary : theme.textTertiary,
                        ),
                      ),
                    ),
                    if (age != null)
                      Text(
                        'Age $age',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: eligible ? theme.success : theme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (dob != null && !eligible)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'You must be at least ${AgeAssurance.minimumAge} years old. Account creation is blocked.',
                style: TextStyle(fontSize: 12, color: theme.error, fontFamily: 'Poppins'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Required for age verification (minimum ${AgeAssurance.minimumAge}+).',
                style: TextStyle(fontSize: 12, color: theme.textTertiary, fontFamily: 'Poppins'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isSocial = widget.isSocialLogin ?? false;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.authBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: BlocListener<DropdownBloc, DropdownState>(
          bloc: dropdownBloc,
          listener: (context, state) {
            if (state is DataLoaded && state.isSubmit) {
              if (state.response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(translation(context).msg_login_success), backgroundColor: theme.success),
                );
                AppNavigator.toDashboard(context);
              } else if (state.response['errors'] != null) {
                final errors = state.response['errors'] as Map<String, dynamic>;
                setState(() {
                  _fieldErrors = {};
                  errors.forEach((key, value) {
                    if (value is List && value.isNotEmpty) {
                      _fieldErrors[key] = value.first.toString();
                    } else if (value is String) {
                      _fieldErrors[key] = value;
                    }
                  });
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.response['message'] ?? translation(context).msg_something_wrong),
                    backgroundColor: theme.error,
                  ),
                );
              }
            } else if (state is SocialLoginSuccess) {
              AppNavigator.toDashboard(context);
            } else if (state is DataError || state is DropdownError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(translation(context).msg_something_wrong), backgroundColor: theme.error),
              );
            }
          },
          child: AuthScaffold(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthBrandHeader(
                    eyebrow: isSocial ? 'Complete profile' : 'Join DocTak',
                    title: isSocial ? 'Complete your account' : 'Create your account',
                    subtitle: 'Connect with peers and grow your practice.',
                  ),
                  BlocBuilder<DropdownBloc, DropdownState>(
                    bloc: dropdownBloc,
                    builder: (context, state) {
                      if (state is! DataLoaded && state is! DropdownError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CupertinoActivityIndicator(color: theme.primary)),
                        );
                      }
                      final showPassword = state is DataLoaded ? state.isPasswordVisible : true;
                      return AuthFormCard(
                        children: [
                          AuthFieldRow(
                            children: [
                              AuthField(
                                label: 'First name',
                                error: _fieldErrors['first_name'],
                                child: _nameInput(firstnameController!, focusNode1, translation(context).lbl_enter_your_name1, theme),
                              ),
                              AuthField(
                                label: 'Last name',
                                error: _fieldErrors['last_name'],
                                child: _nameInput(lastNameController!, focusNode2, translation(context).lbl_enter_your_name2, theme),
                              ),
                            ],
                          ),
                          if (!isSocial) ...[
                            AuthField(
                              label: 'Email address',
                              error: _fieldErrors['email'],
                              child: _emailInput(theme),
                            ),
                            _dobField(theme),
                            theme.buildCheckboxRow(
                              value: _ageConfirmed,
                              onChanged: (value) => setState(() => _ageConfirmed = value ?? false),
                              label:
                                  'I confirm I am at least ${AgeAssurance.minimumAge} years old. Underage accounts cannot be created.',
                            ),
                            AuthField(
                              label: 'Create password',
                              error: _fieldErrors['password'],
                              child: _passwordInput(
                                passwordController,
                                focusNode4,
                                translation(context).lbl_create_password,
                                showPassword,
                                theme,
                                showStrength: true,
                              ),
                            ),
                            AuthField(
                              label: 'Confirm password',
                              child: _passwordInput(
                                confirmPasswordController,
                                focusNode5,
                                translation(context).msg_confirm_password,
                                showPassword,
                                theme,
                                isConfirm: true,
                              ),
                            ),
                          ],
                          if (isSocial) ...[
                            _dobField(theme),
                            theme.buildCheckboxRow(
                              value: _ageConfirmed,
                              onChanged: (value) => setState(() => _ageConfirmed = value ?? false),
                              label:
                                  'I confirm I am at least ${AgeAssurance.minimumAge} years old. Underage accounts cannot be created.',
                            ),
                          ],
                          theme.buildCheckboxRow(
                            value: _isChecked,
                            onChanged: (value) => setState(() => _isChecked = value ?? false),
                            label: '',
                            richText: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 13, color: theme.textSecondary, fontWeight: FontWeight.w500, fontFamily: 'Poppins', height: 1.45),
                                children: [
                                  TextSpan(text: '${translation(context).msg_agree_terms} '),
                                  TextSpan(
                                    text: translation(context).lbl_privacy_policy,
                                    style: theme.authLinkStyle,
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => AppNavigator.push(
                                            context,
                                            TermsAndConditionScreen(),
                                            animation: PageRouteAnimation.Slide,
                                            duration: const Duration(microseconds: 500),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          theme.buildAuthPrimaryButton(
                            label: isSocial ? 'Continue' : 'Sign up',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () => onTapSignUp(context),
                          ),
                        ],
                      );
                    },
                  ),
                  AuthFooterLink(
                    message: translation(context).msg_already_have_account,
                    actionText: translation(context).lbl_log_in2,
                    onTap: () => onTapTxtLogIn(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameInput(TextEditingController controller, FocusNode node, String hint, OneUITheme theme) {
    return AuthFormInput(
      icon: CupertinoIcons.person,
      controller: controller,
      focusNode: node,
      hint: hint,
      textInputAction: TextInputAction.next,
      autovalidateMode:
          _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      validator: (value) =>
          isText(value) ? null : translation(context).err_msg_please_enter_valid_text,
    );
  }

  Widget _emailInput(OneUITheme theme) {
    return AuthFormInput(
      icon: CupertinoIcons.mail,
      controller: emailController,
      focusNode: focusNode3,
      hint: translation(context).msg_enter_your_email2,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autovalidateMode:
          _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      validator: (value) {
        if (value == null || !isValidEmail(value, isRequired: true)) {
          return translation(context).err_msg_please_enter_valid_email;
        }
        return null;
      },
    );
  }

  Widget _passwordInput(
    TextEditingController controller,
    FocusNode node,
    String hint,
    bool showPassword,
    OneUITheme theme, {
    bool isConfirm = false,
    bool showStrength = false,
  }) {
    return AuthFormInput(
      icon: CupertinoIcons.lock,
      controller: controller,
      focusNode: node,
      hint: hint,
      obscureText: showPassword,
      textInputAction: isConfirm ? TextInputAction.done : TextInputAction.next,
      autovalidateMode:
          _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      belowShell: showStrength ? PasswordStrengthBar(password: controller.text) : null,
      suffix: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        icon: Icon(
          showPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
          size: 21,
          color: theme.textTertiary,
        ),
        onPressed: () => dropdownBloc.add(TogglePasswordVisibility()),
      ),
      onChanged: showStrength || isConfirm ? (_) => setState(() {}) : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return isConfirm ? 'Please confirm your password' : 'Please enter a password';
        }
        if (isConfirm && value != passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Future<void> onTapSignUp(BuildContext context) async {
    final isSocial = widget.isSocialLogin ?? false;
    setState(() => _autoValidate = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).err_msg_please_enter_valid_text)));
      return;
    }
    _formKey.currentState?.save();
    setState(() => _fieldErrors = {});

    if (_dateOfBirth == null) {
      setState(() => _fieldErrors = {'dob': 'Date of birth is required.'});
      toast('Please select your date of birth.');
      return;
    }
    if (!AgeAssurance.meetsMinimumAge(_dateOfBirth!)) {
      setState(() {
        _fieldErrors = {
          'dob':
              'You must be at least ${AgeAssurance.minimumAge} years old to use DocTak.',
        };
      });
      toast(
        'DocTak is only available to users age ${AgeAssurance.minimumAge} and older.',
      );
      return;
    }
    if (!_ageConfirmed) {
      toast(
        'Please confirm you are at least ${AgeAssurance.minimumAge} years old.',
      );
      return;
    }

    if (!isSocial && passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (!_isChecked) {
      toast(translation(context).msg_agree_terms);
      return;
    }

    try {
      final token = await _getSafeFcmToken();
      if (isSocial) {
        await AgeAssurance.markConfirmed(
          dateOfBirth: _dateOfBirth!,
          userId: AppData.logInUserId?.toString(),
        );
        dropdownBloc.add(
          SocialButtonPressed(
            token: widget.token ?? '',
            firstName: firstnameController!.text,
            lastName: lastNameController!.text,
            phone: '',
            country: profileBloc.country ?? 'United Arab Emirates',
            state: profileBloc.stateName ?? 'DUBAI',
            specialty: profileBloc.specialtyName ?? '',
            userType: dropdownBloc.isDoctorRole ? 'doctor' : 'student',
            deviceToken: token,
          ),
        );
        return;
      }
      dropdownBloc.add(
        SignUpButtonPressed(
          username: emailController.text,
          password: passwordController.text,
          firstName: firstnameController!.text,
          lastName: lastNameController!.text,
          country: profileBloc.country ?? 'United Arab Emirates',
          state: profileBloc.stateName ?? 'DUBAI',
          specialty: profileBloc.specialtyName ?? '',
          userType: dropdownBloc.isDoctorRole ? 'doctor' : 'student',
          deviceToken: token,
          dob: AgeAssurance.formatDob(_dateOfBirth!),
        ),
      );
    } catch (_) {
      toast(translation(context).msg_something_wrong);
    }
  }

  void onTapTxtLogIn(BuildContext context) {
    AppNavigator.pushAndRemoveAll(context, const LoginScreen());
  }
}
