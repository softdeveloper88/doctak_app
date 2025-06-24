import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/common_navigator.dart';
import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/terms_and_condition_screen/terms_and_condition_screen.dart';
import 'package:doctak_app/widgets/app_bar/custom_app_bar.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';

import '../../core/utils/app_comman_data.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../home_screen/fragments/profile_screen/bloc/profile_event.dart';
import '../home_screen/fragments/profile_screen/bloc/profile_state.dart';
import '../home_screen/utils/SVCommon.dart';
import 'bloc/sign_up_bloc.dart';
import 'component/error_dialog.dart';
// ignore_for_file: must_be_immutable
class SignUpScreen extends StatefulWidget {
  SignUpScreen({this.isSocialLogin = false, this.firstName, this.lastName, this.email, this.token, Key? key}) : super(key: key);
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
  final TextEditingController confirmPasswordController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();
  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  FocusNode focusNode4 = FocusNode();
  FocusNode focusNode5 = FocusNode();
  FocusNode focusNode6 = FocusNode();
  
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: svGetScaffoldColor(),
        resizeToAvoidBottomInset: true,
        body: Container(
          width: 100.w,
          height: 100.h,
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
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(children: [
                     Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02),
                        // App Logo with enhanced styling
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Hero(
                              tag: 'app_logo',
                              child: Image.asset(
                                'assets/logo/logo.png',
                                width: MediaQuery.of(context).size.width * 0.18,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                            // Welcome Section with better typography
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    "Create Account",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Join our community and start your journey",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                        Container(
                          width: double.maxFinite,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BlocBuilder<DropdownBloc, DropdownState>(
                                    bloc: dropdownBloc,
                                    builder: (context, state) {
                                      if (state is DataLoaded) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Container(width: 500,
                                            //   decoration: BoxDecoration(
                                            //       border: Border.all(
                                            //           color: Colors.blue,
                                            //           width: 2),
                                            //       color: Colors.white,
                                            //       borderRadius: const BorderRadius
                                            //           .all(Radius.circular(8))),
                                            //   child: Row(children: [
                                            //     Expanded(
                                            //       child: InkWell(onTap: () {
                                            //         state.isDoctorRole = true;
                                            //         dropdownBloc.isDoctorRole =
                                            //         true;
                                            //         dropdownBloc.add(
                                            //             ChangeDoctorRole());
                                            //         setState(() {
                                            //
                                            //         });
                                            //       },
                                            //         child: Container(
                                            //           padding: const EdgeInsets
                                            //               .all(10),
                                            //           // width: 210,
                                            //           height: 50,
                                            //           decoration: BoxDecoration(
                                            //               color: !state
                                            //                   .isDoctorRole
                                            //                   ? Colors.white
                                            //                   : Colors.blue,
                                            //               borderRadius: const BorderRadius
                                            //                   .all(
                                            //                   Radius.circular(
                                            //                       6))),
                                            //           child: Center(child: Text(
                                            //             "Doctor",
                                            //             style: TextStyle(
                                            //                 fontFamily: 'Poppins',
                                            //                 color: state
                                            //                     .isDoctorRole
                                            //                     ? Colors.white
                                            //                     : Colors.blue,
                                            //                 fontWeight: FontWeight
                                            //                     .bold,
                                            //                 fontSize: 14),
                                            //             // style: CustomTextStyles
                                            //             //     .titleMediumOnPrimaryContainer,
                                            //           )),),),),
                                            //     Expanded(
                                            //       child: InkWell(onTap: () {
                                            //         state.isDoctorRole = false;
                                            //         dropdownBloc.add(
                                            //             ChangeDoctorRole());
                                            //         dropdownBloc.isDoctorRole =
                                            //         false;
                                            //         setState(() {
                                            //
                                            //         });
                                            //       },
                                            //         child: Container(
                                            //           padding: const EdgeInsets
                                            //               .all(10),
                                            //           // width: 200,
                                            //           height: 50,
                                            //           decoration: BoxDecoration(
                                            //               color: state
                                            //                   .isDoctorRole
                                            //                   ? Colors.white
                                            //                   : Colors.blue,
                                            //               borderRadius: const BorderRadius
                                            //                   .all(
                                            //                   Radius.circular(
                                            //                       6))),
                                            //           child: Center(child: Text(
                                            //             "Medical student",
                                            //             style: TextStyle(
                                            //                 fontFamily: 'Poppins',
                                            //                 color: !state
                                            //                     .isDoctorRole
                                            //                     ? Colors.white
                                            //                     : Colors.blue,
                                            //                 fontWeight: FontWeight
                                            //                     .bold,
                                            //                 fontSize: 14),
                                            //             // style: CustomTextStyles
                                            //             //     .titleMediumOnPrimaryContainer,
                                            //           )),),),),
                                            //   ],),),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        translation(context).lbl_enter_first_name,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.grey.shade800,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildName(context),
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
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.grey.shade800,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildName1(context),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            if (widget.isSocialLogin == false) 
                                              Text(translation(context).lbl_enter_email,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            if (widget.isSocialLogin == false) 
                                              const SizedBox(height: 8),
                                            _buildEmail(context),
                                            if (widget.isSocialLogin == false)
                                              const SizedBox(height: 16),
                                            if (widget.isSocialLogin == false)
                                              LayoutBuilder(
                                                builder: (context, constraints) {
                                                  if (constraints.maxWidth > 400) {
                                                    return Row(
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                translation(context).lbl_create_password,
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.grey.shade800,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 8),
                                                              CustomTextFormField(
                                                                fillColor: Colors.grey.shade50,
                                                                filled: true,
                                                                autofocus: false,
                                                                focusNode: focusNode4,
                                                                controller: passwordController,
                                                                hintText: translation(context).lbl_create_password,
                                                                textInputAction: TextInputAction.next,
                                                                textInputType: TextInputType.visiblePassword,
                                                                prefix: Container(
                                                                  margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                                                                  child: Icon(
                                                                    Icons.lock_outline,
                                                                    color: theme.colorScheme.primary,
                                                                    size: 20,
                                                                  )
                                                                ),
                                                                prefixConstraints: const BoxConstraints(maxHeight: 56),
                                                                suffix: InkWell(
                                                                  onTap: () {
                                                                    dropdownBloc.add(TogglePasswordVisibility());
                                                                  },
                                                                  child: Container(
                                                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                                                    child: Icon(
                                                                      state.isPasswordVisible
                                                                          ? Icons.visibility_off
                                                                          : Icons.visibility,
                                                                      color: theme.colorScheme.primary.withOpacity(0.7),
                                                                      size: 20,
                                                                    )
                                                                  ),
                                                                ),
                                                                suffixConstraints: const BoxConstraints(maxHeight: 56),
                                                                validator: (value) {
                                                                  if (value == null ||
                                                                      (!isValidPassword(value, isRequired: true))) {
                                                                    return translation(context)
                                                                        .err_msg_please_enter_valid_password;
                                                                  }
                                                                  return null;
                                                                },
                                                                borderDecoration: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                                                ),
                                                                obscureText: state.isPasswordVisible
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
                                                                'Confirm Password:',
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.grey.shade800,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 8),
                                                              CustomTextFormField(
                                                                fillColor: Colors.grey.shade50,
                                                                filled: true,
                                                                autofocus: false,
                                                                focusNode: focusNode5,
                                                                controller: confirmPasswordController,
                                                                hintText: translation(context).msg_confirm_password,
                                                                textInputAction: TextInputAction.done,
                                                                textInputType: TextInputType.visiblePassword,
                                                                prefix: Container(
                                                                  margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                                                                  child: Icon(
                                                                    Icons.lock_outline,
                                                                    color: theme.colorScheme.primary,
                                                                    size: 20,
                                                                  )
                                                                ),
                                                                prefixConstraints: const BoxConstraints(maxHeight: 56),
                                                                suffix: InkWell(
                                                                  onTap: () {
                                                                    dropdownBloc.add(TogglePasswordVisibility());
                                                                  },
                                                                  child: Container(
                                                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                                                    child: Icon(
                                                                      state.isPasswordVisible
                                                                          ? Icons.visibility_off
                                                                          : Icons.visibility,
                                                                      color: theme.colorScheme.primary.withOpacity(0.7),
                                                                      size: 20,
                                                                    )
                                                                  ),
                                                                ),
                                                                suffixConstraints: const BoxConstraints(maxHeight: 56),
                                                                validator: (value) {
                                                                  if (value == null ||
                                                                      (!isValidPassword(value, isRequired: true))) {
                                                                    return translation(context)
                                                                        .err_msg_please_enter_valid_password;
                                                                  }
                                                                  if (value != passwordController.text) {
                                                                    return "Passwords do not match";
                                                                  }
                                                                  return null;
                                                                },
                                                                borderDecoration: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                                                ),
                                                                obscureText: state.isPasswordVisible
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  } else {
                                                    return Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          translation(context).lbl_create_password,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.grey.shade800,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        CustomTextFormField(
                                                          fillColor: Colors.grey.shade50,
                                                          filled: true,
                                                          autofocus: false,
                                                          focusNode: focusNode4,
                                                          controller: passwordController,
                                                          hintText: translation(context).lbl_create_password,
                                                          textInputAction: TextInputAction.next,
                                                          textInputType: TextInputType.visiblePassword,
                                                          prefix: Container(
                                                            margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                                                            child: Icon(
                                                              Icons.lock_outline,
                                                              color: theme.colorScheme.primary,
                                                              size: 20,
                                                            )
                                                          ),
                                                          prefixConstraints: const BoxConstraints(maxHeight: 56),
                                                          suffix: InkWell(
                                                            onTap: () {
                                                              dropdownBloc.add(TogglePasswordVisibility());
                                                            },
                                                            child: Container(
                                                              margin: const EdgeInsets.symmetric(horizontal: 16),
                                                              child: Icon(
                                                                state.isPasswordVisible
                                                                    ? Icons.visibility_off
                                                                    : Icons.visibility,
                                                                color: theme.colorScheme.primary.withOpacity(0.7),
                                                                size: 20,
                                                              )
                                                            ),
                                                          ),
                                                          suffixConstraints: const BoxConstraints(maxHeight: 56),
                                                          validator: (value) {
                                                            if (value == null ||
                                                                (!isValidPassword(value, isRequired: true))) {
                                                              return translation(context)
                                                                  .err_msg_please_enter_valid_password;
                                                            }
                                                            return null;
                                                          },
                                                          borderDecoration: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            borderSide: BorderSide(color: Colors.grey.shade200),
                                                          ),
                                                          obscureText: state.isPasswordVisible
                                                        ),
                                                        const SizedBox(height: 16),
                                                        Text(
                                                          'Confirm Password:',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.grey.shade800,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        CustomTextFormField(
                                                          fillColor: Colors.grey.shade50,
                                                          filled: true,
                                                          autofocus: false,
                                                          focusNode: focusNode5,
                                                          controller: confirmPasswordController,
                                                          hintText: translation(context).msg_confirm_password,
                                                          textInputAction: TextInputAction.done,
                                                          textInputType: TextInputType.visiblePassword,
                                                          prefix: Container(
                                                            margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                                                            child: Icon(
                                                              Icons.lock_outline,
                                                              color: theme.colorScheme.primary,
                                                              size: 20,
                                                            )
                                                          ),
                                                          prefixConstraints: const BoxConstraints(maxHeight: 56),
                                                          suffix: InkWell(
                                                            onTap: () {
                                                              dropdownBloc.add(TogglePasswordVisibility());
                                                            },
                                                            child: Container(
                                                              margin: const EdgeInsets.symmetric(horizontal: 16),
                                                              child: Icon(
                                                                state.isPasswordVisible
                                                                    ? Icons.visibility_off
                                                                    : Icons.visibility,
                                                                color: theme.colorScheme.primary.withOpacity(0.7),
                                                                size: 20,
                                                              )
                                                            ),
                                                          ),
                                                          suffixConstraints: const BoxConstraints(maxHeight: 56),
                                                          validator: (value) {
                                                            if (value == null ||
                                                                (!isValidPassword(value, isRequired: true))) {
                                                              return translation(context)
                                                                  .err_msg_please_enter_valid_password;
                                                            }
                                                            if (value != passwordController.text) {
                                                              return "Passwords do not match";
                                                            }
                                                            return null;
                                                          },
                                                          borderDecoration: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            borderSide: BorderSide(color: Colors.grey.shade200),
                                                          ),
                                                          obscureText: state.isPasswordVisible
                                                        ),
                                                      ],
                                                    );
                                                  }
                                                },
                                              ),
                                            // if(widget.isSocialLogin == true)_buildPhone(
                                            //     context),
                                            // if(widget.isSocialLogin == false) const SizedBox(
                                            //     height: 28),
                                          ],);
                                      } else {
                                        return Container();
                                      }
                                    }),
                                const SizedBox(height: 16),
                                Row(
                                  children: <Widget>[
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _isChecked,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        activeColor: theme.colorScheme.primary,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _isChecked = value!;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          children: <TextSpan>[
                                            TextSpan(text: translation(context).msg_agree_terms + ' '),
                                            TextSpan(
                                              text: translation(context).lbl_privacy_policy,
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () {
                                                  launchScreen(
                                                    context,
                                                    TermsAndConditionScreen(),
                                                    isNewTask: false,
                                                    pageRouteAnimation: PageRouteAnimation.Slide,
                                                    duration: const Duration(microseconds: 500),
                                                  );
                                                },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                BlocListener<DropdownBloc, DropdownState>(
                                    listener: (context, state) {
                                      if (state is DataLoaded) {
                                        if (state.isSubmit) {
                                          // Received response
                                          if (state.response['success']) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(translation(context).msg_login_success),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            launchScreen(
                                              context,
                                              const SVDashboardScreen(),
                                              isNewTask: true,
                                              pageRouteAnimation: PageRouteAnimation.Slide,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  state.response['message'] ??
                                                  translation(context).msg_something_wrong
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            // Error in response
                                            _showErrorDialog(state.response['errors']);
                                          }
                                        }
                                      } else if (state is SocialLoginSuccess) {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const SVDashboardScreen()
                                          ), 
                                          (route) => false
                                        );
                                      } else if (state is DataError) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(translation(context).msg_something_wrong),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(translation(context).msg_something_wrong),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    bloc: dropdownBloc,
                                    child: _buildSignUp(context)),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      translation(context).msg_already_have_account,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        onTapTxtLogIn(context);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          translation(context).lbl_log_in2,
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
                                const SizedBox(height: 16),
                              ]),
                          ),
                    ),
                    ]),
              ),
            ),
          ),
    ));
  }

  void _showErrorDialog(Map<String, dynamic> errors) {
    showDialog(context: context, builder: (BuildContext context) {
      return ErrorDialog(errors: errors);
    },);
  }

  /// Section Widget
  _buildAppBar(BuildContext context) {
    return CustomAppBar(height: 150,
      leadingWidth: 56,
      centerTitle: true,
      title: Column(children: [
        Image.asset('assets/logo/logo.png', width: 400, height: 100,),
        AppbarTitle(text: widget.isSocialLogin ?? false
            ? "Complete Profile"
            : translation(context).lbl_sign_up),
      ],),);
  }

  /// Section Widget
  Widget _buildName(BuildContext context) {
    return CustomTextFormField(
      fillColor: Colors.grey.shade50,
      filled: true,
      autofocus: false,
      focusNode: focusNode1,
      controller: firstnameController,
      hintText: translation(context).lbl_enter_your_name1,
      textInputAction: TextInputAction.next,
      prefix: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Icon(
          Icons.person_outline,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      prefixConstraints: const BoxConstraints(maxHeight: 56),
      validator: (value) {
        if (!isText(value)) {
          return translation(context).err_msg_please_enter_valid_text;
        }
        return null;
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      borderDecoration: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  /// Section Widget
  Widget _buildName1(BuildContext context) {
    return CustomTextFormField(
      fillColor: Colors.grey.shade50,
      filled: true,
      autofocus: false,
      focusNode: focusNode2,
      controller: lastNameController,
      hintText: translation(context).lbl_enter_your_name2,
      textInputAction: TextInputAction.next,
      prefix: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Icon(
          Icons.person_outline,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      prefixConstraints: const BoxConstraints(maxHeight: 56),
      validator: (value) {
        if (!isText(value)) {
          return translation(context).err_msg_please_enter_valid_text;
        }
        return null;
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      borderDecoration: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  /// Section Widget
  Widget _buildPhone(BuildContext context) {
    return CustomTextFormField(
        fillColor: CupertinoColors.systemGrey5.withOpacity(0.4),
        filled: true,
        autofocus: false,
        focusNode: focusNode6,
        textInputType: TextInputType.phone,
        controller: phoneController,
        hintText: translation(context).lbl_enter_your_phone,
        prefix: const SizedBox(width: 10,),
        // prefix: Container(
        //     margin: const EdgeInsets.fromLTRB(24, 16, 16, 16),
        //     child: CustomImageView(
        //         color: Colors.black54,
        //         imagePath: imgLock,
        //         height: 24,
        //         width: 24)),
        prefixConstraints: const BoxConstraints(maxHeight: 56),
        // validator: (value) {
        //   if (!isText(value)) {
        //     return translation(context).err_msg_please_enter_valid_text;
        //   }
        //   return null;
        // },
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16));
  }

  /// Section Widget
  Widget _buildEmail(BuildContext context) {
    return CustomTextFormField(
      fillColor: Colors.grey.shade50,
      filled: true,
      autofocus: false,
      focusNode: focusNode3,
      controller: emailController,
      hintText: translation(context).msg_enter_your_email2,
      textInputType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
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
        if (value == null || (!isValidEmail(value, isRequired: true))) {
          return translation(context).err_msg_please_enter_valid_email;
        }
        return null;
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      borderDecoration: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  /// Section Widget
  Widget _buildSignUp(BuildContext context) {
    return Container(
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
          onTapSignUp(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Sign Up',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Displays a dialog with the [SignUpSuccessDialog] content.
  onTapSignUp(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translation(context).err_msg_please_enter_valid_text),));
      return;
    }

    await FirebaseMessaging.instance.getToken().then((token) async {
      // if (widget.isSocialLogin == false) {
      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(translation(context).err_msg_please_enter_valid_password),));
      } else {
        if (_isChecked) {
          dropdownBloc.add(SignUpButtonPressed(
              username: emailController.text.toString(),
              password: passwordController.text.toString(),
              firstName: firstnameController!.text.toString(),
              lastName: lastNameController!.text.toString(),
              country: profileBloc.country ?? 'United Arab Emirates',
              state: profileBloc.stateName ?? "DUBAI",
              specialty: profileBloc.specialtyName ?? "",
              userType: dropdownBloc.isDoctorRole ? 'doctor' : 'student',
              deviceToken: token ?? ''
            // replace with real input
          ));
        } else {
          toast(translation(context).msg_agree_terms);
        }
      }
    }).catchError((e){
      toast(translation(context).msg_something_wrong);
    });
  }

  /// Navigates to the loginScreen when the action is triggered.
  onTapTxtLogIn(BuildContext context) {
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()), (
        route) => false);
  }
}