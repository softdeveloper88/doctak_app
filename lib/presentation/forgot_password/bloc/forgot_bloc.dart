import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/presentation/forgot_password/bloc/forgot_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'forgot_state.dart';

class ForgotBloc extends Bloc<ForgotEvent, ForgotState> {
  final ApiService apiService = ApiService(Dio(BaseOptions(
    followRedirects: true,
    maxRedirects: 5, // Set maximum number of redirects to follow
  )));

  ForgotBloc() : super(ForgotInitial()) {
    on<ForgotPasswordEvent>(_onLoginButtonPressed);
  }

  void _onLoginButtonPressed(
      ForgotPasswordEvent event, Emitter<ForgotState> emit) async {
    ProgressDialogUtils.showProgressDialog();
    print("response ${event.username}");

    // try {
    //   final response = await apiService.forgotPassword(
    //        event.username,
    //   );
    var postBody = {
      'email': event.username,
    };
    Uri url = Uri.parse("https://doctak.net/api/v1/forgot_password");
    final response = await http.post(
      url,
      body: jsonEncode(postBody),
      headers: {
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      ProgressDialogUtils.hideProgressDialog();

      emit(ForgotSuccess(response: response.body));
    } else {
      ProgressDialogUtils.hideProgressDialog();

      emit(ForgotFailure(error: response.body));
    }
    // } catch (e) {
    //   ProgressDialogUtils.hideProgressDialog();
    //   print(e);
    //   emit(ForgotFailure(error: 'An error occurred'));
    // }
  }
}
