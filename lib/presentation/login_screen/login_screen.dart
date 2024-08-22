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
import 'package:doctak_app/widgets/app_bar/appbar_title.dart';
import 'package:doctak_app/widgets/app_bar/custom_app_bar.dart';
import 'package:doctak_app/widgets/custom_outlined_button.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sizer/sizer.dart';

import '../../core/utils/app/AppData.dart';
import '../home_screen/utils/SVCommon.dart';
import 'bloc/login_bloc.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  LoginBloc loginBloc = LoginBloc();

  Future<void> sendVerificationLink(String email, BuildContext context) async {
    // Show the loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Disallow dismissing while loading
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Sending Verification Link'),
          children: [
            Center(
              child: CircularProgressIndicator(
                color: svGetBodyColor(),
              ),
            ),
          ],
        );
      },
    );

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
          const SnackBar(
            content: Text('Verification link sent successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (response.statusCode == 422) {
        // Validation error or user email not found
        // Show error Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Validation error or user email not found'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (response.statusCode == 404) {
        // User already verified
        // Show info Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User already verified'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Something went wrong
        // Show error Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Handle network errors or other exceptions
      // Close the loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _rememberMe = false;

  FocusNode focusNode1 = FocusNode();

  FocusNode focusNode2 = FocusNode();

  void showVerifyMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verify Account'),
          content: const Text('Please verify your account.'),
          actions: [
            TextButton(
              onPressed: () async {
                // Add your logic for resending the verification link here

                String email = emailController.text;
                sendVerificationLink(email, context);
              },
              child: const Text('Resend Link'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: _buildAppBar(context),
          body: BlocListener<LoginBloc, LoginState>(
              bloc: loginBloc,
              listener: (context, state) {
                if (state is LoginSuccess) {
                  if (state.isEmailVerified == '') {
                    showVerifyMessage(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(''),
                        backgroundColor: Colors.green,
                      ),
                    );
                    return;
                  }
                  toasty(context, 'Login successfully',bgColor: Colors.green,textColor: Colors.white);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) =>
                          const SVDashboardScreen(),
                    ),
                  );
                  // Navigate to the home screen or perform desired action
                } else if (state is SocialLoginSuccess) {
                  toasty(context, 'Social Login successfully',bgColor: Colors.green,textColor: Colors.white);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Social Login successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  if (state.response.user?.userType != null) {
                    if (state.response.recentCreated == false) {
                      print(state.response.toJson());
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const SVDashboardScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => SignUpScreen(
                              isSocialLogin: true,
                              firstName: state.response.user?.firstName ?? '',
                              lastName: state.response.user?.lastName ?? '',
                              token: state.response.token ?? ''),
                        ),
                      );
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => SignUpScreen(
                            isSocialLogin: true,
                            firstName: state.response.user?.firstName ?? '',
                            lastName: state.response.user?.lastName ?? '',
                            token: state.response.token ?? ''),
                      ),
                    );
                  }
                  // Navigate to the home screen or perform desired action
                } else if (state is LoginFailure) {
                  // Show an error message
                  toasty(context, 'Login failed please try again',bgColor: Colors.red,textColor: Colors.white);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: SizedBox(
                  width: 100.w,
                  child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: AutofillGroup(
                        child: Form(
                            key: _formKey,
                            child: Container(
                                width: double.maxFinite,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 39),
                                child: Column(children: [
                                  CustomTextFormField(
                                      autofillHint: AutofillHints.username,
                                      focusNode: focusNode1,
                                      controller: emailController,
                                      hintText: translation(context)
                                          .msg_enter_your_email,
                                      textInputType: TextInputType.emailAddress,
                                      prefix: Container(
                                          margin: const EdgeInsets.fromLTRB(
                                              24, 16, 16, 16),
                                          child: CustomImageView(
                                              color: Colors.blueGrey,
                                              imagePath:
                                                  ImageConstant.imgCheckmark,
                                              height: 24,
                                              width: 24)),
                                      prefixConstraints:
                                          const BoxConstraints(maxHeight: 56),
                                      validator: (value) {
                                        if (value == null ||
                                            (!isValidEmail(value,
                                                isRequired: true))) {
                                          return translation(context)
                                              .err_msg_please_enter_valid_email;
                                        }
                                        return null;
                                      },
                                      contentPadding: const EdgeInsets.only(
                                          top: 18, right: 30, bottom: 18)),
                                  const SizedBox(height: 16),
                                  BlocBuilder<LoginBloc, LoginState>(
                                      bloc: loginBloc,
                                      builder: (context, state) {
                                        print(state.isShowPassword);
                                        return CustomTextFormField(
                                            autofillHint: AutofillHints.password,
                                            focusNode: focusNode2,
                                            controller: passwordController,
                                            hintText: translation(context)
                                                .msg_enter_new_password,
                                            textInputAction: TextInputAction.done,
                                            textInputType:
                                                TextInputType.visiblePassword,
                                            prefix: Container(
                                                margin: const EdgeInsets.fromLTRB(
                                                    24, 16, 16, 16),
                                                child: CustomImageView(
                                                    color: Colors.blueGrey,
                                                    imagePath:
                                                        ImageConstant.imgLocation,
                                                    height: 24,
                                                    width: 24)),
                                            prefixConstraints:
                                                const BoxConstraints(
                                                    maxHeight: 56),
                                            suffix: InkWell(
                                                onTap: () {
                                                  loginBloc.add(
                                                      ChangePasswordVisibilityEvent(
                                                          value: !state
                                                              .isShowPassword));
                                                },
                                                child: Container(
                                                    margin:
                                                        const EdgeInsets.fromLTRB(
                                                            30, 16, 24, 16),
                                                    child: state.isShowPassword
                                                        ? const Icon(
                                                            Icons.visibility_off,
                                                            color: Colors.black54,
                                                            size: 24,
                                                          )
                                                        : const Icon(
                                                            Icons.visibility,
                                                            color: Colors.black54,
                                                            size: 24,
                                                          ))),
                                            suffixConstraints:
                                                const BoxConstraints(
                                                    maxHeight: 56),
                                            validator: (value) {
                                              if (value == null ||
                                                  (isValidPassword(value,
                                                      isRequired: true))) {
                                                return translation(context)
                                                    .err_msg_please_enter_valid_password;
                                              }
                                              return null;
                                            },
                                            obscureText: state.isShowPassword);
                                      }),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value!;
                                          });
                                        },
                                      ),
                                      const Text('Remember Me')
                                    ],
                                  ),
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                          onTap: () {
                                            onTapTxtForgotPassword(context);
                                          },
                                          child: Text(
                                              translation(context)
                                                  .msg_forgot_password,
                                              style: CustomTextStyles
                                                  .titleSmallPrimary))),
                                  const SizedBox(height: 32),
                                  svAppButton(
                                    context: context,
                                    text: 'LOGIN',
                                    onTap: () async {
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setBool('acceptTerms', true);
                        
                                      if (_formKey.currentState!.validate()) {
                                        _formKey.currentState!.save();
                                      }
                                      // TermsAndConditionScreen(accept: () async {
                                      print('object');
                                      await FirebaseMessaging.instance
                                          .getToken()
                                          .then((token) async {
                                        loginBloc.add(
                                          LoginButtonPressed(
                                              username: emailController.text,
                                              // replace with real input
                                              password: passwordController.text,
                                              rememberMe: _rememberMe,
                                              deviceToken: token ?? ""
                                              // replace with real input
                                              ),
                                        );
                                      });
                                      // },).launch(context, isNewTask: true);
                                    },
                                  ),
                                  const SizedBox(height: 25),
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 48),
                                          child: Row(children: [
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 1),
                                                child: Text(
                                                    translation(context)
                                                        .msg_don_t_have_an_account,
                                                    style: CustomTextStyles
                                                        .bodyMediumGray600)),
                                            GestureDetector(
                                                onTap: () {
                                                  onTapTxtSignUp(context);
                                                },
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 4),
                                                    child: Text(
                                                        translation(context)
                                                            .lbl_sign_up,
                                                        style: CustomTextStyles
                                                            .titleSmallPrimarySemiBold)))
                                          ]))),
                                  const SizedBox(height: 34),
                                  _buildORDivider(context),
                                  const SizedBox(height: 29),
                                  _buildSocial(context),
                                  const SizedBox(height: 5)
                                ]))),
                      ))))),
    );
  }

  /// Section Widget
  _buildAppBar(BuildContext context) {
    return CustomAppBar(
      height: 140,
      leadingWidth: 56,
      centerTitle: true,
      title: Column(
        children: [
          Image.asset(
            'assets/logo/logo.png',
            width: 400,
            height: 100,
          ),
          AppbarTitle(text: translation(context).lbl_login),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildORDivider(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 9),
              child: SizedBox(width: 137, child: Divider())),
          Text(translation(context).lbl_or, style: theme.textTheme.bodyLarge),
          const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 9),
              child: SizedBox(width: 137, child: Divider()))
        ]);
  }

  /// Section Widget
  Widget _buildSocial(BuildContext context) {
    return Column(children: [
      CustomOutlinedButton(
          text: translation(context).msg_sign_in_with_google,
          leftIcon: Container(
              margin: const EdgeInsets.only(right: 20),
              child: CustomImageView(
                  color: Colors.red,
                  imagePath: ImageConstant.imgGoogle,
                  height: 20,
                  width: 19)),
          onPressed: () {
            onPressedGoogleLogin();
            // onTapSignInWithGoogle(context);
          }),
      const SizedBox(height: 16),
      if (Platform.isIOS)
        CustomOutlinedButton(
            onPressed: () {
              signInWithApple();
            },
            text: translation(context).msg_sign_in_with_apple,
            leftIcon: Container(
                margin: const EdgeInsets.only(right: 30),
                child: CustomImageView(
                    color: Colors.blueGrey,
                    imagePath: ImageConstant.imgApple,
                    height: 20,
                    width: 16))),
      const SizedBox(height: 16),
    ]);
  }

  onTapTxtForgotPassword(BuildContext context) {
    ForgotPassword().launch(context);
  }

  onTapTxtSignUp(BuildContext context) {
    // TODO: implement Actions
    SignUpScreen().launch(context);
    // Navigator.pushNamed(context, AppRoutes.signUpScreen);
  }

  onPressedGoogleLogin() async {
    try {
      // GoogleSignIn().signOut();
      await FirebaseMessaging.instance.getToken().then((token) async {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        print(googleUser.toString());

        GoogleSignInAuthentication googleSignInAuthentication =
            await googleUser!.authentication;
        String accessToken = googleSignInAuthentication.accessToken!;
        // await FirebaseMessaging.instance.getToken().then((token) async {
        //   print('token$googleUser');
        loginBloc.add(SocialLoginButtonPressed(
          email: googleUser.email,
          firstName: googleUser.displayName!.split(' ').first,
          lastName: googleUser.displayName!.split(' ').last,
          isSocialLogin: true,
          provider: 'google',
          token: 'accessToken',
          deviceToken: token ?? '',
        ));
        GoogleSignIn().disconnect();
      });
    } on Exception catch (e) {
      print('error is ....... $e');
      // TODO
    }
  }

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
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
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    await FirebaseMessaging.instance.getToken().then((token) async {
      var response =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      loginBloc.add(SocialLoginButtonPressed(
        email: response.user?.email ?? ' ',
        firstName: response.user?.displayName!.split(' ').first ?? ' ',
        lastName: response.user?.displayName!.split(' ').last ?? ' ',
        isSocialLogin: true,
        provider: 'apple',
        token: response.user!.uid ?? '',
        deviceToken: token ?? '',
      ));
      print("${appleCredential.givenName} ${appleCredential.familyName}");

      GoogleSignIn().disconnect();
    });
  }
}
