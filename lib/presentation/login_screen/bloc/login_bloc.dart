import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/auth_session_helper.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
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

  /// Get device info (id + type) for auth requests
  Future<Map<String, String>> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String deviceId = '';
    String deviceType = '';
    if (isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      deviceType = "android";
      deviceId = androidInfo.id;
    } else {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      deviceType = "ios";
      deviceId = iosInfo.identifierForVendor.toString();
    }
    return {'device_id': deviceId, 'device_type': deviceType};
  }

  void _onLoginButtonPressed(LoginButtonPressed event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    ProgressDialogUtils.showProgressDialog();
    try {
      final deviceInfo = await _getDeviceInfo();

      Dio dio = Dio();
      Response response1 = await dio.post(
        '${AppData.remoteUrlV6}/login',
        data: FormData.fromMap({
          'email': event.username,
          'password': event.password,
          'device_token': event.deviceToken,
          'device_type': deviceInfo['device_type'],
          'device_id': deviceInfo['device_id'],
        }),
      );

      PostLoginDeviceAuthResp response = PostLoginDeviceAuthResp.fromJson(response1.data);

      if (response.success == true) {
        // Use centralized session helper to persist all user & subscription data
        await AuthSessionHelper.persistSession(
          response,
          deviceToken: event.deviceToken,
          rememberMe: event.rememberMe,
        );

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
      final deviceInfo = await _getDeviceInfo();

      Dio dio = Dio();
      // Use v6 social-login endpoint with actual OAuth id_token
      Response response1 = await dio.post(
        '${AppData.remoteUrlV6}/social-login',
        data: FormData.fromMap({
          'email': event.email,
          'first_name': event.firstName,
          'last_name': event.lastName,
          'provider': event.provider,
          'id_token': event.token,
          'device_token': event.deviceToken,
          'device_type': deviceInfo['device_type'],
          'device_id': deviceInfo['device_id'],
        }),
      );

      PostLoginDeviceAuthResp response = PostLoginDeviceAuthResp.fromJson(response1.data);

      log(response.user?.userType ?? '');
      if (response.success == true) {
        ProgressDialogUtils.hideProgressDialog();

        // Use centralized session helper
        await AuthSessionHelper.persistSession(
          response,
          deviceToken: event.deviceToken,
          rememberMe: true,
        );

        emit(SocialLoginSuccess(response: response));
      } else {
        ProgressDialogUtils.hideProgressDialog();
        emit(LoginFailure(error: 'Invalid credentials'));
      }
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      print('=== Social Login Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error: $e');

      if (e is DioException) {
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        print('Request Data: ${e.requestOptions.data}');
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
