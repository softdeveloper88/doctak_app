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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sizer/sizer.dart';

import '../../core/utils/app/AppData.dart';
import '../../widgets/show_loading_dialog.dart';
import '../home_screen/utils/SVCommon.dart';
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedUsernames = prefs.getStringList('saved_usernames') ?? [];
    });
    if (_savedUsernames.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSavedLogins(context);
      });
    }
  }

  Future<void> _saveLoginDetails(String username, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> usernames = prefs.getStringList('saved_usernames') ?? [];
    if (!usernames.contains(username)) {
      usernames.add(username);
    }
    await prefs.setStringList('saved_usernames', usernames);
    await prefs.setString('password_$username', password);
  }

  String? selectedUsername;

  Future<void> _showSavedLogins(BuildContext context1) async {
    showModalBottomSheet(
      context: context1,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    translation(context).lbl_saved_logins,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _savedUsernames.isNotEmpty
                  ? ListView.separated(
                      shrinkWrap: true,
                      itemCount: _savedUsernames.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final username = _savedUsernames[index];
                        final isSelected = selectedUsername == username;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade200,
                            child: Icon(
                              CupertinoIcons.profile_circled,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            username,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.black,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              selectedUsername = username;
                            });
                            _onUsernameSelected(username);
                            // Navigator.pop(context1); // Close the sheet after selection
                          },
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        translation(context).msg_no_saved_logins,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  void _onUsernameSelected(String username) async {
    Navigator.of(context).pop(); // Close the bottom sheet
    emailController.text = username;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? password = prefs.getString('password_$username');
    if (password != null) {
      passwordController.text = password;
    }
    // new changes
    await prefs.setBool('acceptTerms', true);
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }
    print('object');
    if (Platform.isAndroid) {
      await FirebaseMessaging.instance.getToken().then((token) {
        print("token $token");
        loginBloc.add(
          LoginButtonPressed(
              username: emailController.text,
              // replace with real input
              password: passwordController.text,
              rememberMe: true,
              deviceToken: token ?? ""
              // replace with real input
              ),
        );
      });
    } else {
      String? token = await FirebaseMessaging.instance.getToken();
      loginBloc.add(
        LoginButtonPressed(
            username: emailController.text,
            // replace with real input
            password: passwordController.text,
            rememberMe: true,
            deviceToken: token ?? ""
            // replace with real input
            ),
      );
    }
  }

  @override
  void initState() {
    _loadSavedUsernames();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: svGetScaffoldColor(),
          body: BlocListener<LoginBloc, LoginState>(
              bloc: loginBloc,
              listener: (context, state) {
                if (state is LoginSuccess) {
                  // if (state.isEmailVerified == '') {
                  //   showVerifyMessage(context, () {
                  //     String email = emailController.text;
                  //     sendVerificationLink(email, context);
                  //   });
                  //   if (mounted) {
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       const SnackBar(
                  //         content: Text(''),
                  //         backgroundColor: Colors.green,
                  //       ),
                  //     );
                  //   }
                  //   return;
                  // }
                  loginApp(context);
                } else if (state is SocialLoginSuccess) {
                  if (mounted) {
                    toasty(context, translation(context).msg_login_success,
                        bgColor: Colors.green, textColor: Colors.white);
                  }
                  // if (state.response.user?.userType != null) {
                  //   if (state.response.recentCreated == false) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const SVDashboardScreen(),
                      ),
                    );
                  }
                  //   } else {
                  //     if (mounted) {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (BuildContext context) => SignUpScreen(
                  //             isSocialLogin: true,
                  //             firstName: state.response.user?.firstName ?? '',
                  //             lastName: state.response.user?.lastName ?? '',
                  //             email: state.response.user?.email ?? '',
                  //             token: state.response.token ?? '',
                  //           ),
                  //         ),
                  //       );
                  //     }
                  //   }
                  // } else {
                  //   if (mounted) {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (BuildContext context) => SignUpScreen(
                  //           isSocialLogin: true,
                  //           firstName: state.response.user?.firstName ?? '',
                  //           lastName: state.response.user?.lastName ?? '',
                  //           email: state.response.user?.email ?? '',
                  //           token: state.response.token ?? '',
                  //         ),
                  //       ),
                  //     );
                  //   }
                  // }
                } else if (state is LoginFailure) {
                  if (mounted) {
                    TextInput.finishAutofillContext(shouldSave: false);
                    toasty(context, translation(context).msg_login_failed,
                        bgColor: Colors.red, textColor: Colors.white);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.blue.shade50.withOpacity(0.8),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo and Welcome Text Section
                            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                            Hero(
                              tag: 'app_logo',
                              child: Image.asset(
                                'assets/logo/logo.png',
                                width: MediaQuery.of(context).size.width * 0.18,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Log In!",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 20,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // Email Field
                                  Text(
                                    translation(context).lbl_enter_your_email_colon,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextFormField(
                                    fillColor: Colors.grey.shade50,
                                    filled: true,
                                    autofillHint: const [AutofillHints.username],
                                    focusNode: focusNode1,
                                    controller: emailController,
                                    hintText: translation(context).msg_enter_your_email,
                                    textInputType: TextInputType.emailAddress,
                                    prefix: Container(
                                      margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                                      child: Icon(
                                        Icons.email_outlined,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    prefixConstraints: const BoxConstraints(maxHeight: 56),
                                    validator: (value) {
                                      if (value == null || !isValidEmail(value, isRequired: true)) {
                                        return translation(context)
                                            .err_msg_please_enter_valid_email;
                                      }
                                      return null;
                                    },
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 16),
                                    borderDecoration: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Password Field
                                  Text(
                                    translation(context).lbl_enter_your_password_colon,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  BlocBuilder<LoginBloc, LoginState>(
                                    bloc: loginBloc,
                                    builder: (context, state) {
                                      return CustomTextFormField(
                                        fillColor: Colors.grey.shade50,
                                        filled: true,
                                        autofillHint: const [AutofillHints.password],
                                        focusNode: focusNode2,
                                        controller: passwordController,
                                        hintText: translation(context).msg_enter_new_password,
                                        textInputType: TextInputType.visiblePassword,
                                        textInputAction: TextInputAction.done,
                                        prefix: Container(
                                          margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                                          child: Icon(
                                            Icons.lock_outline,
                                            color: theme.colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                        prefixConstraints: const BoxConstraints(maxHeight: 56),
                                        suffix: InkWell(
                                          onTap: () {
                                            loginBloc.add(
                                              ChangePasswordVisibilityEvent(
                                                  value: !state.isShowPassword),
                                            );
                                          },
                                          child: Container(
                                            margin:
                                            const EdgeInsets.symmetric(horizontal: 16),
                                            child: Icon(
                                              state.isShowPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: theme.colorScheme.primary.withOpacity(0.7),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        suffixConstraints: const BoxConstraints(maxHeight: 56),
                                        obscureText: !state.isShowPassword,
                                        borderDecoration: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade200),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Remember Me Checkbox and Forgot Password
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          activeColor: theme.colorScheme.primary,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        translation(context).lbl_remember_me,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => onTapTxtForgotPassword(context),
                                        child: Text(
                                          translation(context).msg_forgot_password,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),

                                  // Login Button
                                  Container(
                                    width: double.infinity,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.primary.withOpacity(0.7),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_formKey.currentState!.validate()) {
                                          _formKey.currentState!.save();
                                          final token = await FirebaseMessaging.instance.getToken();
                                          loginBloc.add(
                                            LoginButtonPressed(
                                              username: emailController.text,
                                              password: passwordController.text,
                                              rememberMe: _rememberMe,
                                              deviceToken: token ?? "",
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        translation(context).lbl_login_button,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Signup and Social Login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  translation(context).msg_don_t_have_an_account,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => onTapTxtSignUp(context),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      translation(context).lbl_sign_up,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    translation(context).lbl_or,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSocial(context),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
          )),
    );
  }
  /// Section Widget
  Widget _buildSocial(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Sign-in Button
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                onPressedGoogleLogin();
              },
              child: Center(
                child: SvgPicture.asset(
                   imgGoogle,
                  height: 24,
                  width: 24,
                  // color: Colors.red,
                ),
              ),
            ),
          ),
        ),
        if (Platform.isIOS) const SizedBox(width: 20),
        // Apple Sign-in Button (iOS only)
        if (Platform.isIOS)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  signInWithApple();
                },
                child: Center(
                  child: CustomImageView(
                    imagePath: imgApple,
                    height: 24,
                    width: 24,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
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
      // GoogleSignIn().signOut();
      String? token = "";
      if (Platform.isAndroid) {
        await FirebaseMessaging.instance.getToken().then((token) async {
          debugPrint(token);
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
            token: googleUser.id,
            deviceToken: token ?? '',
          ));
          GoogleSignIn().disconnect();
        }).catchError((onError){
          toast(translation(context).msg_login_failed);
        });
      } else {
        // String? token = await FirebaseMessaging.instance.getToken();

        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        print(googleUser.toString());

        GoogleSignInAuthentication googleSignInAuthentication =
            await googleUser!.authentication;
        String accessToken = googleSignInAuthentication.accessToken!;
        await FirebaseMessaging.instance.getToken().then((token) async {
          //   print('token$googleUser');

          loginBloc.add(SocialLoginButtonPressed(
            email: googleUser.email,
            firstName: googleUser.displayName!.split(' ').first,
            lastName: googleUser.displayName!.split(' ').last,
            isSocialLogin: true,
            provider: 'google',
            token: googleUser.id,
            deviceToken: token ?? '',
          ));
          GoogleSignIn().disconnect();
        }).catchError((onError){
          toast(translation(context).msg_login_failed);
        });}

    } on Exception catch (e) {
      toast(translation(context).msg_something_wrong);
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
    String? token = "";
    if (Platform.isAndroid) {
      token = await FirebaseMessaging.instance.getToken();
    } else {
      token = await FirebaseMessaging.instance.getToken();
    }
    var response = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    if (token != "") {
      loginBloc.add(SocialLoginButtonPressed(
        email: response.user?.email ?? ' ',
        firstName: response.user?.displayName!.split(' ').first ?? ' ',
        lastName: response.user?.displayName!.split(' ').last ?? ' ',
        isSocialLogin: true,
        provider: 'apple',
        token: response.user!.uid ?? '',
        deviceToken: token ?? '',
      ));
    } else {
      toast(translation(context).msg_something_wrong);
    }
    print("${appleCredential.givenName} ${appleCredential.familyName}");

    GoogleSignIn().disconnect();
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
      toasty(context, translation(context).msg_login_success,
          bgColor: Colors.green, textColor: Colors.white);
      if (mounted) {
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (BuildContext context) => const SVDashboardScreen(),
        //   ),
        // );
        const SVDashboardScreen().launch(context,
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
      }
    });
  }
}
