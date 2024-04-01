import 'dart:convert';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/validation_functions.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/sign_up_success_dialog/sign_up_success_dialog.dart';
import 'package:doctak_app/widgets/app_bar/appbar_leading_image.dart';
import 'package:doctak_app/widgets/app_bar/appbar_subtitle_two.dart';
import 'package:doctak_app/widgets/app_bar/custom_app_bar.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home_screen/utils/SVCommon.dart';
import 'bloc/sign_up_bloc.dart';

// ignore_for_file: must_be_immutable
class SignUpScreen extends StatefulWidget {
  SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DropdownBloc dropdownBloc = DropdownBloc();

  @override
  void initState() {
    dropdownBloc.add(LoadDropdownValues());
    print('object');
    super.initState();
  }

  // static Widget builder(BuildContext context) {
  String? selectedNewUniversity = '';

  final TextEditingController firstnameController = TextEditingController();

  final TextEditingController lastNameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  final TextEditingController phoneController = TextEditingController();
  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  FocusNode focusNode4 = FocusNode();
  FocusNode focusNode5 = FocusNode();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: _buildAppBar(context),
            body: SizedBox(
                width: SizeUtils.width,
                child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery
                            .of(context)
                            .viewInsets
                            .bottom),
                    child: Form(
                        key: _formKey,
                        child: Container(
                            width: double.maxFinite,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24.h, vertical: 39.v),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 16.v),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      BlocBuilder<DropdownBloc, DropdownState>(
                                          bloc: dropdownBloc,
                                          builder: (context, state) {
                                            if (state is DataLoaded) {
                                              return Container(
                                                width: 500.v,
                                                // height: 15.w,
                                                decoration: BoxDecoration(
                                                    color: Colors.blueGrey[300],
                                                    borderRadius:
                                                    const BorderRadius.all(
                                                        Radius.circular(
                                                            15))),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: InkWell(
                                                        onTap: () {
                                                          state.isDoctorRole =
                                                          true;
                                                          dropdownBloc
                                                              .isDoctorRole =
                                                          true;
                                                          dropdownBloc.add(
                                                              ChangeDoctorRole());
                                                        },
                                                        child: Container(
                                                          padding:
                                                          const EdgeInsets
                                                              .all(10),
                                                          // width: 210.v,
                                                          height: 50.v,
                                                          decoration: BoxDecoration(
                                                              color: !state
                                                                  .isDoctorRole
                                                                  ? Colors
                                                                  .blueGrey[
                                                              300]
                                                                  : Colors.blue,
                                                              borderRadius:
                                                              const BorderRadius
                                                                  .all(
                                                                  Radius
                                                                      .circular(
                                                                      15))),
                                                          child: Center(
                                                              child: Text(
                                                                "Doctor",
                                                                style: GoogleFonts
                                                                    .poppins(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                    12),
                                                                // style: CustomTextStyles
                                                                //     .titleMediumOnPrimaryContainer,
                                                              )),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: InkWell(
                                                        onTap: () {
                                                          state.isDoctorRole =
                                                          false;
                                                          dropdownBloc.add(
                                                              ChangeDoctorRole());
                                                          dropdownBloc
                                                              .isDoctorRole =
                                                          false;
                                                        },
                                                        child: Container(
                                                          padding:
                                                          const EdgeInsets
                                                              .all(10),
                                                          // width: 200.v,
                                                          height: 50.v,
                                                          decoration: BoxDecoration(
                                                              color: state
                                                                  .isDoctorRole
                                                                  ? Colors
                                                                  .blueGrey[
                                                              300]
                                                                  : Colors.blue,
                                                              borderRadius:
                                                              const BorderRadius
                                                                  .all(
                                                                  Radius
                                                                      .circular(
                                                                      15))),
                                                          child: Center(
                                                              child: Text(
                                                                "Medical student",
                                                                style: GoogleFonts
                                                                    .poppins(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                    12),
                                                                // style: CustomTextStyles
                                                                //     .titleMediumOnPrimaryContainer,
                                                              )),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              return Container();
                                            }
                                          }),
                                      SizedBox(height: 16.v),
                                      _buildName(context),
                                      SizedBox(height: 16.v),
                                      _buildName1(context),
                                      SizedBox(height: 16.v),
                                      _buildEmail(context),
                                      // const SizedBox(height: 10),
                                      // CustomDropdownButtonFormField(
                                      //   items: state.firstDropdownValues,
                                      //   value: state
                                      //       .selectedFirstDropdownValue,
                                      //   width: double.infinity,
                                      //   contentPadding:
                                      //       const EdgeInsets.symmetric(
                                      //     horizontal: 10,
                                      //     vertical: 0,
                                      //   ),
                                      //   onChanged: (String? newValue) {
                                      //     print(newValue);
                                      //     BlocProvider.of<DropdownBloc>(
                                      //             context)
                                      //         .add(
                                      //             UpdateFirstDropdownValue(
                                      //                 newValue!));
                                      //   },
                                      // ),
                                      // const SizedBox(height: 10),
                                      // CustomDropdownButtonFormField(
                                      //   items: state.secondDropdownValues,
                                      //   value: state
                                      //       .selectedSecondDropdownValue,
                                      //   width: double.infinity,
                                      //   contentPadding:
                                      //       const EdgeInsets.symmetric(
                                      //     horizontal: 10,
                                      //     vertical: 0,
                                      //   ),
                                      //   onChanged: (String? newValue) {
                                      //     // print(newValue);
                                      //     // BlocProvider.of<DropdownBloc>(
                                      //     //     context)
                                      //     //     .add(UpdateSecondDropdownValues(
                                      //     //     state
                                      //     //         .selectedFirstDropdownValue));
                                      //     BlocProvider.of<DropdownBloc>(
                                      //             context)
                                      //         .add(
                                      //             UpdateUniversityDropdownValues(
                                      //                 newValue!));
                                      //   },
                                      // ),
                                      // if (state.isDoctorRole)
                                      //   const SizedBox(height: 10),
                                      // if (state.isDoctorRole)
                                      //   CustomDropdownButtonFormField(
                                      //     items: state
                                      //         .specialtyDropdownValue,
                                      //     value: state
                                      //         .selectedSpecialtyDropdownValue,
                                      //     width: double.infinity,
                                      //     contentPadding:
                                      //         const EdgeInsets.symmetric(
                                      //       horizontal: 10,
                                      //       vertical: 0,
                                      //     ),
                                      //     onChanged: (String? newValue) {
                                      //       print(newValue);
                                      //       // BlocProvider.of<DropdownBloc>(
                                      //       //     context)
                                      //       //     .add(UpdateSecondDropdownValues(
                                      //       //     state
                                      //       //         .selectedSpecialtyDropdownValue));
                                      //     },
                                      //   ),
                                      // if (!state.isDoctorRole)
                                      //   const SizedBox(height: 10),
                                      // if (!state.isDoctorRole)
                                      //   CustomDropdownButtonFormField(
                                      //     items: state
                                      //         .universityDropdownValue,
                                      //     value: state.selectedUniversityDropdownValue ==
                                      //             ''
                                      //         ? null
                                      //         : state
                                      //             .selectedUniversityDropdownValue,
                                      //     width: double.infinity,
                                      //     contentPadding:
                                      //         const EdgeInsets.symmetric(
                                      //       horizontal: 10,
                                      //       vertical: 0,
                                      //     ),
                                      //     onChanged: (String? newValue) {
                                      //       print(newValue);
                                      //       // selectedNewUniversity=newValue;
                                      //       BlocProvider.of<DropdownBloc>(
                                      //               context)
                                      //           .add(
                                      //               UpdateUniversityDropdownValues(
                                      //                   newValue!));
                                      //     },
                                      //   ),
                                      // if (!state.isDoctorRole)
                                      //   const SizedBox(height: 10),
                                      // if (!state.isDoctorRole &&
                                      //     state.selectedUniversityDropdownValue ==
                                      //         'Add new University')
                                      //   _buildName(context),
                                      SizedBox(height: 16.v),
                                      CustomTextFormField(
                                          focusNode: focusNode4,
                                          controller: passwordController,
                                          hintText: translation(context)
                                              .lbl_create_password,
                                          textInputAction: TextInputAction.done,
                                          textInputType:
                                          TextInputType.visiblePassword,
                                          prefix: Container(
                                              margin: EdgeInsets.fromLTRB(
                                                  24.h, 16.v, 16.h, 16.v),
                                              child: CustomImageView(
                                                  color: Colors.black54,
                                                  imagePath:
                                                  ImageConstant.imgLocation,
                                                  height: 24.adaptSize,
                                                  width: 24.adaptSize)),
                                          prefixConstraints:
                                          BoxConstraints(maxHeight: 56.v),
                                          suffix: InkWell(
                                              onTap: () {
                                                dropdownBloc.add(
                                                    TogglePasswordVisibility());
                                              },
                                              child: Container(
                                                  margin: EdgeInsets.fromLTRB(
                                                      30.h, 16.v, 24.h, 16.v),
                                                  child: CustomImageView(
                                                      color: Colors.black54,
                                                      imagePath:
                                                      ImageConstant.imgEye,
                                                      height: 24.adaptSize,
                                                      width: 24.adaptSize))),
                                          suffixConstraints:
                                          BoxConstraints(maxHeight: 56.v),
                                          validator: (value) {
                                            if (value == null ||
                                                (!isValidPassword(value,
                                                    isRequired: true))) {
                                              return translation(context)
                                                  .err_msg_please_enter_valid_password;
                                            }
                                            return null;
                                          },
                                          obscureText:
                                          dropdownBloc.isVisiblePassword),
                                      SizedBox(height: 28.v),
                                      CustomTextFormField(
                                          focusNode: focusNode5,
                                          controller: confirmPasswordController,
                                          hintText: translation(context)
                                              .msg_confirm_password,
                                          textInputAction: TextInputAction.done,
                                          textInputType:
                                          TextInputType.visiblePassword,
                                          prefix: Container(
                                              margin: EdgeInsets.fromLTRB(
                                                  24.h, 16.v, 16.h, 16.v),
                                              child: CustomImageView(
                                                  color: Colors.black54,
                                                  imagePath:
                                                  ImageConstant.imgLocation,
                                                  height: 24.adaptSize,
                                                  width: 24.adaptSize)),
                                          prefixConstraints:
                                          BoxConstraints(maxHeight: 56.v),
                                          suffix: InkWell(
                                              onTap: () {
                                                dropdownBloc.add(
                                                    TogglePasswordVisibility());
                                              },
                                              child: Container(
                                                  margin: EdgeInsets.fromLTRB(
                                                      30.h, 16.v, 24.h, 16.v),
                                                  child: CustomImageView(
                                                      color: Colors.black54,
                                                      imagePath:
                                                      ImageConstant.imgEye,
                                                      height: 24.adaptSize,
                                                      width: 24.adaptSize))),
                                          suffixConstraints:
                                          BoxConstraints(maxHeight: 56.v),
                                          validator: (value) {
                                            if (value == null ||
                                                (!isValidPassword(value,
                                                    isRequired: true))) {
                                              return translation(context)
                                                  .err_msg_please_enter_valid_password;
                                            }
                                            return null;
                                          },
                                          obscureText:
                                          dropdownBloc.isVisiblePassword),
                                      SizedBox(height: 28.v),
                                      BlocListener<DropdownBloc, DropdownState>(
                                          listener: (context, state) {
                                            if (state is DropdownLoaded1) {
                                              var jsonString = state.response
                                                  .toString();
                                              jsonString =
                                                  jsonString.replaceAll(
                                                      '{', '{"');
                                              jsonString =
                                                  jsonString.replaceAll(
                                                      ': ', '": "');
                                              jsonString =
                                                  jsonString.replaceAll(
                                                      ', ', '", "');
                                              jsonString =
                                                  jsonString.replaceAll(
                                                      '}', '"}');

                                              var data = jsonDecode(jsonString);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(content: Text(
                                                    data['message'])),);
                                              Navigator.pushAndRemoveUntil(
                                                  context, MaterialPageRoute(
                                                  builder: (context) =>
                                                      LoginScreen()), (
                                                  route) => false);
                                            }
                                          },
                                          bloc: dropdownBloc,
                                          child: _buildSignUp(context)),

                                      SizedBox(height: 26.v),
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                              padding:
                                              EdgeInsets.only(left: 44.h),
                                              child: Row(children: [
                                                Text("Already have an account",
                                                    style: CustomTextStyles
                                                        .bodyMediumGray600),
                                                GestureDetector(
                                                    onTap: () {
                                                      onTapTxtLogIn(context);
                                                    },
                                                    child: Padding(
                                                        padding:
                                                        EdgeInsets.only(
                                                            left: 4.h),
                                                        child: Text(
                                                            translation(context)
                                                                .lbl_log_in2,
                                                            style: CustomTextStyles
                                                                .titleSmallPrimarySemiBold)))
                                              ]))),
                                      SizedBox(height: 5.v)
                                    ],
                                  ),
                                ])))))));
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
        leadingWidth: 56.h,
        leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgIconChevronLeft,
            margin: EdgeInsets.only(left: 32.h, top: 8.v, bottom: 8.v)),
        centerTitle: true,
        title: AppbarSubtitleTwo(text: translation(context).lbl_sign_up));
  }

  /// Section Widget
  Widget _buildName(BuildContext context) {
    return CustomTextFormField(
        focusNode: focusNode1,
        controller: firstnameController,
        hintText: translation(context).lbl_enter_your_name1,
        prefix: Container(
            margin: EdgeInsets.fromLTRB(24.h, 16.v, 16.h, 16.v),
            child: CustomImageView(
                color: Colors.black54,
                imagePath: ImageConstant.imgLock,
                height: 24.adaptSize,
                width: 24.adaptSize)),
        prefixConstraints: BoxConstraints(maxHeight: 56.v),
        validator: (value) {
          if (!isText(value)) {
            return translation(context).err_msg_please_enter_valid_text;
          }
          return null;
        },
        contentPadding: EdgeInsets.only(top: 18.v, right: 30.h, bottom: 18.v));
  }

  /// Section Widget
  Widget _buildName1(BuildContext context) {
    return CustomTextFormField(
        focusNode: focusNode2,
        controller: lastNameController,
        hintText: translation(context).lbl_enter_your_name2,
        prefix: Container(
            margin: EdgeInsets.fromLTRB(24.h, 16.v, 16.h, 16.v),
            child: CustomImageView(
                color: Colors.black54,
                imagePath: ImageConstant.imgLock,
                height: 24.adaptSize,
                width: 24.adaptSize)),
        prefixConstraints: BoxConstraints(maxHeight: 56.v),
        validator: (value) {
          if (!isText(value)) {
            return translation(context).err_msg_please_enter_valid_text;
          }
          return null;
        },
        contentPadding: EdgeInsets.only(top: 18.v, right: 30.h, bottom: 18.v));
  }

  /// Section Widget
  Widget _buildPhone(BuildContext context) {
    return CustomTextFormField(
        textInputType: TextInputType.phone,
        controller: phoneController,
        hintText: translation(context).lbl_enter_your_phone,
        prefix: Container(
            margin: EdgeInsets.fromLTRB(24.h, 16.v, 16.h, 16.v),
            child: CustomImageView(
                color: Colors.black54,
                imagePath: ImageConstant.imgLock,
                height: 24.adaptSize,
                width: 24.adaptSize)),
        prefixConstraints: BoxConstraints(maxHeight: 56.v),
        validator: (value) {
          if (!isText(value)) {
            return translation(context).err_msg_please_enter_valid_text;
          }
          return null;
        },
        contentPadding: EdgeInsets.only(top: 18.v, right: 30.h, bottom: 18.v));
  }

  /// Section Widget
  Widget _buildEmail(BuildContext context) {
    return CustomTextFormField(
        focusNode: focusNode3,
        controller: emailController,
        hintText: translation(context).msg_enter_your_email2,
        textInputType: TextInputType.emailAddress,
        prefix: Container(
            margin: EdgeInsets.fromLTRB(24.h, 16.v, 16.h, 16.v),
            child: CustomImageView(
                color: Colors.black54,
                imagePath: ImageConstant.imgCheckmark,
                height: 24.adaptSize,
                width: 24.adaptSize)),
        prefixConstraints: BoxConstraints(maxHeight: 56.v),
        validator: (value) {
          if (value == null || (!isValidEmail(value, isRequired: true))) {
            return translation(context).err_msg_please_enter_valid_email;
          }
          return null;
        },
        contentPadding: EdgeInsets.only(top: 18.v, right: 30.h, bottom: 18.v));
  }

  /// Section Widget
  Widget _buildSignUp(BuildContext context) {
    return svAppButton(
      context: context,
      text: 'Sign Up',
      onTap: () {
        onTapSignUp(context);
      },
    );
  }

  /// Displays a dialog with the [SignUpSuccessDialog] content.
  onTapSignUp(BuildContext context) {
    print(emailController.text.toString());
    dropdownBloc.add(SignUpButtonPressed(
        username: emailController.text.toString(),
        password: passwordController.text.toString(),
        firstName: firstnameController.text.toString(),
        lastName: lastNameController.text.toString(),
        userType: dropdownBloc.isDoctorRole ? 'doctor' : 'student'
      // replace with real input
    ));

    // showDialog(
    //     context: context,
    //     builder: (_) => AlertDialog(
    //           content: SignUpSuccessDialog.builder(context),
    //           backgroundColor: Colorsansparent,
    //           contentPadding: EdgeInsets.zero,
    //           insetPadding: const EdgeInsets.only(left: 0),
    //         ));
  }

  /// Navigates to the loginScreen when the action is triggered.
  onTapTxtLogIn(BuildContext context) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>LoginScreen()), (route) => false);

  }
}
// class DropdownWidget extends StatefulWidget {
//   final List<Countries> dynamicValues;
//
//
//   DropdownWidget(this.dynamicValues,);
//
//   @override
//   _DropdownWidgetState createState() => _DropdownWidgetState();
// }
//
// class _DropdownWidgetState extends State<DropdownWidget> {
//   String? selectedValue;
//   @override
//   Widget build(BuildContext context) {
//     print(widget.dynamicValues.toString());
//     return Padding(
//           padding: const EdgeInsets.all(10),
//           child: CustomDropdownButtonFormField(
//             items: widget.dynamicValues,
//             value: widget.dynamicValues.first.countryName,
//             width: double.infinity,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 10,
//               vertical: 0,
//             ),
//             onChanged: (value) {
//               setState(() {
//                 // if (value == 'Filter By Delivery Status') {
//                 //   _orders = _searchResult;
//                 // } else {
//                 //   print(value.toString());
//                 //   _orders = _searchResult
//                 //       .where((item) => item.deliveryStatus!
//                 //       .toLowerCase()
//                 //       .contains(
//                 //       value.toString().toLowerCase()))
//                 //       .toList();
//                 // }
//               });
//             },
//           ),
//         );
//   }
// }
