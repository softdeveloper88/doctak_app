import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:doctak_app/core/utils/saved_login_credentials.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/notification_service.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/presentation/forgot_password/forgot_password.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/login_screen/bloc/login_event.dart';
import 'package:doctak_app/presentation/login_screen/bloc/login_state.dart';
import 'package:doctak_app/presentation/login_screen/two_factor_challenge_screen.dart';
import 'package:doctak_app/presentation/sign_up_screen/sign_up_screen.dart';
import 'package:doctak_app/presentation/auth/auth_screen_widgets.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/utils/secure_storage_service.dart';
import 'package:doctak_app/widgets/email_verification_actions.dart';
import 'bloc/login_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  LoginBloc loginBloc = LoginBloc();
  Future<void> sendVerificationLink(String email, BuildContext context) {
    return requestEmailVerificationLink(context: context, email: email);
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
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: theme.isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          translation(context).lbl_saved_logins,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: theme.textPrimary),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: theme.inputBackground, borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.close_rounded, size: 20, color: theme.textSecondary),
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
                            separatorBuilder: (context, index) => Divider(color: theme.divider, thickness: 0.5, height: 1, indent: 72),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: isSelected ? LinearGradient(colors: [theme.primary, theme.primary.withValues(alpha: 0.7)]) : null,
                                            color: isSelected ? null : theme.inputBackground,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Icon(CupertinoIcons.person_fill, size: 22, color: isSelected ? Colors.white : theme.textSecondary),
                                        ),
                                        const SizedBox(width: 16),
                                        // Username
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                username,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 15,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                  color: isSelected ? theme.primary : theme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Tap to sign in',
                                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: theme.textTertiary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Check icon
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                            child: Icon(Icons.check_rounded, size: 18, color: theme.primary),
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
                                  decoration: BoxDecoration(color: theme.inputBackground, borderRadius: BorderRadius.circular(20)),
                                  child: Icon(CupertinoIcons.person_2, size: 40, color: theme.textTertiary),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  translation(context).msg_no_saved_logins,
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: theme.textSecondary),
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
    // Delegate to the shared, APNS-aware getter. On iOS the FCM token cannot be
    // issued until the APNS token is set, so this waits for it first; otherwise
    // login would send an empty device_token and the device gets no pushes.
    final token = await NotificationService.getFcmTokenSafely();
    if (token.isEmpty) {
      print("All FCM token attempts failed, proceeding without token");
    }
    return token;
  }

  void _onUsernameSelected(String username) async {
    Navigator.of(context).pop(); // Close the bottom sheet
    emailController.text = username;

    final prefs = SecureStorageService.instance;
    await prefs.initialize();

    // After a web password reset we clear cached passwords — never auto-login with a stale one.
    final pending = await prefs.getString(SavedLoginCredentials.passwordResetPendingKey);
    if (pending == '1') {
      await SavedLoginCredentials.consumePasswordResetPending();
      passwordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your password was reset. Enter your new password.'),
        ));
      }
      return;
    }

    String? password = await prefs.getString('password_$username');
    if (password == null || password.isEmpty) {
      passwordController.clear();
      return;
    }

    passwordController.text = password;
    // new changes
    await prefs.setBool('acceptTerms', true);
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }

    final token = await _getSafeFcmToken();
    loginBloc.add(LoginButtonPressed(username: emailController.text, password: passwordController.text, rememberMe: true, deviceToken: token));
  }

  @override
  void initState() {
    _loadSavedUsernames();
    _applyPasswordResetPendingState();
    super.initState();
  }

  Future<void> _applyPasswordResetPendingState() async {
    final pending = await SavedLoginCredentials.consumePasswordResetPending();
    if (!pending || !mounted) return;

    passwordController.clear();
    setState(() {
      _rememberMe = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final theme = OneUITheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Your password was reset. Sign in with your new password.'),
        backgroundColor: theme.success,
        duration: const Duration(seconds: 6),
      ));
    });
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
        backgroundColor: theme.authBackgroundColor,
        body: BlocListener<LoginBloc, LoginState>(
          bloc: loginBloc,
          listener: (context, state) {
            if (state is LoginSuccess) {
              loginApp(context);
            } else if (state is LoginRequiresTwoFactor) {
              if (!mounted) return;
              AppNavigator.push(
                context,
                TwoFactorChallengeScreen(
                  pendingToken: state.pendingToken,
                  methods: state.methods,
                  maskedEmail: state.maskedEmail,
                  rememberMe: state.rememberMe,
                  deviceToken: state.deviceToken,
                  initialMessage: state.message,
                  autoResendEmail: state.methods['email'] == true && !state.emailSent,
                ),
              );
            } else if (state is SocialLoginSuccess) {
              if (mounted) {
                toasty(context, translation(context).msg_login_success, bgColor: theme.success, textColor: Colors.white);
              }
              if (mounted) {
                AppNavigator.pushReplacement(context, const SVDashboardScreen());
              }
            } else if (state is LoginFailure) {
              if (mounted) {
                TextInput.finishAutofillContext(shouldSave: false);
                toasty(context, state.error, bgColor: theme.error, textColor: Colors.white);
              }
            }
          },
          child: AuthScaffold(
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthBrandHeader(
                      eyebrow: translation(context).lbl_welcome_back,
                      title: 'Log in to DocTak',
                      subtitle: 'The professional network built for doctors.',
                    ),
                    AuthFormCard(
                      children: [
                        AuthField(
                          label: 'Email address',
                          child: AuthFormInput(
                            icon: CupertinoIcons.mail,
                            controller: emailController,
                            focusNode: focusNode1,
                            hint: translation(context).msg_enter_your_email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || !isValidEmail(value, isRequired: true)) {
                                return translation(context).err_msg_please_enter_valid_email;
                              }
                              return null;
                            },
                          ),
                        ),
                        BlocBuilder<LoginBloc, LoginState>(
                          bloc: loginBloc,
                          builder: (context, state) {
                            return AuthField(
                              label: 'Password',
                              child: AuthFormInput(
                                icon: CupertinoIcons.lock,
                                controller: passwordController,
                                focusNode: focusNode2,
                                hint: translation(context).msg_enter_new_password,
                                obscureText: !state.isShowPassword,
                                textInputAction: TextInputAction.done,
                                suffix: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: Icon(
                                    state.isShowPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                                    size: 21,
                                    color: theme.textTertiary,
                                  ),
                                  onPressed: () => loginBloc.add(
                                    ChangePasswordVisibilityEvent(value: !state.isShowPassword),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return translation(context).err_msg_please_enter_valid_password;
                                  }
                                  return null;
                                },
                              ),
                            );
                          },
                        ),
                        AuthRememberForgotRow(
                          rememberMe: _rememberMe,
                          onRememberChanged: (v) => setState(() => _rememberMe = v),
                          rememberLabel: translation(context).lbl_remember_me,
                          forgotLabel: translation(context).msg_forgot_password,
                          onForgot: () => onTapTxtForgotPassword(context),
                        ),
                        theme.buildAuthPrimaryButton(
                          label: translation(context).lbl_login_button,
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              final token = await _getSafeFcmToken();
                              loginBloc.add(LoginButtonPressed(
                                username: emailController.text,
                                password: passwordController.text,
                                rememberMe: _rememberMe,
                                deviceToken: token,
                              ));
                            }
                          },
                        ),
                        theme.buildOrDivider(),
                        theme.buildAuthSocialPill(
                          label: 'Continue with Google',
                          icon: SvgPicture.asset(imgGoogle, height: 20, width: 20),
                          onTap: onPressedGoogleLogin,
                        ),
                        if (Platform.isIOS)
                          theme.buildAuthSocialPill(
                            label: 'Continue with Apple',
                            icon: CustomImageView(imagePath: imgApple, height: 20, width: 20, color: theme.textPrimary),
                            onTap: signInWithApple,
                          ),
                      ],
                    ),
                    AuthFooterLink(
                      message: translation(context).msg_don_t_have_an_account,
                      actionText: translation(context).lbl_sign_up,
                      onTap: () => onTapTxtSignUp(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onTapTxtForgotPassword(BuildContext context) {
    const ForgotPassword().launch(context);
  }

  void onTapTxtSignUp(BuildContext context) {
    // TODO: implement Actions
    SignUpScreen().launch(context);
    // Navigator.pushNamed(context, AppRoutes.signUpScreen);
  }

  Future<void> onPressedGoogleLogin() async {
    try {
      // Brief delay to ensure platform channels are ready
      await Future.delayed(const Duration(milliseconds: 300));

      // Configure GoogleSignIn with serverClientId (required for v6.2.2 on Android)
      final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: '975716064608-1edbbe269cgibdp16uq1858p665h0id7.apps.googleusercontent.com');

      debugPrint('GoogleSignIn configured with serverClientId for Android compatibility');

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
                content: Text(translation(context).msg_google_signin_failed),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(label: translation(context).lbl_try_again, onPressed: () => onPressedGoogleLogin()),
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
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Sign in to Firebase using the obtained tokens (if Firebase is used)
      UserCredential? userCredential;
      try {
        if (googleAuth.idToken != null) {
          final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
          userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          debugPrint('Firebase sign-in successful: ${userCredential.user?.uid}');
        } else {
          debugPrint('No Google idToken available');
        }
      } catch (e) {
        debugPrint('Firebase sign-in error: $e');
      }

      // Extract display name / email from either Google or Firebase user
      final displayName = googleUser.displayName ?? userCredential?.user?.displayName ?? '';
      final nameParts = displayName.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final email = googleUser.email; // googleUser.email is non-null

      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint('Google Sign-In failed: no id_token returned');
        if (mounted) toast(translation(context).msg_something_wrong);
        return;
      }

      // Debug: Print the data being sent
      debugPrint('=== Google Sign-In Data ===');
      debugPrint('Email: $email');
      debugPrint('First Name: $firstName');
      debugPrint('Last Name: $lastName');
      debugPrint('Provider: google');
      debugPrint('Token length: ${idToken.length}');
      debugPrint('Device Token: $deviceToken');
      debugPrint('========================');

      // Send login event to BLoC
      loginBloc.add(SocialLoginButtonPressed(email: email, firstName: firstName, lastName: lastName, isSocialLogin: true, provider: 'google', token: idToken, deviceToken: deviceToken));

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
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      // The identity token is the JWT we send to our backend
      final appleIdToken = appleCredential.identityToken;
      if (appleIdToken == null) {
        toast(translation(context).msg_something_wrong);
        return;
      }

      // Try to get extra user info via Firebase (optional — only works when
      // Firebase Apple Sign-In is configured). If it fails we continue with
      // whatever Apple gave us directly.
      String? firebaseEmail;
      String? firebaseDisplayName;
      try {
        final oauthCredential = OAuthProvider('apple.com').credential(idToken: appleIdToken, rawNonce: rawNonce);
        final firebaseResponse = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        firebaseEmail = firebaseResponse.user?.email;
        firebaseDisplayName = firebaseResponse.user?.displayName;
      } catch (firebaseError) {
        // Firebase sign-in failed (misconfiguration, network, etc.)
        // Non-fatal: we still have the Apple identity token for our own backend.
        debugPrint('Apple Firebase sign-in skipped: $firebaseError');
      }

      final String deviceToken = await _getSafeFcmToken();

      // Resolve email: Apple credential → Firebase → empty (backend looks up returning users by provider id)
      final String email = appleCredential.email ?? firebaseEmail ?? '';

      // Resolve name parts
      final nameParts = (firebaseDisplayName ?? '').split(' ');
      final String firstName = appleCredential.givenName ?? (nameParts.isNotEmpty ? nameParts.first : '');
      final String lastName  = appleCredential.familyName ?? (nameParts.length > 1 ? nameParts.last : '');

      loginBloc.add(
        SocialLoginButtonPressed(
          email: email,
          firstName: firstName,
          lastName: lastName,
          isSocialLogin: true,
          provider: 'apple',
          token: appleIdToken,
          deviceToken: deviceToken,
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled or Apple auth failed — don't show an error for cancellation
      if (e.code != AuthorizationErrorCode.canceled) {
        debugPrint('Apple Sign-In error: ${e.message}');
        if (mounted) toast(translation(context).msg_something_wrong);
      }
    } catch (e) {
      debugPrint('Apple Sign-In unexpected error: $e');
      if (mounted) toast(translation(context).msg_something_wrong);
    }
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
      toasty(context, translation(context).msg_login_success, bgColor: Colors.green, textColor: Colors.white);
      if (mounted) {
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (BuildContext context) => const SVDashboardScreen(),
        //   ),
        // );
        AppNavigator.toDashboard(context);
      }
    });
  }
}
