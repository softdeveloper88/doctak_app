import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_req.dart';
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/core/app_export.dart';

part 'sign_up_event.dart';

part 'sign_up_state.dart';

/// A bloc that manages the state of a SignUp according to the event that is dispatched to it.

class DropdownBloc extends Bloc<DropdownEvent, DropdownState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  bool isVisiblePassword = false;
  bool isDoctorRole = true;

  DropdownBloc() : super(DropdownInitial()) {
    on<LoadDropdownValues>(_loadDropdownValues);
    on<TogglePasswordVisibility>(_changePasswordVisibility);
    on<ChangeDoctorRole>(_changeDoctorRole);
    on<CompleteButtonPressed>(_onCompleteButtonPressed);
    on<SignUpButtonPressed>(_onSignUpButtonPressed);
    on<SocialButtonPressed>(_onSocialLoginProfileCompletePressed);
  }

  void _loadDropdownValues(
      LoadDropdownValues event, Emitter<DropdownState> emit) async {
    try {
      // Simulate fetching dynamic values from an API or other source

      emit(DataLoaded(false, true, false, {}));
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
        (state as DataLoaded).response));
  }

  void _changeDoctorRole(ChangeDoctorRole event, Emitter<DropdownState> emit) {
    emit(DataLoaded(
      !(state as DataLoaded).isPasswordVisible,
      (state as DataLoaded).isDoctorRole,
      false,
      (state as DataLoaded).response,
    ));
  }

  void _onSignUpButtonPressed(
      SignUpButtonPressed event, Emitter<DropdownState> emit) async {
    ProgressDialogUtils.showProgressDialog();
    try {
      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      String deviceId='';
      String deviceType='';
      if(isAndroid){
        AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        print('Running on ${androidInfo.model}');
        deviceType="android";
        deviceId=androidInfo.id;
      }else{
        IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        print('Running on ${iosInfo.utsname.machine}');  // e.g. "iPod7,1"
        deviceType="ios";
        deviceId=iosInfo.identifierForVendor.toString();
      }
      // final response1 = await apiManager.register(
      //     event.firstName,
      //     event.lastName,
      //     event.username,
      //     event.password,
      //     event.userType,event.deviceToken??"",deviceType,deviceId);
      Dio dio = Dio();

      Response response1 = await dio.post(
          '${AppData.remoteUrl2}/register',
          // Add query parameters
          data: FormData.fromMap({
            'first_name': event.firstName,
            'last_name': event.lastName,
            'email': event.username,
            'password': event.password,
            'user_type': event.userType,
            'device_token': event.deviceToken,
            'device_type': deviceType,
            'device_id': deviceId,
          })
      );
      PostLoginDeviceAuthResp response=PostLoginDeviceAuthResp.fromJson(response1.data);
        ProgressDialogUtils.hideProgressDialog();
        print('response ${response1.data}');
        if(response1.statusCode==200) {
          if (response.success == true) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('device_token', event.deviceToken ?? '');
            await prefs.setString('token', response.token ?? '');
            await prefs.setString(
                'email_verified_at', response.user?.emailVerifiedAt ?? '');
            await prefs.setString('userId', response.user?.id ?? '');
            await prefs.setString('name',
                '${response.user?.firstName ?? ''} ${response.user?.lastName ??
                    ''}');
            await prefs.setString(
                'profile_pic', response.user?.profilePic ?? '');
            await prefs.setString('email', response.user?.email ?? '');
            await prefs.setString('phone', response.user?.phone ?? '');
            await prefs.setString(
                'background', response.user?.background ?? '');
            await prefs.setString('specialty', response.user?.specialty ?? '');
            await prefs.setString('licenseNo', response.user?.licenseNo ?? '');
            await prefs.setString('title', response.user?.title ?? '');
            await prefs.setString('city', response.user?.state ?? '');
            await prefs.setString(
                'countryOrigin', response.user?.countryOrigin ?? '');
            await prefs.setString('college', response.user?.college ?? '');
            await prefs.setString(
                'clinicName', response.user?.clinicName ?? '');
            await prefs.setString('dob', response.user?.dob ?? '');
            await prefs.setString('user_type', response.user?.userType ?? '');
            await prefs.setString(
                'countryName', response.country?.countryName ?? '');
            await prefs.setString('currency', response.country?.currency ?? '');
            if (response.university != null) {
              await prefs.setString(
                  'university', response.university?.name ?? '');
            }
            await prefs.setString(
                'practicingCountry', response.user?.practicingCountry ?? '');
            await prefs.setString('gender', response.user?.gender ?? '');
            await prefs.setString(
                'country', response.user?.country.toString() ?? '');
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
            String? city = prefs.getString('city') ?? '';
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
              AppData.city = city;
              AppData.currency = currency;
            }
            emit(DataLoaded(!(state as DataLoaded).isPasswordVisible,
                (state as DataLoaded).isDoctorRole, true, response1.data));
            ProgressDialogUtils.hideProgressDialog();
          } else {
            emit(DataLoaded(!(state as DataLoaded).isPasswordVisible,
                (state as DataLoaded).isDoctorRole, true, response1.data));
          }
        }else{
          emit(DropdownError( 'An error occurred'));
        }
    } catch (e) {
      print(e);
      // emit(DropdownLoaded1(response: ));

      ProgressDialogUtils.hideProgressDialog();

      emit(DropdownError( 'An error occurred'));
    }
  }
  void _onCompleteButtonPressed(
      CompleteButtonPressed event, Emitter<DropdownState> emit) async {
    ProgressDialogUtils.showProgressDialog();
    print(event.country);
    print(event.state);
    print(event.specialty);
    try {
      Dio dio = Dio();
      Response response1 = await dio.post(
          '${AppData.remoteUrl2}/update-profile',
          options: Options(headers: {
            'Authorization': 'Bearer ${AppData.userToken}',  // Set headers
          }),// Add query parameters
          data: FormData.fromMap({
            'country': event.country,
            'state': event.state,
            'specialty': event.specialty,
          })
      );
      if (response1.statusCode == 200) {
        AppData.countryName=event.country;
        AppData.city=event.state;
        AppData.specialty=event.specialty;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('specialty',event.specialty) ;
        prefs.setString('country',event.country) ?? '';
        prefs.setString('city',event.state) ?? '';
        ProgressDialogUtils.hideProgressDialog();
        emit(DataCompleteLoaded(response1.data));
        // emit(DropdownLoaded1(response: response.response.data));
      } else {
        emit(DropdownError(response1.data));
        ProgressDialogUtils.hideProgressDialog();
        // emit(LoginFailure(error: 'Invalid credentials'));
      }
    } catch (e) {
      toast('Something went wrong please try again');

      ProgressDialogUtils.hideProgressDialog();
      emit(DropdownError(e.toString()));
    }
  }

  void _onSocialLoginProfileCompletePressed(
      SocialButtonPressed event, Emitter<DropdownState> emit) async {
    ProgressDialogUtils.showProgressDialog();
    try {
      print(event.token);
      final response = await apiManager.completeProfile(
          'Bearer ${event.token}',
          event.firstName,
          event.lastName,
          '',
          '',
          '',
          event.phone,
          event.userType,
      );
      log(event.token);

    print('response ${response.toJson()}');
      if (response.user!.userType != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('device_token', event.deviceToken ?? '');
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
        await prefs.setString('city', response.user?.state ?? '');
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
        await prefs.setString(
            'country', response.user?.country.toString() ?? '');
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
      } else {
        emit(DataLoaded(!(state as DataLoaded).isPasswordVisible,
            (state as DataLoaded).isDoctorRole, true, {}));
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
      emit(DataLoaded(!(state as DataLoaded).isPasswordVisible,
          (state as DataLoaded).isDoctorRole, true, {}));

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
