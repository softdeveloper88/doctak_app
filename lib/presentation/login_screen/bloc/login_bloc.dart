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

  String _messageFromDio(DioException e, {String fallback = 'An error occurred'}) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    if (e.response?.statusCode == 401) {
      return 'Invalid email or password';
    }
    return fallback;
  }

  void _onLoginButtonPressed(LoginButtonPressed event, Emitter<LoginState> emit) async {
    emit(LoginLoading(isShowPassword: state.isShowPassword));
    ProgressDialogUtils.showProgressDialog();
    try {
      final deviceInfo = await _getDeviceInfo();
      final email = event.username.trim();
      final password = event.password;

      if (email.isEmpty || password.isEmpty) {
        ProgressDialogUtils.hideProgressDialog();
        emit(LoginFailure(error: 'Please enter your email and password'));
        return;
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Accept': 'application/json',
          // Opt into server-side 2FA challenge (store builds omit this and keep legacy login).
          'X-Doctak-Supports-2FA': '1',
        },
      ));

      final response1 = await dio.post(
        '${AppData.remoteUrlV6}/login',
        data: FormData.fromMap({
          'email': email,
          'password': password,
          'device_token': event.deviceToken,
          'device_type': deviceInfo['device_type'],
          'device_id': deviceInfo['device_id'],
          'remember': event.rememberMe ? '1' : '0',
          'supports_2fa': '1',
        }),
      );

      final raw = response1.data;
      if (raw is Map && raw['requires_2fa'] == true) {
        ProgressDialogUtils.hideProgressDialog();
        final methodsRaw = raw['methods'];
        final methods = <String, bool>{
          'email': methodsRaw is Map ? methodsRaw['email'] == true : false,
          'app': methodsRaw is Map ? methodsRaw['app'] == true : false,
        };
        final pendingToken = (raw['pending_token'] ?? '').toString();
        if (pendingToken.isEmpty || (!methods['email']! && !methods['app']!)) {
          emit(LoginFailure(error: 'Two-factor challenge could not be started. Please try again.'));
          return;
        }
        emit(LoginRequiresTwoFactor(
          pendingToken: pendingToken,
          methods: methods,
          maskedEmail: raw['masked_email']?.toString(),
          message: raw['message']?.toString(),
          emailSent: raw['email_sent'] != false,
          rememberMe: event.rememberMe,
          deviceToken: event.deviceToken,
        ));
        return;
      }

      final response = PostLoginDeviceAuthResp.fromJson(raw);

      if (response.success == true && (response.token?.isNotEmpty ?? false)) {
        await AuthSessionHelper.persistSession(
          response,
          deviceToken: event.deviceToken,
          rememberMe: event.rememberMe,
        );

        emit(LoginSuccess(isEmailVerified: response.user?.emailVerifiedAt ?? ''));
        ProgressDialogUtils.hideProgressDialog();
      } else {
        ProgressDialogUtils.hideProgressDialog();
        emit(LoginFailure(error: 'Invalid email or password'));
      }
    } on DioException catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      emit(LoginFailure(error: _messageFromDio(e)));
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      emit(LoginFailure(error: 'An error occurred. Please try again.'));
    }
  }

  void _onSocialLoginButtonPressed(SocialLoginButtonPressed event, Emitter<LoginState> emit) async {
    emit(LoginLoading(isShowPassword: state.isShowPassword));
    ProgressDialogUtils.showProgressDialog();
    try {
      final deviceInfo = await _getDeviceInfo();

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
      ));

      final response1 = await dio.post(
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
          'remember': '1',
        }),
      );

      final response = PostLoginDeviceAuthResp.fromJson(response1.data);

      log(response.user?.userType ?? '');
      if (response.success == true) {
        ProgressDialogUtils.hideProgressDialog();

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
    } on DioException catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      emit(LoginFailure(error: _messageFromDio(e)));
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      emit(LoginFailure(error: 'An error occurred. Please try again.'));
    }
  }

  void _changePasswordVisibility(ChangePasswordVisibilityEvent event, Emitter<LoginState> emit) {
    emit(state.copyWith(isShowPassword: event.value));
  }
}
