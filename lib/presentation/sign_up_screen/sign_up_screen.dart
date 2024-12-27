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
    print(widget.isSocialLogin);
    dropdownBloc.add(LoadDropdownValues());
    profileBloc.add(UpdateFirstDropdownValue(''));
    firstnameController = TextEditingController(text: widget.firstName);
    lastNameController = TextEditingController(text: widget.lastName);

    emailController = TextEditingController(text: widget.email);
    print('object');
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
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: svGetScaffoldColor(),
        resizeToAvoidBottomInset: false,
        body: SizedBox(width: 100.w,
            child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom),
                child: Form(key: _formKey,
                    child: Column(children: [
                      Padding(padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            Image.asset(
                              'assets/logo/logo.png',
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: 100,
                            ),
                            const Text('Sign Up', style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w500,),),
                            const SizedBox(height: 8),
                            const Text('Please Register your account to continue',
                              overflow: TextOverflow.visible,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),),
                          ],),),
                        Container(width: double.maxFinite,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 0),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                BlocBuilder<DropdownBloc, DropdownState>(
                                    bloc: dropdownBloc,
                                    builder: (context, state) {
                                      if (state is DataLoaded) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
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
                                            const SizedBox(height: 10),
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                'Enter Your First Name:',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight
                                                      .w500,),),),
                                            _buildName(context),
                                            const SizedBox(height: 16),
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                'Enter Your Last Name:',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight
                                                      .w500,),),),
                                            _buildName1(context),
                                            const SizedBox(height: 16),
                                            if (widget.isSocialLogin ==
                                                false)const Padding(
                                              padding: EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text('Enter Your Email:',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight
                                                      .w500,),),),
                                            _buildEmail(context),
                                            if (widget.isSocialLogin ==
                                                false)const SizedBox(
                                                height: 16),
                                            if (widget.isSocialLogin ==
                                                false)const Padding(
                                              padding: EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text('Create Password:',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight
                                                      .w500,),),),
                                            CustomTextFormField(
                                                fillColor: CupertinoColors
                                                    .systemGrey5.withOpacity(
                                                    0.4),
                                                filled: true,

                                                focusNode: focusNode4,
                                                controller: passwordController,
                                                hintText: translation(context)
                                                    .lbl_create_password,
                                                textInputAction: TextInputAction
                                                    .done,
                                                textInputType: TextInputType
                                                    .visiblePassword,
                                                prefix: Container(
                                                    margin: const EdgeInsets
                                                        .fromLTRB(
                                                        24, 16, 16, 16),
                                                    child: CustomImageView(
                                                        color: Colors.black54,
                                                        imagePath: imgLocation,
                                                        height: 24,
                                                        width: 24)),
                                                prefixConstraints: const BoxConstraints(
                                                    maxHeight: 56),
                                                suffix: InkWell(onTap: () {
                                                  dropdownBloc.add(
                                                      TogglePasswordVisibility());
                                                },
                                                    child: Container(
                                                        margin: const EdgeInsets
                                                            .fromLTRB(
                                                            30, 16, 24, 16),
                                                        child: state
                                                            .isPasswordVisible
                                                            ? const Icon(
                                                          Icons.visibility_off,
                                                          color: Colors.black54,
                                                          size: 24,)
                                                            : const Icon(
                                                          Icons.visibility,
                                                          color: Colors.black54,
                                                          size: 24,))),
                                                suffixConstraints: const BoxConstraints(
                                                    maxHeight: 56),
                                                validator: (value) {
                                                  if (value == null ||
                                                      (!isValidPassword(value,
                                                          isRequired: true))) {
                                                    return translation(context)
                                                        .err_msg_please_enter_valid_password;
                                                  }
                                                  return null;
                                                },
                                                obscureText: state
                                                    .isPasswordVisible),
                                            if (widget.isSocialLogin ==
                                                false)const SizedBox(
                                                height: 16),
                                            if (widget.isSocialLogin ==
                                                false)const Padding(
                                              padding: EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text('Confirm Password:',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight
                                                      .w500,),),),
                                            CustomTextFormField(
                                                fillColor: CupertinoColors
                                                    .systemGrey5.withOpacity(
                                                    0.4),
                                                filled: true,
                                                focusNode: focusNode5,
                                                controller: confirmPasswordController,
                                                hintText: translation(context)
                                                    .msg_confirm_password,
                                                textInputAction: TextInputAction
                                                    .done,
                                                textInputType: TextInputType
                                                    .text,
                                                prefix: Container(
                                                    margin: const EdgeInsets
                                                        .fromLTRB(
                                                        24, 16, 16, 16),
                                                    child: CustomImageView(
                                                        color: Colors.black54,
                                                        imagePath: imgLocation,
                                                        height: 24,
                                                        width: 24)),
                                                prefixConstraints: const BoxConstraints(
                                                    maxHeight: 56),
                                                suffix: InkWell(onTap: () {
                                                  dropdownBloc.add(
                                                      TogglePasswordVisibility());
                                                },
                                                    child: Container(
                                                        margin: const EdgeInsets
                                                            .fromLTRB(
                                                            30, 16, 24, 16),
                                                        child: state
                                                            .isPasswordVisible
                                                            ? const Icon(
                                                          Icons.visibility_off,
                                                          color: Colors.black54,
                                                          size: 24,)
                                                            : const Icon(
                                                          Icons.visibility,
                                                          color: Colors.black54,
                                                          size: 24,))),
                                                // child: CustomImageView(color: Colors.black54, imagePath: imgEye, height: 24, width: 24))),
                                                suffixConstraints: const BoxConstraints(
                                                    maxHeight: 56),
                                                validator: (value) {
                                                  if (value == null ||
                                                      (!isValidPassword(value,
                                                          isRequired: true))) {
                                                    return translation(context)
                                                        .err_msg_please_enter_valid_password;
                                                  }
                                                  return null;
                                                },
                                                obscureText: state
                                                    .isPasswordVisible),
                                            // if(widget.isSocialLogin == true)_buildPhone(
                                            //     context),
                                            // if(widget.isSocialLogin == false) const SizedBox(
                                            //     height: 28),
                                          ],);
                                      } else {
                                        return Container();
                                      }
                                    }),
                                Row(children: <Widget>[
                                  Checkbox(value: _isChecked, onChanged: (
                                      bool? value) {
                                    setState(() {
                                      _isChecked = value!;
                                    });
                                  },),
                                  Expanded(child: RichText(text: TextSpan(
                                    style: const TextStyle(fontSize: 14.0,
                                      color: Colors.black,
                                      fontFamily: 'Poppins',),
                                    children: <TextSpan>[
                                      const TextSpan(text: 'I agree to the '),
                                      TextSpan(text: 'Terms and Conditions',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontFamily: 'Poppins',),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            // Handle the click event for Terms and Conditions
                                            launchScreen(context,
                                                TermsAndConditionScreen(),
                                                isNewTask: false,
                                                pageRouteAnimation: PageRouteAnimation
                                                    .Slide,
                                                duration: const Duration(
                                                    microseconds: 500));

                                            // You can navigate to the Terms and Conditions page here
                                          },),
                                    ],),),),
                                ],),
                                const SizedBox(height: 8,),
                                BlocListener<DropdownBloc, DropdownState>(
                                    listener: (context, state) {
                                      if (state is DataLoaded) {
                                        if (state.isSubmit) {
                                          print(state.response);
                                          if (state.response['success']) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                content: Text('Account create successfully')),);
                                            launchScreen(context,
                                                const SVDashboardScreen(),
                                                isNewTask: true,
                                                pageRouteAnimation: PageRouteAnimation
                                                    .Slide);
                                            // Navigator.pushAndRemoveUntil(
                                            //     context,
                                            //     MaterialPageRoute(
                                            //         builder: (context) => WelcomeScreen(emailController.text)),
                                            //         (route) => false);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                content: Text(state.response['message'] ??
                                                    "Something went wrong.Please make sure no field left empty")),);
                                            print("errors ${state.response}");
                                            _showErrorDialog(
                                                state.response['errors']);
                                          }
                                        }
                                      } else if (state is SocialLoginSuccess) {
                                        Navigator.pushAndRemoveUntil(context,
                                            MaterialPageRoute(builder: (
                                                context) => const SVDashboardScreen()), (
                                                route) => false);
                                      } else if (state is DataError) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Something went wrong')),);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Something went wrong')),);
                                      }
                                    },
                                    bloc: dropdownBloc,
                                    child: _buildSignUp(context)),
                                const SizedBox(height: 26),
                                Align(alignment: Alignment.centerLeft,
                                    child: Padding(padding: const EdgeInsets
                                        .only(left: 44), child: Row(children: [
                                      Text("Already have an account",
                                          style: CustomTextStyles
                                              .bodyMediumGray600),
                                      GestureDetector(onTap: () {
                                        onTapTxtLogIn(context);
                                      },
                                          child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4),
                                              child: Text(translation(context)
                                                  .lbl_log_in2,
                                                  style: CustomTextStyles
                                                      .titleSmallPrimarySemiBold)))
                                    ]))),
                                const SizedBox(height: 5),
                              ])),
                    ],)))));
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
        fillColor: CupertinoColors.systemGrey5.withOpacity(0.4),
        filled: true,
        focusNode: focusNode1,
        controller: firstnameController,
        hintText: translation(context).lbl_enter_your_name1,
        prefix: Container(margin: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            child: CustomImageView(color: Colors.black54,
                imagePath: imgPerson,
                height: 24,
                width: 24)),
        prefixConstraints: const BoxConstraints(maxHeight: 56),
        validator: (value) {
          if (!isText(value)) {
            return translation(context).err_msg_please_enter_valid_text;
          }
          return null;
        },
        contentPadding: const EdgeInsets.only(top: 18, right: 30, bottom: 18));
  }

  /// Section Widget
  Widget _buildName1(BuildContext context) {
    return CustomTextFormField(
        fillColor: CupertinoColors.systemGrey5.withOpacity(0.4),
        filled: true,
        focusNode: focusNode2,
        controller: lastNameController,
        hintText: translation(context).lbl_enter_your_name2,
        prefix: Container(margin: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            child: CustomImageView(color: Colors.black54,
                imagePath: imgPerson,
                height: 24,
                width: 24)),
        prefixConstraints: const BoxConstraints(maxHeight: 56),
        validator: (value) {
          if (!isText(value)) {
            return translation(context).err_msg_please_enter_valid_text;
          }
          return null;
        },
        contentPadding: const EdgeInsets.only(top: 18, right: 30, bottom: 18));
  }

  /// Section Widget
  Widget _buildPhone(BuildContext context) {
    return CustomTextFormField(
        fillColor: CupertinoColors.systemGrey5.withOpacity(0.4),
        filled: true,
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
        contentPadding: const EdgeInsets.only(top: 18, right: 30, bottom: 18));
  }

  /// Section Widget
  Widget _buildEmail(BuildContext context) {
    return CustomTextFormField(
        fillColor: CupertinoColors.systemGrey5.withOpacity(0.4),
        filled: true,
        focusNode: focusNode3,
        controller: emailController,
        hintText: translation(context).msg_enter_your_email2,
        textInputType: TextInputType.emailAddress,
        prefix: Container(margin: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            child: CustomImageView(color: Colors.black54,
                imagePath: imgCheckmark,
                height: 30,
                width: 30)),
        prefixConstraints: const BoxConstraints(maxHeight: 56),
        validator: (value) {
          if (value == null || (!isValidEmail(value, isRequired: true))) {
            return translation(context).err_msg_please_enter_valid_email;
          }
          return null;
        },
        contentPadding: const EdgeInsets.only(top: 18, right: 30, bottom: 18));
  }

  /// Section Widget
  Widget _buildSignUp(BuildContext context) {
    return svAppButton(context: context, text: 'Sign Up', onTap: () async {
      onTapSignUp(context);
    },);
  }

  /// Displays a dialog with the [SignUpSuccessDialog] content.
  onTapSignUp(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field must be filled'),));
      return;
    }

    await FirebaseMessaging.instance.getToken().then((token) async {
      // if (widget.isSocialLogin == false) {
      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password should be match'),));
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
          toast("Please accept terms and conditions before proceeds");
        }
      }
    }).catchError((e){
      toast("Something went wrong please try again");
    });
  }

  /// Navigates to the loginScreen when the action is triggered.
  onTapTxtLogIn(BuildContext context) {
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()), (
        route) => false);
  }
}

