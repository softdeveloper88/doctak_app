import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/core/utils/common_navigator.dart';
import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/presentation/auth/auth_screen_widgets.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/terms_and_condition_screen/terms_and_condition_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
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
              AppNavigator.pushAndRemoveAll(context, const SVDashboardScreen());
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
    setState(() => _autoValidate = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).err_msg_please_enter_valid_text)));
      return;
    }
    _formKey.currentState?.save();
    setState(() => _fieldErrors = {});

    if (passwordController.text != confirmPasswordController.text) {
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
