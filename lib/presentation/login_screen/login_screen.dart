import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/presentation/forgot_password/forgot_password.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/login_screen/bloc/login_event.dart';
import 'package:doctak_app/presentation/login_screen/bloc/login_state.dart';
import 'package:doctak_app/presentation/sign_up_screen/sign_up_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/utils/app/AppData.dart';
import '../../core/utils/secure_storage_service.dart';
import '../../widgets/show_loading_dialog.dart';
import 'bloc/login_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  LoginBloc loginBloc = LoginBloc();
  Future<void> sendVerificationLink(String email, BuildContext context) async {
    showLoadingDialog(context);
    // Show the loading dialog
    // showDialog(
    //   context: context,
    //   barrierDismissible: false, // Disallow dismissing while loading
    //   builder: (BuildContext context) {
    //     return SimpleDialog(
    //       title: const Text('Sending Verification Link'),
    //       children: [
    //         Center(
    //           child: CircularProgressIndicator(
    //             color: svGetBodyColor(),
    //           ),
    //         ),
    //       ],
    //     );
    //   },
    // );
    try {
      final response = await http.post(
        Uri.parse('${AppData.remoteUrl}/send-verification-link'),
        body: {'email': email},
      );

      // Close the loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Successful API call, handle the response if needed
        // Show success Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context).msg_verification_link_sent),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (response.statusCode == 422) {
        // Validation error or user email not found
        // Show error Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context).msg_validation_error),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (response.statusCode == 404) {
        // User already verified
        // Show info Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context).msg_user_already_verified),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Something went wrong
        // Show error Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context).msg_something_wrong),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Handle network errors or other exceptions
      // Close the loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translation(context).msg_something_wrong),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  bool _rememberMe = false;

  FocusNode focusNode1 = FocusNode();

  FocusNode focusNode2 = FocusNode();

  List<String> _savedUsernames = [];

  Future<void> _loadSavedUsernames() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    setState(() {
      _savedUsernames = [];
    });
    final savedUsernamesStr = await prefs.getString('saved_usernames');
    if (savedUsernamesStr != null && savedUsernamesStr.isNotEmpty) {
      setState(() {
        _savedUsernames = savedUsernamesStr.split('|||');
      });
    }
    if (_savedUsernames.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSavedLogins(context);
      });
    }
  }

  Future<void> _saveLoginDetails(String username, String password) async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    final savedUsernamesStr = await prefs.getString('saved_usernames');
    List<String> usernames = [];
    if (savedUsernamesStr != null && savedUsernamesStr.isNotEmpty) {
      usernames = savedUsernamesStr.split('|||');
    }
    if (!usernames.contains(username)) {
      usernames.add(username);
    }
    await prefs.setString('saved_usernames', usernames.join('|||'));
    await prefs.setString('password_$username', password);
  }

  String? selectedUsername;

  Future<void> _showSavedLogins(BuildContext context1) async {
    final theme = OneUITheme.of(context1);

    showModalBottomSheet(
      context: context1,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          translation(context).lbl_saved_logins,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.inputBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: theme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.divider),
                  // Content
                  Flexible(
                    child: _savedUsernames.isNotEmpty
                        ? ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _savedUsernames.length,
                            separatorBuilder: (context, index) => Divider(
                              color: theme.divider,
                              thickness: 0.5,
                              height: 1,
                              indent: 72,
                            ),
                            itemBuilder: (context, index) {
                              final username = _savedUsernames[index];
                              final isSelected = selectedUsername == username;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      selectedUsername = username;
                                    });
                                    setState(() {
                                      selectedUsername = username;
                                    });
                                    _onUsernameSelected(username);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? LinearGradient(
                                                    colors: [
                                                      theme.primary,
                                                      theme.primary.withOpacity(
                                                        0.7,
                                                      ),
                                                    ],
                                                  )
                                                : null,
                                            color: isSelected
                                                ? null
                                                : theme.inputBackground,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Icon(
                                            CupertinoIcons.person_fill,
                                            size: 22,
                                            color: isSelected
                                                ? Colors.white
                                                : theme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Username
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                username,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 15,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? theme.primary
                                                      : theme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Tap to sign in',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12,
                                                  color: theme.textTertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Check icon
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: theme.primary.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.check_rounded,
                                              size: 18,
                                              color: theme.primary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: theme.inputBackground,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.person_2,
                                    size: 40,
                                    color: theme.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  translation(context).msg_no_saved_logins,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  // Safe area padding
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Safely get FCM token with retry logic for FIS_AUTH_ERROR
  Future<String> _getSafeFcmToken() async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          print(
            "FCM token obtained on attempt $attempt: ${token.substring(0, 20)}...",
          );
          return token;
        }
      } catch (e) {
        print("FCM token attempt $attempt failed: $e");

        // Check if it's a FIS_AUTH_ERROR
        if (e.toString().contains('FIS_AUTH_ERROR')) {
          print(
            "FIS_AUTH_ERROR detected, attempting to delete and reinstall Firebase Installations...",
          );
          try {
            // Delete the Firebase Installation ID to force re-authentication
            await FirebaseMessaging.instance.deleteToken();
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (deleteError) {
            print("Error deleting token: $deleteError");
          }
        }

        if (attempt < maxRetries) {
          print("Retrying in ${retryDelay.inSeconds} seconds...");
          await Future.delayed(retryDelay);
        }
      }
    }

    print("All FCM token attempts failed, proceeding without token");
    return "";
  }

  void _onUsernameSelected(String username) async {
    Navigator.of(context).pop(); // Close the bottom sheet
    emailController.text = username;
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    String? password = await prefs.getString('password_$username');
    if (password != null) {
      passwordController.text = password;
    }
    // new changes
    await prefs.setBool('acceptTerms', true);
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }
    print('object');

    final token = await _getSafeFcmToken();
    loginBloc.add(
      LoginButtonPressed(
        username: emailController.text,
        password: passwordController.text,
        rememberMe: true,
        deviceToken: token,
      ),
    );
  }

  @override
  void initState() {
    _loadSavedUsernames();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackground,
        body: BlocListener<LoginBloc, LoginState>(
          bloc: loginBloc,
          listener: (context, state) {
            if (state is LoginSuccess) {
              loginApp(context);
            } else if (state is SocialLoginSuccess) {
              if (mounted) {
                toasty(
                  context,
                  translation(context).msg_login_success,
                  bgColor: theme.success,
                  textColor: Colors.white,
                );
              }
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        const SVDashboardScreen(),
                  ),
                );
              }
            } else if (state is LoginFailure) {
              if (mounted) {
                TextInput.finishAutofillContext(shouldSave: false);
                toasty(
                  context,
                  translation(context).msg_login_failed,
                  bgColor: theme.error,
                  textColor: Colors.white,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: theme.error,
                  ),
                );
              }
            }
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: theme.authBackground,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            // Logo
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: theme.authLogoDecoration,
                              child: Hero(
                                tag: 'app_logo',
                                child: Image.asset(
                                  'assets/logo/logo.png',
                                  width:
                                      MediaQuery.of(context).size.width * 0.18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Welcome Text
                            Text(
                              translation(context).lbl_welcome_back,
                              style: theme.authSubtitleStyle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              translation(context).lbl_login_button,
                              style: theme.authTitleStyle,
                            ),
                            const SizedBox(height: 32),
                            // Login Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: theme.authCardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Email Field
                                  Text(
                                    translation(
                                      context,
                                    ).lbl_enter_your_email_colon,
                                    style: theme.authLabelStyle,
                                  ),
                                  const SizedBox(height: 10),
                                  CustomTextFormField(
                                    fillColor: theme.inputBackground,
                                    filled: true,
                                    autofocus: false,
                                    autofillHint: const [
                                      AutofillHints.username,
                                    ],
                                    focusNode: focusNode1,
                                    controller: emailController,
                                    hintText: translation(
                                      context,
                                    ).msg_enter_your_email,
                                    textInputType: TextInputType.emailAddress,
                                    prefix: Container(
                                      margin: const EdgeInsets.fromLTRB(
                                        16,
                                        14,
                                        10,
                                        14,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.mail,
                                        color: theme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    prefixConstraints: const BoxConstraints(
                                      maxHeight: 54,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          !isValidEmail(
                                            value,
                                            isRequired: true,
                                          )) {
                                        return translation(
                                          context,
                                        ).err_msg_please_enter_valid_email;
                                      }
                                      return null;
                                    },
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 16,
                                    ),
                                    borderDecoration: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: theme.border,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Password Field
                                  Text(
                                    translation(
                                      context,
                                    ).lbl_enter_your_password_colon,
                                    style: theme.authLabelStyle,
                                  ),
                                  const SizedBox(height: 10),
                                  BlocBuilder<LoginBloc, LoginState>(
                                    bloc: loginBloc,
                                    builder: (context, state) {
                                      return CustomTextFormField(
                                        fillColor: theme.inputBackground,
                                        filled: true,
                                        autofocus: false,
                                        autofillHint: const [
                                          AutofillHints.password,
                                        ],
                                        focusNode: focusNode2,
                                        controller: passwordController,
                                        hintText: translation(
                                          context,
                                        ).msg_enter_new_password,
                                        textInputType:
                                            TextInputType.visiblePassword,
                                        textInputAction: TextInputAction.done,
                                        prefix: Container(
                                          margin: const EdgeInsets.fromLTRB(
                                            16,
                                            14,
                                            10,
                                            14,
                                          ),
                                          child: Icon(
                                            CupertinoIcons.lock,
                                            color: theme.primary,
                                            size: 20,
                                          ),
                                        ),
                                        prefixConstraints: const BoxConstraints(
                                          maxHeight: 54,
                                        ),
                                        suffix: InkWell(
                                          onTap: () {
                                            loginBloc.add(
                                              ChangePasswordVisibilityEvent(
                                                value: !state.isShowPassword,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
                                            child: Icon(
                                              state.isShowPassword
                                                  ? CupertinoIcons.eye_slash
                                                  : CupertinoIcons.eye,
                                              color: theme.textTertiary,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        suffixConstraints: const BoxConstraints(
                                          maxHeight: 54,
                                        ),
                                        obscureText: !state.isShowPassword,
                                        borderDecoration: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.border,
                                            width: 0.5,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Remember Me & Forgot Password
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          activeColor: theme.primary,
                                          side: BorderSide(
                                            color: theme.border,
                                            width: 1.5,
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        translation(context).lbl_remember_me,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: theme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () =>
                                            onTapTxtForgotPassword(context),
                                        child: Text(
                                          translation(
                                            context,
                                          ).msg_forgot_password,
                                          style: theme.authLinkStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  // Login Button
                                  theme.buildAuthPrimaryButton(
                                    label: translation(
                                      context,
                                    ).lbl_login_button,
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        _formKey.currentState!.save();
                                        final token = await _getSafeFcmToken();
                                        loginBloc.add(
                                          LoginButtonPressed(
                                            username: emailController.text,
                                            password: passwordController.text,
                                            rememberMe: _rememberMe,
                                            deviceToken: token,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Sign Up Link
                            theme.buildAuthNavLink(
                              message: translation(
                                context,
                              ).msg_don_t_have_an_account,
                              actionText: translation(context).lbl_sign_up,
                              onTap: () => onTapTxtSignUp(context),
                            ),
                            const SizedBox(height: 28),
                            // OR Divider
                            theme.buildOrDivider(
                              text: translation(context).lbl_or,
                            ),
                            const SizedBox(height: 28),
                            // Social Login Buttons
                            _buildSocial(context, theme),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildSocial(BuildContext context, OneUITheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Sign-in Button
        theme.buildSocialButton(
          icon: SvgPicture.asset(imgGoogle, height: 24, width: 24),
          onTap: () => onPressedGoogleLogin(),
        ),
        if (Platform.isIOS) const SizedBox(width: 20),
        // Apple Sign-in Button (iOS only)
        if (Platform.isIOS)
          theme.buildSocialButton(
            icon: CustomImageView(
              imagePath: imgApple,
              height: 24,
              width: 24,
              color: theme.isDark ? Colors.white : Colors.black,
            ),
            onTap: () => signInWithApple(),
          ),
      ],
    );
  }

  onTapTxtForgotPassword(BuildContext context) {
    const ForgotPassword().launch(context);
  }

  onTapTxtSignUp(BuildContext context) {
    // TODO: implement Actions
    SignUpScreen().launch(context);
    // Navigator.pushNamed(context, AppRoutes.signUpScreen);
  }

  onPressedGoogleLogin() async {
    try {
      // Brief delay to ensure platform channels are ready
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Configure GoogleSignIn with serverClientId (required for v6.2.2 on Android)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '975716064608-1edbbe269cgibdp16uq1858p665h0id7.apps.googleusercontent.com',
      );

      debugPrint(
        'GoogleSignIn configured with serverClientId for Android compatibility',
      );

      // Get Firebase device token first (optional)
      String deviceToken = "";
      try {
        if (Firebase.apps.isNotEmpty) {
          deviceToken = await _getSafeFcmToken();
        }
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      // Sign out first to allow account selection
      GoogleSignInAccount? googleUser;
      
      try {
        // Try sign out first (ignore errors)
        try {
          await googleSignIn.signOut();
        } catch (_) {}

        // Attempt sign in once
        googleUser = await googleSignIn.signIn();
      } on PlatformException catch (e) {
        debugPrint('Google Sign-In platform error: ${e.code} - ${e.message}');
        
        if (e.code == 'channel-error') {
          // Show user-friendly message for channel error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  translation(context).msg_google_signin_failed,
                ),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: translation(context).lbl_try_again,
                  onPressed: () => onPressedGoogleLogin(),
                ),
              ),
            );
          }
          return;
        }
        rethrow;
      }

      if (googleUser == null) {
        // User cancelled the sign-in
        debugPrint('Google Sign-In cancelled by user');
        return;
      }

      debugPrint('Google user: ${googleUser.email}');

      // Obtain the auth details (id token)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Sign in to Firebase using the obtained tokens (if Firebase is used)
      UserCredential? userCredential;
      try {
        if (googleAuth.idToken != null) {
          final credential = GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
          );
          userCredential = await FirebaseAuth.instance.signInWithCredential(
            credential,
          );
          debugPrint(
            'Firebase sign-in successful: ${userCredential.user?.uid}',
          );
        } else {
          debugPrint('No Google idToken available');
        }
      } catch (e) {
        debugPrint('Firebase sign-in error: $e');
      }

      // Extract display name / email from either Google or Firebase user
      final displayName =
          googleUser.displayName ?? userCredential?.user?.displayName ?? '';
      final nameParts = displayName.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      final email = googleUser.email; // googleUser.email is non-null

      // Prefer ID token, fall back to Google user id
      final tokenToSend = googleAuth.idToken ?? googleUser.id;

      // Debug: Print the data being sent
      debugPrint('=== Google Sign-In Data ===');
      debugPrint('Email: $email');
      debugPrint('First Name: $firstName');
      debugPrint('Last Name: $lastName');
      debugPrint('Provider: google');
      debugPrint('Token length: ${tokenToSend.length}');
      debugPrint('Device Token: $deviceToken');
      debugPrint('========================');

      // Send login event to BLoC
      loginBloc.add(
        SocialLoginButtonPressed(
          email: email,
          firstName: firstName,
          lastName: lastName,
          isSocialLogin: true,
          provider: 'google',
          token: tokenToSend,
          deviceToken: deviceToken,
        ),
      );

      // Sign out to allow different account selection next time
      try {
        await googleSignIn.signOut();
      } catch (e) {
        // ignore errors on sign out
      }
    } on PlatformException catch (e) {
      // Handle platform-specific exceptions
      debugPrint('Google Sign-In platform error: ${e.code} - ${e.message}');
      if (e.code != 'sign_in_canceled' && mounted) {
        toast(translation(context).msg_something_wrong);
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (mounted) {
        toast(translation(context).msg_something_wrong);
      }
    }
  }

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  signInWithApple() async {
    //   print('token$token');
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);
    String token = await _getSafeFcmToken();
    var response = await FirebaseAuth.instance.signInWithCredential(
      oauthCredential,
    );
    if (token.isNotEmpty) {
      loginBloc.add(
        SocialLoginButtonPressed(
          email: response.user?.email ?? ' ',
          firstName: response.user?.displayName?.split(' ').first ?? ' ',
          lastName: response.user?.displayName?.split(' ').last ?? ' ',
          isSocialLogin: true,
          provider: 'apple',
          token: response.user?.uid ?? '',
          deviceToken: token,
        ),
      );
    } else {
      toast(translation(context).msg_something_wrong);
    }
    print("${appleCredential.givenName} ${appleCredential.familyName}");

    // No need to disconnect GoogleSignIn here since we're using Apple Sign-In
  }

  Future<void> loginApp(BuildContext context) async {
    print(emailController.text);
    // if (Platform.isIOS) {
    _saveLoginDetails(emailController.text, passwordController.text);
    // }
    // if (mounted) {
    // // toasty(context, 'Login successfully', bgColor: Colors.green, textColor: Colors.white);
    // //   ScaffoldMessenger.of(context).showSnackBar(
    // //     const SnackBar(
    // //       content: Text('Login successfully'),
    // //       backgroundColor: Colors.green,
    // //     ),
    // //   );
    // }
    TextInput.finishAutofillContext(shouldSave: true);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      toasty(
        context,
        translation(context).msg_login_success,
        bgColor: Colors.green,
        textColor: Colors.white,
      );
      if (mounted) {
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (BuildContext context) => const SVDashboardScreen(),
        //   ),
        // );
        const SVDashboardScreen().launch(
          context,
          isNewTask: true,
          pageRouteAnimation: PageRouteAnimation.Slide,
        );
      }
    });
  }
}
