import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';
import 'package:doctak_app/presentation/login_screen/bloc/login_state.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../core/utils/app/AppData.dart';
import 'login_event.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<SocialLoginButtonPressed>(_onSocialLoginButtonPressed);
    on<ChangePasswordVisibilityEvent>(_changePasswordVisibility);
  }

  void _onLoginButtonPressed(LoginButtonPressed event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
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
        print('Running on ${iosInfo.utsname.machine}'); // e.g. "iPod7,1"
        deviceType = "ios";
        deviceId = iosInfo.identifierForVendor.toString();
      }

      Dio dio = Dio();
      Response response1 = await dio.post(
        '${AppData.remoteUrl2}/login',
        // Add query parameters
        data: FormData.fromMap({'email': event.username, 'password': event.password, 'device_token': event.deviceToken, 'device_type': deviceType, 'device_id': deviceId}),
      );
      // log(response);
      PostLoginDeviceAuthResp response = PostLoginDeviceAuthResp.fromJson(response1.data);

      if (response.success == true) {
        // if (response.user!.emailVerifiedAt == null) {
        //
        //   return;
        // }
        // if (response.user?.emailVerifiedAt != '' && response.user!.emailVerifiedAt != null) {
        if (event.rememberMe) {
          final prefs = SecureStorageService.instance;
          await prefs.initialize();
          await prefs.setString('token', response.token ?? '');
          await prefs.setBool('rememberMe', event.rememberMe);
          await prefs.setString('email_verified_at', response.user?.emailVerifiedAt ?? '');
          await prefs.setString('device_token', event.deviceToken ?? '');
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
          String? userType = await prefs.getString('user_type') ?? '';
          String? university = await prefs.getString('university') ?? '';
          String? specialty = await prefs.getString('specialty') ?? '';
          String? countryName = await prefs.getString('country') ?? '';
          String? city = await prefs.getString('city') ?? '';
          String? currency = await prefs.getString('currency') ?? '';

          if (userToken != '') {
            AppData.userToken = userToken;
            AppData.deviceToken = await prefs.getString('device_token') ?? event.deviceToken;
            AppData.logInUserId = userId;
            AppData.name = name;
            AppData.profile_pic = profilePic;

            AppData.university = university;
            AppData.userType = response.user?.userType ?? '';
            AppData.background = background;
            AppData.email = email;
            AppData.specialty = specialty;
            AppData.countryName = countryName;
            AppData.city = city;
            AppData.currency = currency;
          }
        } else {
          final prefs = SecureStorageService.instance;
          await prefs.initialize();
          await prefs.setString('token', response.token ?? '');
          String? userToken = await prefs.getString('token') ?? '';
          await prefs.setString('email_verified_at', response.user?.emailVerifiedAt ?? '');
          AppData.userToken = response.token ?? '';
          AppData.logInUserId = response.user?.id ?? '';
          AppData.name = '${response.user?.firstName ?? ''} ${response.user?.lastName ?? ''}';
          AppData.profile_pic = response.user?.profilePic ?? '';
          if (response.university != null) {
            AppData.university = response.university?.name ?? '';
          }
          AppData.deviceToken = event.deviceToken;

          AppData.userType = response.user?.userType ?? '';
          AppData.background = response.user?.background ?? '';
          AppData.email = response.user?.email ?? '';
          AppData.specialty = response.user?.specialty ?? '';
          AppData.countryName = response.user?.country ?? '';
          AppData.city = response.user?.state ?? '';
          AppData.currency = response.country?.currency ?? '';
        }

        emit(LoginSuccess(isEmailVerified: response.user?.emailVerifiedAt ?? ''));
        ProgressDialogUtils.hideProgressDialog();
      } else {
        ProgressDialogUtils.hideProgressDialog();

        emit(LoginFailure(error: 'Invalid credentials'));
      }
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      print(e);
      emit(LoginFailure(error: 'An error occurred'));
    }
  }

  void _onSocialLoginButtonPressed(SocialLoginButtonPressed event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
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
        print('Running on ${iosInfo.utsname.machine}'); // e.g. "iPod7,1"
        deviceType = "android";
        deviceId = iosInfo.identifierForVendor.toString();
      }

      Dio dio = Dio();
      Response response1 = await dio.post(
        '${AppData.remoteUrl2}/login', // Add query parameters
        data: FormData.fromMap({
          'email': event.email,
          'first_name': event.firstName,
          'last_name': event.lastName,
          'device_type': deviceType,
          'device_id': deviceId,
          'isSocialLogin': event.isSocialLogin,
          'provider': event.provider,
          'token': "4a080919-3829-4b4a-abdc-95b1267c4371",
          'device_token': event.deviceToken,
        }),
      );
      PostLoginDeviceAuthResp response = PostLoginDeviceAuthResp.fromJson(response1.data);

      //   final response = await apiService.loginWithSocial(
      //       event.email,
      //       event.firstName,
      //       event.lastName,
      //       deviceType,
      //       deviceId,
      //       event.isSocialLogin,
      //       event.provider,
      //       event.token,
      //     event.deviceToken
      //   );
      log(response.user?.userType ?? '');
      if (response.success == true) {
        ProgressDialogUtils.hideProgressDialog();
        // if (response.user!.emailVerifiedAt == null) {
        //   // showVerifyMessage(context);
        //   return;
        // }else
        // if (response.user?.userType != null) {
        // if (response.recentCreated == false) {
        final prefs = SecureStorageService.instance;
        await prefs.initialize();
        await prefs.setBool('rememberMe', true);
        await prefs.setString('device_token', event.deviceToken ?? '');
        await prefs.setString('email_verified_at', response.user?.emailVerifiedAt ?? '');
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
          AppData.deviceToken = await prefs.getString('device_token') ?? event.deviceToken;
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
        }
        emit(SocialLoginSuccess(response: response));
        // }
        // } else {
        //   emit(SocialLoginSuccess(response: response));
        // }
      } else {
        ProgressDialogUtils.hideProgressDialog();

        emit(LoginFailure(error: 'Invalid credentials'));
      }
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      print('=== Social Login Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error: $e');

      // Enhanced logging for DioException
      if (e is DioException) {
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        print('Request Data: ${e.requestOptions.data}');
        print('Request Headers: ${e.requestOptions.headers}');
        print('URL: ${e.requestOptions.uri}');
      }
      print('========================');

      emit(LoginFailure(error: 'An error occurred'));
    }
  }

  void _changePasswordVisibility(ChangePasswordVisibilityEvent event, Emitter<LoginState> emit) {
    emit(LoginState(isShowPassword: event.value));
    // emit(state.copyWith(isShowPassword: event.value));
  }
}
