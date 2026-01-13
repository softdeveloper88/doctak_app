import 'dart:convert';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/presentation/forgot_password/bloc/forgot_event.dart';
import 'package:doctak_app/presentation/forgot_password/bloc/forgot_state.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/sign_up_screen/sign_up_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

import 'bloc/forgot_bloc.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ForgotBloc forgotBloc = ForgotBloc();
  final FocusNode emailFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        resizeToAvoidBottomInset: true,
        body: BlocConsumer<ForgotBloc, ForgotState>(
          bloc: forgotBloc,
          listener: (context, state) {
            if (state is ForgotSuccess) {
              var data = jsonDecode(state.response);
              if (data['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      translation(context).msg_verification_link_sent,
                    ),
                    backgroundColor: theme.success,
                  ),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(translation(context).msg_validation_error),
                    backgroundColor: theme.error,
                  ),
                );
              }
            } else if (state is ForgotFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(translation(context).msg_validation_error),
                  backgroundColor: theme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            String message = '';
            if (state is ForgotSuccess) {
              var data = jsonDecode(state.response);
              if (!data['success']) {
                message = translation(context).msg_validation_error;
              }
            } else if (state is ForgotFailure) {
              message = translation(context).msg_validation_error;
            }

            return Container(
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
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.cardBackground,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: theme.border,
                                    width: 0.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.isDark
                                          ? Colors.black.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                  color: theme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Logo
                          Hero(
                            tag: 'app_logo',
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: theme.authLogoDecoration,
                              child: Image.asset(
                                'assets/logo/logo.png',
                                width: MediaQuery.of(context).size.width * 0.15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Title
                          Text(
                            translation(context).lbl_forgot_password_title,
                            style: theme.authTitleStyle,
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            translation(context).msg_enter_email_to_reset,
                            textAlign: TextAlign.center,
                            style: theme.authSubtitleStyle,
                          ),
                          const SizedBox(height: 32),
                          // Form Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: theme.authCardDecoration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email Label
                                Text(
                                  translation(
                                    context,
                                  ).lbl_enter_your_email_colon,
                                  style: theme.authLabelStyle,
                                ),
                                const SizedBox(height: 10),
                                // Email Field
                                CustomTextFormField(
                                  fillColor: theme.inputBackground,
                                  filled: true,
                                  focusNode: emailFocusNode,
                                  controller: emailController,
                                  hintText: translation(
                                    context,
                                  ).msg_enter_your_email,
                                  textInputType: TextInputType.emailAddress,
                                  prefix: Container(
                                    margin: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      8,
                                      16,
                                    ),
                                    child: Icon(
                                      Icons.email_outlined,
                                      color: theme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  prefixConstraints: const BoxConstraints(
                                    maxHeight: 56,
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
                                    vertical: 18,
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
                                // Error Message
                                if (message.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: theme.error.withOpacity(0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline_rounded,
                                            size: 18,
                                            color: theme.error,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              message,
                                              style: TextStyle(
                                                color: theme.error,
                                                fontSize: 13,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 28),
                                // Send Button
                                theme.buildAuthPrimaryButton(
                                  label: translation(context).lbl_send_button,
                                  isLoading: state is ForgotLoading,
                                  onPressed: () {
                                    if (emailController.text.isEmpty) return;
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      forgotBloc.add(
                                        ForgotPasswordEvent(
                                          username: emailController.text,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),
                                // Sign Up Link
                                theme.buildAuthNavLink(
                                  message: translation(
                                    context,
                                  ).msg_don_t_have_an_account,
                                  actionText: translation(context).lbl_sign_up,
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignUpScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Back to Login Link
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.cardBackground.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.border,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                    color: theme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Back to ${translation(context).lbl_login}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
