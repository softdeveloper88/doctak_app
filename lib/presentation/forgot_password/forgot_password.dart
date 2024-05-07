import 'dart:convert';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/presentation/forgot_password/bloc/forgot_event.dart';
import 'package:doctak_app/presentation/forgot_password/bloc/forgot_state.dart';
import 'package:doctak_app/presentation/login_screen/bloc/login_state.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/sign_up_screen/sign_up_screen.dart';
import 'package:doctak_app/widgets/app_bar/appbar_leading_image.dart';
import 'package:doctak_app/widgets/app_bar/appbar_title.dart';
import 'package:doctak_app/widgets/app_bar/custom_app_bar.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

import '../../widgets/error_dialog.dart';
import '../home_screen/utils/SVCommon.dart';
import 'bloc/forgot_bloc.dart';

class ForgotPassword extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  ForgotBloc forgotBloc=ForgotBloc();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(context),
        body: BlocListener<ForgotBloc, ForgotState>(
          bloc: forgotBloc,
            listener: (context, state) {
              if (state is ForgotSuccess) {
               var data=jsonDecode(state.response);
               print(data);
               if(data['success']) {
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
               }else{
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text(data['message']),
                     backgroundColor: Colors.red,
                   ),
                 );

               }
               } else if (state is ForgotFailure) {
                // Show an error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: SizedBox(
                width: SizeUtils.width,
                child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Form(
                        key: _formKey,
                        child: Container(
                            width: double.maxFinite,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24.h, vertical: 39.v),
                            child: Column(children: [
                              CustomTextFormField(
                                  controller: emailController,
                                  hintText: translation(context)
                                      .msg_enter_your_email,
                                  textInputType: TextInputType.emailAddress,
                                  prefix: Container(
                                      margin: EdgeInsets.fromLTRB(
                                          24.h, 16.v, 16.h, 16.v),
                                      child: CustomImageView(
                                          color: Colors.blueGrey,
                                          imagePath:
                                              ImageConstant.imgCheckmark,
                                          height: 24.adaptSize,
                                          width: 24.adaptSize)),
                                  prefixConstraints:
                                      BoxConstraints(maxHeight: 56.v),
                                  validator: (value) {
                                    if (value == null ||
                                        (!isValidEmail(value,
                                            isRequired: true))) {
                                      return translation(context)
                                          .err_msg_please_enter_valid_email;
                                    }
                                    return null;
                                  },
                                  contentPadding: EdgeInsets.only(
                                      top: 18.v,
                                      right: 30.h,
                                      bottom: 18.v)),
                              SizedBox(height: 32.v),
                              svAppButton(
                                context: context,
                                text: 'SEND',
                                onTap: () {
                                  forgotBloc.add(
                                    ForgotPasswordEvent(
                                      username: emailController.text,
                                      // replace with real input
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 25.v),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                      padding: EdgeInsets.only(left: 48.h),
                                      child: Row(children: [
                                        Padding(
                                            padding: EdgeInsets.only(
                                                bottom: 1.v),
                                            child: Text(
                                                translation(context)
                                                    .msg_don_t_have_an_account,
                                                style: CustomTextStyles
                                                    .bodyMediumGray600)),
                                        GestureDetector(
                                            onTap: () {
                                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>SignUpScreen()), (route) => false);

                                            },
                                            child: Padding(
                                                padding: EdgeInsets.only(
                                                    left: 4.h),
                                                child: Text(
                                                    translation(context)
                                                        .lbl_sign_up,
                                                    style: CustomTextStyles
                                                        .titleSmallPrimarySemiBold)))
                                      ]))),
                              SizedBox(height: 5.v)
                            ])))))));
  }

  /// Section Widget
  _buildAppBar(BuildContext context) {
    return CustomAppBar(
      height: 140,
      leadingWidth: 56.h,
      centerTitle: true,

      title: Column(
         mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/logo/logo.png',
            width: 400.v,
            height: 100.h,
          ),

          AppbarTitle(text: 'Forgot Password'),
        ],
      ),
    );
  }

}
