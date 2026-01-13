import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/common_navigator.dart';
import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/terms_and_condition_screen/terms_and_condition_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart' hide PageRouteAnimation;
import 'package:sizer/sizer.dart';

import '../home_screen/fragments/profile_screen/bloc/profile_event.dart';
import '../home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'bloc/sign_up_bloc.dart';
import 'component/error_dialog.dart';

// ignore_for_file: must_be_immutable
class SignUpScreen extends StatefulWidget {
  SignUpScreen({
    this.isSocialLogin = false,
    this.firstName,
    this.lastName,
    this.email,
    this.token,
    Key? key,
  }) : super(key: key);
  bool? isSocialLogin;
  String? firstName = '';
  String? lastName = '';
  String? email = '';
  String? token = '';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DropdownBloc dropdownBloc = DropdownBloc();
  ProfileBloc profileBloc = ProfileBloc();
  bool _isChecked = false;

  @override
  void initState() {
    // Social login status initialized
    dropdownBloc.add(LoadDropdownValues());
    profileBloc.add(UpdateFirstDropdownValue(''));
    firstnameController = TextEditingController(text: widget.firstName);
    lastNameController = TextEditingController(text: widget.lastName);

    emailController = TextEditingController(text: widget.email);
    // Initialize controllers
    super.initState();
  }

  // static Widget builder(BuildContext context) {
  String? selectedNewUniversity = '';

  TextEditingController? firstnameController;

  TextEditingController? lastNameController;

  TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final TextEditingController phoneController = TextEditingController();
  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  FocusNode focusNode4 = FocusNode();
  FocusNode focusNode5 = FocusNode();
  FocusNode focusNode6 = FocusNode();

  /// Safely get FCM token with retry logic for FIS_AUTH_ERROR
  Future<String> _getSafeFcmToken() async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } catch (e) {
        debugPrint("FCM token attempt $attempt failed: $e");

        if (e.toString().contains('FIS_AUTH_ERROR')) {
          try {
            await FirebaseMessaging.instance.deleteToken();
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (_) {}
        }

        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }
    return "";
  }

  @override
  void dispose() {
    focusNode1.dispose();
    focusNode2.dispose();
    focusNode3.dispose();
    focusNode4.dispose();
    focusNode5.dispose();
    focusNode6.dispose();
    firstnameController?.dispose();
    lastNameController?.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oneUI = OneUITheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: oneUI.scaffoldBackground,
        resizeToAvoidBottomInset: true,
        body: Container(
          width: 100.w,
          height: 100.h,
          decoration: oneUI.authBackground,
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 20,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.01,
                          ),
                          // App Logo
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: oneUI.authLogoDecoration,
                              child: Hero(
                                tag: 'app_logo',
                                child: Image.asset(
                                  'assets/logo/logo.png',
                                  width:
                                      MediaQuery.of(context).size.width * 0.16,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
                          ),
                          // Welcome Text
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  widget.isSocialLogin ?? false
                                      ? "Complete Profile"
                                      : "Create Account",
                                  style: oneUI.authTitleStyle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Join our community and start your journey",
                                  textAlign: TextAlign.center,
                                  style: oneUI.authSubtitleStyle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Main Form Card
                    Container(
                      width: double.maxFinite,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: oneUI.authCardDecoration,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BlocBuilder<DropdownBloc, DropdownState>(
                              bloc: dropdownBloc,
                              builder: (context, state) {
                                if (state is DataLoaded) {
                                  return _buildFormFields(
                                    context,
                                    state,
                                    oneUI,
                                  );
                                } else {
                                  return Center(
                                    child: CupertinoActivityIndicator(
                                      color: oneUI.primary,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            // Terms Checkbox
                            oneUI.buildCheckboxRow(
                              value: _isChecked,
                              onChanged: (value) {
                                setState(() {
                                  _isChecked = value!;
                                });
                              },
                              label: '',
                              richText: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: oneUI.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text:
                                          translation(context).msg_agree_terms +
                                          ' ',
                                    ),
                                    TextSpan(
                                      text: translation(
                                        context,
                                      ).lbl_privacy_policy,
                                      style: oneUI.authLinkStyle,
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          launchScreen(
                                            context,
                                            TermsAndConditionScreen(),
                                            isNewTask: false,
                                            pageRouteAnimation:
                                                PageRouteAnimation.Slide,
                                            duration: const Duration(
                                              microseconds: 500,
                                            ),
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Sign Up Button
                            BlocListener<DropdownBloc, DropdownState>(
                              listener: (context, state) {
                                if (state is DataLoaded) {
                                  if (state.isSubmit) {
                                    if (state.response['success'] == true) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            translation(
                                              context,
                                            ).msg_login_success,
                                          ),
                                          backgroundColor: oneUI.success,
                                        ),
                                      );
                                      launchScreen(
                                        context,
                                        const SVDashboardScreen(),
                                        isNewTask: true,
                                        pageRouteAnimation:
                                            PageRouteAnimation.Slide,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            state.response['message'] ??
                                                translation(
                                                  context,
                                                ).msg_something_wrong,
                                          ),
                                          backgroundColor: oneUI.error,
                                        ),
                                      );
                                      if (state.response['errors'] != null) {
                                        _showErrorDialog(
                                          state.response['errors'],
                                        );
                                      }
                                    }
                                  }
                                } else if (state is SocialLoginSuccess) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SVDashboardScreen(),
                                    ),
                                    (route) => false,
                                  );
                                } else if (state is DataError ||
                                    state is DropdownError) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        translation(
                                          context,
                                        ).msg_something_wrong,
                                      ),
                                      backgroundColor: oneUI.error,
                                    ),
                                  );
                                }
                              },
                              bloc: dropdownBloc,
                              child: oneUI.buildAuthPrimaryButton(
                                label: 'Sign Up',
                                onPressed: () => onTapSignUp(context),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Login Link
                            oneUI.buildAuthNavLink(
                              message: translation(
                                context,
                              ).msg_already_have_account,
                              actionText: translation(context).lbl_log_in2,
                              onTap: () => onTapTxtLogIn(context),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(
    BuildContext context,
    DataLoaded state,
    OneUITheme oneUI,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // First & Last Name Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translation(context).lbl_enter_first_name,
                    style: oneUI.authLabelStyle,
                  ),
                  const SizedBox(height: 8),
                  _buildNameField(
                    context,
                    firstnameController!,
                    focusNode1,
                    translation(context).lbl_enter_your_name1,
                    oneUI,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translation(context).lbl_enter_last_name,
                    style: oneUI.authLabelStyle,
                  ),
                  const SizedBox(height: 8),
                  _buildNameField(
                    context,
                    lastNameController!,
                    focusNode2,
                    translation(context).lbl_enter_your_name2,
                    oneUI,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Email Field
        if (widget.isSocialLogin == false) ...[
          Text(
            translation(context).lbl_enter_email,
            style: oneUI.authLabelStyle,
          ),
          const SizedBox(height: 8),
          _buildEmailField(context, oneUI),
          const SizedBox(height: 16),
        ],
        // Password Fields
        if (widget.isSocialLogin == false) ...[
          Text(
            translation(context).lbl_create_password,
            style: oneUI.authLabelStyle,
          ),
          const SizedBox(height: 8),
          _buildPasswordField(
            context,
            passwordController,
            focusNode4,
            translation(context).lbl_create_password,
            state.isPasswordVisible,
            oneUI,
          ),
          const SizedBox(height: 16),
          Text('Confirm Password:', style: oneUI.authLabelStyle),
          const SizedBox(height: 8),
          _buildPasswordField(
            context,
            confirmPasswordController,
            focusNode5,
            translation(context).msg_confirm_password,
            state.isPasswordVisible,
            oneUI,
            isConfirm: true,
          ),
        ],
      ],
    );
  }

  Widget _buildNameField(
    BuildContext context,
    TextEditingController controller,
    FocusNode focusNode,
    String hint,
    OneUITheme oneUI,
  ) {
    return CustomTextFormField(
      fillColor: oneUI.inputBackground,
      filled: true,
      autofocus: false,
      focusNode: focusNode,
      controller: controller,
      hintText: hint,
      textInputAction: TextInputAction.next,
      prefix: Container(
        margin: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Icon(CupertinoIcons.person, color: oneUI.primary, size: 20),
      ),
      prefixConstraints: const BoxConstraints(maxHeight: 52),
      validator: (value) {
        if (!isText(value)) {
          return translation(context).err_msg_please_enter_valid_text;
        }
        return null;
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      borderDecoration: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: oneUI.border, width: 0.5),
      ),
    );
  }

  Widget _buildEmailField(BuildContext context, OneUITheme oneUI) {
    return CustomTextFormField(
      fillColor: oneUI.inputBackground,
      filled: true,
      autofocus: false,
      focusNode: focusNode3,
      controller: emailController,
      hintText: translation(context).msg_enter_your_email2,
      textInputType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefix: Container(
        margin: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Icon(CupertinoIcons.mail, color: oneUI.primary, size: 20),
      ),
      prefixConstraints: const BoxConstraints(maxHeight: 52),
      validator: (value) {
        if (value == null || (!isValidEmail(value, isRequired: true))) {
          return translation(context).err_msg_please_enter_valid_email;
        }
        return null;
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      borderDecoration: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: oneUI.border, width: 0.5),
      ),
    );
  }

  Widget _buildPasswordField(
    BuildContext context,
    TextEditingController controller,
    FocusNode focusNode,
    String hint,
    bool isPasswordVisible,
    OneUITheme oneUI, {
    bool isConfirm = false,
  }) {
    return CustomTextFormField(
      fillColor: oneUI.inputBackground,
      filled: true,
      autofocus: false,
      focusNode: focusNode,
      controller: controller,
      hintText: hint,
      textInputAction: isConfirm ? TextInputAction.done : TextInputAction.next,
      textInputType: TextInputType.visiblePassword,
      prefix: Container(
        margin: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Icon(CupertinoIcons.lock, color: oneUI.primary, size: 20),
      ),
      prefixConstraints: const BoxConstraints(maxHeight: 52),
      suffix: InkWell(
        onTap: () {
          dropdownBloc.add(TogglePasswordVisibility());
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(
            isPasswordVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
            color: oneUI.textTertiary,
            size: 20,
          ),
        ),
      ),
      suffixConstraints: const BoxConstraints(maxHeight: 52),
      validator: (value) {
        if (value == null || (!isValidPassword(value, isRequired: true))) {
          return translation(context).err_msg_please_enter_valid_password;
        }
        if (isConfirm && value != passwordController.text) {
          return "Passwords do not match";
        }
        return null;
      },
      borderDecoration: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: oneUI.border, width: 0.5),
      ),
      obscureText: isPasswordVisible,
    );
  }

  void _showErrorDialog(Map<String, dynamic> errors) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ErrorDialog(errors: errors);
      },
    );
  }

  /// Displays a dialog with the [SignUpSuccessDialog] content.
  onTapSignUp(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translation(context).err_msg_please_enter_valid_text),
        ),
      );
      return;
    }

    try {
      final token = await _getSafeFcmToken();

      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              translation(context).err_msg_please_enter_valid_password,
            ),
          ),
        );
      } else {
        if (_isChecked) {
          dropdownBloc.add(
            SignUpButtonPressed(
              username: emailController.text.toString(),
              password: passwordController.text.toString(),
              firstName: firstnameController!.text.toString(),
              lastName: lastNameController!.text.toString(),
              country: profileBloc.country ?? 'United Arab Emirates',
              state: profileBloc.stateName ?? "DUBAI",
              specialty: profileBloc.specialtyName ?? "",
              userType: dropdownBloc.isDoctorRole ? 'doctor' : 'student',
              deviceToken: token,
            ),
          );
        } else {
          toast(translation(context).msg_agree_terms);
        }
      }
    } catch (e) {
      toast(translation(context).msg_something_wrong);
    }
  }

  /// Navigates to the loginScreen when the action is triggered.
  onTapTxtLogIn(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}
