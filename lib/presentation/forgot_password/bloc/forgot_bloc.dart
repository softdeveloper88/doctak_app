import 'dart:convert';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/presentation/forgot_password/bloc/forgot_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'forgot_state.dart';

class ForgotBloc extends Bloc<ForgotEvent, ForgotState> {
  ForgotBloc() : super(ForgotInitial()) {
    on<ForgotPasswordEvent>(_onForgotPassword);
  }

  String get _deviceType {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'android';
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordEvent event,
    Emitter<ForgotState> emit,
  ) async {
    ProgressDialogUtils.showProgressDialog();
    emit(ForgotLoading());

    try {
      final email = event.username.trim();
      final url = Uri.parse('${AppData.remoteUrl}/forgot_password');
      final response = await http.post(
        url,
        body: jsonEncode({
          'email': email,
          // Native skips Turnstile; web clients still get checked server-side.
          'device_type': _deviceType,
        }),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      ProgressDialogUtils.hideProgressDialog();

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        data = {};
      }

      final message = data['message']?.toString() ?? '';
      final code = data['code']?.toString() ?? '';
      final success = data['success'] == true;

      if (response.statusCode == 200 && success) {
        emit(ForgotSuccess(
          response: response.body,
          message: message.isNotEmpty
              ? message
              : 'We sent a password reset link to your email. Open it to choose a new password.',
        ));
        return;
      }

      String errorMessage = message;
      if (errorMessage.isEmpty) {
        if (code == 'not_found' || response.statusCode == 422) {
          errorMessage = 'No DocTak account was found for that email address.';
        } else {
          errorMessage = 'Could not send reset email. Please try again.';
        }
      }

      emit(ForgotFailure(error: errorMessage));
    } catch (_) {
      ProgressDialogUtils.hideProgressDialog();
      emit(const ForgotFailure(error: 'Could not send reset email. Please try again.'));
    }
  }
}
