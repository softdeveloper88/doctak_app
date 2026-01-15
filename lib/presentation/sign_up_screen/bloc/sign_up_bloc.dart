import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';
import 'package:equatable/equatable.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';

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

  void _loadDropdownValues(LoadDropdownValues event, Emitter<DropdownState> emit) async {
    try {
      // Simulate fetching dynamic values from an API or other source

      emit(DataLoaded(false, true, false, {}));
      print('daa');
    } catch (e) {
      emit(DropdownError('Failed to load dropdown values1'));
    }
  }

  void _changePasswordVisibility(TogglePasswordVisibility event, Emitter<DropdownState> emit) {
    emit(DataLoaded(!(state as DataLoaded).isPasswordVisible, (state as DataLoaded).isDoctorRole, false, (state as DataLoaded).response));
  }

  void _changeDoctorRole(ChangeDoctorRole event, Emitter<DropdownState> emit) {
    emit(DataLoaded(!(state as DataLoaded).isPasswordVisible, (state as DataLoaded).isDoctorRole, false, (state as DataLoaded).response));
  }

  void _onSignUpButtonPressed(SignUpButtonPressed event, Emitter<DropdownState> emit) async {
    ProgressDialogUtils.showProgressDialog();
    try {
      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      String deviceId = '';
      String deviceType = '';
      if (isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        print('Running on ${androidInfo.model}');
        deviceType = "android";
        deviceId = androidInfo.id;
      } else {
        IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        print('Running on ${iosInfo.utsname.machine}');
        deviceType = "ios";
        deviceId = iosInfo.identifierForVendor.toString();
      }

      Dio dio = Dio();

      Response response1;
      try {
        response1 = await dio.post(
          '${AppData.remoteUrl2}/register',
          data: FormData.fromMap({
            'first_name': event.firstName,
            'last_name': event.lastName,
            'email': event.username,
            'password': event.password,
            'user_type': event.userType,
            'device_token': event.deviceToken,
            'device_type': deviceType,
            'device_id': deviceId,
          }),
        );
      } on DioException catch (dioError) {
        // Handle DioException - check if response contains token (registration succeeded but email failed)
        if (dioError.response != null && dioError.response!.data != null) {
          final responseData = dioError.response!.data;
          if (responseData is Map && responseData['token'] != null) {
            // User was registered successfully, just email sending failed
            print('Registration succeeded but email sending failed - bypassing email error');
            response1 = Response(requestOptions: dioError.requestOptions, statusCode: 200, data: responseData);
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      PostLoginDeviceAuthResp response = PostLoginDeviceAuthResp.fromJson(response1.data);
      ProgressDialogUtils.hideProgressDialog();
      print('response ${response1.data}');

      // Check for email error but successful registration (bypass email sending exceptions)
      final responseData = response1.data;
      bool hasToken = response.token != null && response.token!.isNotEmpty;
      bool hasEmailError =
          responseData is Map &&
          (responseData['email_error'] != null ||
              responseData['message']?.toString().toLowerCase().contains('email') == true ||
              responseData['message']?.toString().toLowerCase().contains('smtp') == true ||
              responseData['message']?.toString().toLowerCase().contains('mail') == true);

      // If we have a token, consider registration successful regardless of email errors
      if (hasToken || response1.statusCode == 200 && response.success == true) {
        if (hasToken || response.success == true) {
          final prefs = SecureStorageService.instance;
          await prefs.initialize();
          await prefs.setString('device_token', event.deviceToken);
          await prefs.setString('token', response.token ?? '');
          await prefs.setString('email_verified_at', response.user?.emailVerifiedAt ?? '');
          await prefs.setString('userId', response.user?.id ?? '');
          await prefs.setString('name', '${response.user?.firstName ?? ''} ${response.user?.lastName ?? ''}');
          await prefs.setString('profile_pic', response.user?.profilePic ?? '');
          await prefs.setString('email', response.user?.email ?? '');
          await prefs.setString('phone', response.user?.phone ?? '');
          await prefs.setString('background', response.user?.background ?? '');
          await prefs.setString('specialty', response.user?.specialty ?? '');
          await prefs.setString('licenseNo', response.user?.licenseNo ?? '');
          await prefs.setString('title', response.user?.title ?? '');
          await prefs.setString('city', response.user?.state ?? '');
          await prefs.setString('countryOrigin', response.user?.countryOrigin ?? '');
          await prefs.setString('college', response.user?.college ?? '');
          await prefs.setString('clinicName', response.user?.clinicName ?? '');
          await prefs.setString('dob', response.user?.dob ?? '');
          await prefs.setString('user_type', response.user?.userType ?? '');
          await prefs.setString('countryName', response.country?.countryName ?? '');
          await prefs.setString('currency', response.country?.currency ?? '');
          if (response.university != null) {
            await prefs.setString('university', response.university?.name ?? '');
          }
          await prefs.setString('practicingCountry', response.user?.practicingCountry ?? '');
          await prefs.setString('gender', response.user?.gender ?? '');
          await prefs.setString('country', response.user?.country.toString() ?? '');
          String? userToken = await prefs.getString('token') ?? '';
          String? userId = await prefs.getString('userId') ?? '';
          String? name = await prefs.getString('name') ?? '';
          String? profilePic = await prefs.getString('profile_pic') ?? '';
          String? background = await prefs.getString('background') ?? '';
          String? email = await prefs.getString('email') ?? '';
          String? specialty = await prefs.getString('specialty') ?? '';
          String? userType = await prefs.getString('user_type') ?? '';
          String? university = await prefs.getString('university') ?? '';
          String? countryName = await prefs.getString('country') ?? '';
          String? city = await prefs.getString('city') ?? '';
          String? currency = await prefs.getString('currency') ?? '';

          if (userToken != '') {
            AppData.userToken = userToken;
            AppData.logInUserId = userId;
            AppData.name = name;
            AppData.profile_pic = profilePic;
            AppData.university = university;
            AppData.userType = userType;
            AppData.background = background;
            AppData.email = email;
            AppData.specialty = specialty;
            AppData.countryName = countryName;
            AppData.city = city;
            AppData.currency = currency;
          }

          // Mark response as success even if there was an email error
          final emitData = Map<String, dynamic>.from(response1.data as Map);
          emitData['success'] = true;
          if (hasEmailError) {
            print('Email sending failed but registration succeeded - continuing to dashboard');
          }

          emit(DataLoaded(!(state as DataLoaded).isPasswordVisible, (state as DataLoaded).isDoctorRole, true, emitData));
          ProgressDialogUtils.hideProgressDialog();
        } else {
          emit(DataLoaded(!(state as DataLoaded).isPasswordVisible, (state as DataLoaded).isDoctorRole, true, response1.data));
        }
      } else {
        emit(DropdownError('An error occurred'));
      }
    } catch (e) {
      print('Registration error: $e');
      ProgressDialogUtils.hideProgressDialog();

      // Check if error message contains email-related keywords but might still have succeeded
      String errorStr = e.toString().toLowerCase();
      if (errorStr.contains('email') || errorStr.contains('smtp') || errorStr.contains('mail')) {
        // This might be an email sending error after successful registration
        // Try to check if user was actually registered by attempting to get token
        print('Possible email error detected - registration may have succeeded');
      }

      emit(DropdownError('An error occurred'));
    }
  }

  void _onCompleteButtonPressed(CompleteButtonPressed event, Emitter<DropdownState> emit) async {
    ProgressDialogUtils.showProgressDialog();
    print(event.country);
    print(event.state);
    print(event.specialty);
    try {
      Dio dio = Dio();
      Response response1 = await dio.post(
        '${AppData.remoteUrl2}/update-profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppData.userToken}', // Set headers
          },
        ), // Add query parameters
        data: FormData.fromMap({'country': event.country, 'state': event.state, 'specialty': event.specialty}),
      );
      if (response1.statusCode == 200) {
        AppData.countryName = event.country;
        AppData.city = event.state;
        AppData.specialty = event.specialty;
        final prefs = SecureStorageService.instance;
        await prefs.initialize();
        prefs.setString('specialty', event.specialty);
        prefs.setString('country', event.country);
        prefs.setString('city', event.state);
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

  void _onSocialLoginProfileCompletePressed(SocialButtonPressed event, Emitter<DropdownState> emit) async {
    ProgressDialogUtils.showProgressDialog();
    try {
      print(event.token);
      final response = await apiManager.completeProfile('Bearer ${event.token}', event.firstName, event.lastName, '', '', '', event.phone, event.userType);
      log(event.token);

      print('response ${response.toJson()}');
      if (response.user!.userType != null) {
        final prefs = SecureStorageService.instance;
        await prefs.initialize();
        await prefs.setString('device_token', event.deviceToken);
        await prefs.setString('token', response.token ?? '');
        await prefs.setString('userId', response.user?.id ?? '');
        await prefs.setString('name', '${response.user?.firstName ?? ''} ${response.user?.lastName ?? ''}');
        await prefs.setString('profile_pic', response.user?.profilePic ?? '');
        await prefs.setString('email', response.user?.email ?? '');
        await prefs.setString('phone', response.user?.phone ?? '');
        await prefs.setString('background', response.user?.background ?? '');
        await prefs.setString('specialty', response.user?.specialty ?? '');
        await prefs.setString('licenseNo', response.user?.licenseNo ?? '');
        await prefs.setString('title', response.user?.title ?? '');
        await prefs.setString('city', response.user?.state ?? '');
        await prefs.setString('countryOrigin', response.user?.countryOrigin ?? '');
        await prefs.setString('college', response.user?.college ?? '');
        await prefs.setString('clinicName', response.user?.clinicName ?? '');
        await prefs.setString('dob', response.user?.dob ?? '');
        await prefs.setString('user_type', response.user?.userType ?? '');
        await prefs.setString('countryName', response.country?.countryName ?? '');
        await prefs.setString('currency', response.country?.currency ?? '');
        if (response.university != null) {
          await prefs.setString('university', response.university?.name ?? '');
        }
        await prefs.setString('practicingCountry', response.user?.practicingCountry ?? '');
        await prefs.setString('gender', response.user?.gender ?? '');
        await prefs.setString('country', response.user?.country.toString() ?? '');
        String? userToken = await prefs.getString('token') ?? '';
        String? userId = await prefs.getString('userId') ?? '';
        String? name = await prefs.getString('name') ?? '';
        String? profilePic = await prefs.getString('profile_pic') ?? '';
        String? background = await prefs.getString('background') ?? '';
        String? email = await prefs.getString('email') ?? '';
        String? specialty = await prefs.getString('specialty') ?? '';
        String? userType = await prefs.getString('user_type') ?? '';
        String? university = await prefs.getString('university') ?? '';
        String? countryName = await prefs.getString('country') ?? '';
        String? currency = await prefs.getString('currency') ?? '';

        if (userToken != '') {
          AppData.userToken = userToken;
          AppData.logInUserId = userId;
          AppData.name = name;
          AppData.profile_pic = profilePic;
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
        emit(DataLoaded(!(state as DataLoaded).isPasswordVisible, (state as DataLoaded).isDoctorRole, true, {}));
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
      emit(DataLoaded(!(state as DataLoaded).isPasswordVisible, (state as DataLoaded).isDoctorRole, true, {}));

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
