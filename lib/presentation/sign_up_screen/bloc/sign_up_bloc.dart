import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/core/app_export.dart';

part 'sign_up_event.dart';

part 'sign_up_state.dart';

/// A bloc that manages the state of a SignUp according to the event that is dispatched to it.

class DropdownBloc extends Bloc<DropdownEvent, DropdownState> {
  final ApiService apiService = ApiService(Dio());
  bool isVisiblePassword = false;
  bool isDoctorRole = true;

  DropdownBloc() : super(DropdownInitial()) {
    on<LoadDropdownValues>(_loadDropdownValues);
     on<TogglePasswordVisibility>(_changePasswordVisibility);
    on<ChangeDoctorRole>(_changeDoctorRole);
    on<SignUpButtonPressed>(_onSignUpButtonPressed);
    on<SocialButtonPressed>(_onSocialLoginProfileCompletePressed);

  }

  void _loadDropdownValues(
      LoadDropdownValues event, Emitter<DropdownState> emit) async {
    try {
      // Simulate fetching dynamic values from an API or other source

      emit(DataLoaded(false, true,false,{}));
      print('daa');
    } catch (e) {
      emit(DropdownError('Failed to load dropdown values1'));
    }
  }


  void _changePasswordVisibility(
      TogglePasswordVisibility event, Emitter<DropdownState> emit) {
    emit(DataLoaded(
      !(state as DataLoaded).isPasswordVisible,
      (state as DataLoaded).isDoctorRole,
        false,
        (state as DataLoaded).response
    ));

  }

  void _changeDoctorRole(ChangeDoctorRole event, Emitter<DropdownState> emit) {
    emit(DataLoaded(
      !(state as DataLoaded).isPasswordVisible,
      (state as DataLoaded).isDoctorRole,
      false,

        (state as DataLoaded).response,
    ));
  }

  void _onSignUpButtonPressed(SignUpButtonPressed event, Emitter<DropdownState> emit) async {
    ProgressDialogUtils.showProgressDialog();
    try {
      print(event.firstName);
      final response = await apiService.register(
          event.firstName, event.lastName,event.username, event.password, event.userType);
      if (response.response.statusCode == 200) {

        ProgressDialogUtils.hideProgressDialog();
        emit(DataLoaded( !(state as DataLoaded).isPasswordVisible,
            (state as DataLoaded).isDoctorRole,true, response.response.data));

        // emit(DropdownLoaded1(response: response.response.data));
      } else {
        emit(DataLoaded( !(state as DataLoaded).isPasswordVisible,
            (state as DataLoaded).isDoctorRole,true, response.response.data));
        print('rese ${response.response.data}');
        ProgressDialogUtils.hideProgressDialog();
        // emit(LoginFailure(error: 'Invalid credentials'));
      }
    } catch (e) {
      print(e);
      // emit(DropdownLoaded1(response: ));

      ProgressDialogUtils.hideProgressDialog();

      // emit(LoginFailure(error: 'An error occurred'));
    }
  }
  void _onSocialLoginProfileCompletePressed(SocialButtonPressed event, Emitter<DropdownState> emit) async {
    ProgressDialogUtils.showProgressDialog();
    try {

      print(event.token);
      final response = await apiService.completeProfile(
           'Bearer ${event.token}',
          event.firstName, event.lastName,event.country,event.state,event.phone,event.userType);

    if(response.user!.userType !=null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response.token ?? '');
      await prefs.setString('userId', response.user?.id ?? '');
      await prefs.setString('name',
          '${response.user?.firstName ?? ''} ${response.user?.lastName ?? ''}');
      await prefs.setString('profile_pic', response.user?.profilePic ?? '');
      await prefs.setString('email', response.user?.email ?? '');
      await prefs.setString('phone', response.user?.phone ?? '');
      await prefs.setString('background', response.user?.background ?? '');
      await prefs.setString('specialty', response.user?.specialty ?? '');
      await prefs.setString('licenseNo', response.user?.licenseNo ?? '');
      await prefs.setString('title', response.user?.title ?? '');
      await prefs.setString('city', response.user?.city ?? '');
      await prefs.setString(
          'countryOrigin', response.user?.countryOrigin ?? '');
      await prefs.setString('college', response.user?.college ?? '');
      await prefs.setString('clinicName', response.user?.clinicName ?? '');
      await prefs.setString('dob', response.user?.dob ?? '');
      await prefs.setString('user_type', response.user?.userType ?? '');
      await prefs.setString(
          'countryName', response.country?.countryName ?? '');
      await prefs.setString('currency', response.country?.currency ?? '');
      if (response.university != null) {
        await prefs.setString('university', response.university?.name ?? '');
      }
      await prefs.setString(
          'practicingCountry', response.user?.practicingCountry ?? '');
      await prefs.setString('gender', response.user?.gender ?? '');
      await prefs.setString('country', response.user?.country.toString() ?? '');
      String? userToken = prefs.getString('token') ?? '';
      String? userId = prefs.getString('userId') ?? '';
      String? name = prefs.getString('name') ?? '';
      String? profile_pic = prefs.getString('profile_pic') ?? '';
      String? background = prefs.getString('background') ?? '';
      String? email = prefs.getString('email') ?? '';
      String? specialty = prefs.getString('specialty') ?? '';
      String? userType = prefs.getString('user_type') ?? '';
      String? university = prefs.getString('university') ?? '';
      String? countryName = prefs.getString('country') ?? '';
      String? currency = prefs.getString('currency') ?? '';

      if (userToken != '') {
        AppData.userToken = userToken;
        AppData.logInUserId = userId;
        AppData.name = name;
        AppData.profile_pic = profile_pic;
        AppData.university = university;
        AppData.userType = userType;
        AppData.background = background;
        AppData.email = email;
        AppData.specialty = specialty;
        AppData.countryName = countryName;
        AppData.currency = currency;

        emit(SocialLoginSuccess());
      }

      ProgressDialogUtils.hideProgressDialog();
      print("hello${response.toJson()}");
    }else{
      emit(DataLoaded( !(state as DataLoaded).isPasswordVisible,
          (state as DataLoaded).isDoctorRole,true, {}));

    }
        // emit(DataLoaded( !(state as DataLoaded).isPasswordVisible,
        //     (state as DataLoaded).isDoctorRole,true, response.response.data));

        // emit(DropdownLoaded1(response: response.response.data));
      // } else {
      //   emit(DataLoaded( !(state as DataLoaded).isPasswordVisible,
      //       (state as DataLoaded).isDoctorRole,true, response.response.data));
      //   print('rese ${response.response.data}');
      //   ProgressDialogUtils.hideProgressDialog();
      //   // emit(LoginFailure(error: 'Invalid credentials'));
      // }
    } catch (e) {
      print(e);
      emit(DataLoaded( !(state as DataLoaded).isPasswordVisible,
          (state as DataLoaded).isDoctorRole,true, {}));


      ProgressDialogUtils.hideProgressDialog();

      // emit(LoginFailure(error: 'An error occurred'));
    }
  }
}

//
//   _changeCheckBox(
//     ChangeCheckBoxEvent event,
//     Emitter<SignUpState> emit,
//   ) {
//     emit(state.copyWith(checkbox: event.value));
//
//   }
//
//   _onInitialize(
//     SignUpInitialEvent event,
//     Emitter<SignUpState> emit,
//   ) async {
//     emit(state.copyWith(
//         nameController: TextEditingController(),
//         emailController: TextEditingController(),
//         passwordController: TextEditingController(),
//         isShowPassword: true,
//         checkbox: false));
//
//
//     // NavigatorService.pushNamed(
//     //   AppRoutes.loginScreen,
//     // );
//   }
// }
