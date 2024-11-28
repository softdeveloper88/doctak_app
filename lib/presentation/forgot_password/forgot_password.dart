import 'dart:convert';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/presentation/forgot_password/bloc/forgot_event.dart';
import 'package:doctak_app/presentation/forgot_password/bloc/forgot_state.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/sign_up_screen/sign_up_screen.dart';
import 'package:doctak_app/widgets/app_bar/appbar_title.dart';
import 'package:doctak_app/widgets/app_bar/custom_app_bar.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../home_screen/utils/SVCommon.dart';
import 'bloc/forgot_bloc.dart';

class ForgotPassword extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  ForgotBloc forgotBloc = ForgotBloc();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(context),
        body: BlocConsumer<ForgotBloc, ForgotState>(
            bloc: forgotBloc,
            listener: (context, state) {
              if (state is ForgotSuccess) {
                var data = jsonDecode(state.response);
                print(data);
                if (data['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data['message']),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => LoginScreen(),
                      ),
                      (route) => false);
                  // Navigate to the home screen or perform desired action
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data['errors']['email'].toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else if (state is ForgotFailure) {
                // Show an error message
                print(state.error);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        jsonDecode(state.error)['errors']['email'].toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            // child:
            builder: (context, state) {
              var message = '';
              if (state is ForgotSuccess) {
                var data = jsonDecode(state.response);
                if (!data['success']) {
                  // message = data['message'];
                  message = data['errors']['email'].toString();
                }
              } else if (state is ForgotFailure) {
                message = jsonDecode(state.error)['errors']['email'].toString();
              }
              return SizedBox(
                  width: 100.w,
                  child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Form(
                          key: _formKey,
                          child: Container(
                              width: double.maxFinite,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 39),
                              child: Column(children: [
                                CustomTextFormField(
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
                                Text(
                                  message,
                                  style: TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 32),
                                svAppButton(
                                  context: context,
                                  text: 'SEND',
                                  onTap: () {
                                    if (emailController.text.isEmpty) {
                                      return;
                                    }
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                    }

                                    forgotBloc.add(
                                      ForgotPasswordEvent(
                                        username: emailController.text,
                                        // replace with real input
                                      ),
                                    );
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
                                                FocusScope.of(context)
                                                    .unfocus();
                                                Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            SignUpScreen()),
                                                    (route) => false);
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
                                const SizedBox(height: 5)
                              ])))));
            }));
  }

  /// Section Widget
  _buildAppBar(BuildContext context) {
    return CustomAppBar(
      height: 140,
      leadingWidth: 30,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/logo/logo.png',
            width: 400,
            height: 100,
          ),
          AppbarTitle(text: 'Forgot Password'),
        ],
      ),
    );
  }
}
