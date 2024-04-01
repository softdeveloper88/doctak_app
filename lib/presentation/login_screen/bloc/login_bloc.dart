// // import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_req.dart';
// // import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';
// // import 'package:doctak_app/data/repository/repository.dart';
// // import 'package:equatable/equatable.dart';
// // import 'package:flutter/material.dart';
// // import '/core/app_export.dart';
// // import 'package:doctak_app/presentation/login_screen/models/login_model.dart';
// // import 'dart:async';
// // part 'login_event.dart';
// // part 'login_state.dart';
// //
// // /// A bloc that manages the state of a Login according to the event that is dispatched to it.
// // class LoginBloc extends Bloc<LoginEvent, LoginState> {
// //   LoginBloc(LoginState initialState) : super(initialState) {
// //     on<LoginInitialEvent>(_onInitialize);
// //     on<ChangePasswordVisibilityEvent>(_changePasswordVisibility);
// //     on<CreateLoginEvent>(_callLoginDeviceAuth);
// //   }
// //
// //   final _repository = Repository();
// //
// //   var postLoginDeviceAuthResp = PostLoginDeviceAuthResp();
// //
// //   _changePasswordVisibility(
// //       ChangePasswordVisibilityEvent event,
// //       Emitter<LoginState> emit,
// //       ) {
// //     emit(state.copyWith(isShowPassword: event.value));
// //   }
// //   /// Calls the https://nodedemo.dhiwise.co/device/auth/login API and triggers a [CreateLoginEvent] event on the [LoginBloc] bloc.
// //   ///
// //   /// The [BuildContext] parameter represents current [BuildContext]
// //   _onInitialize(
// //       LoginInitialEvent event,
// //       Emitter<LoginState> emit,) async {
// //       emit(state.copyWith(
// //         emailController: TextEditingController(),
// //         passwordController: TextEditingController(),
// //         deviceType: 'mobile',
// //         deviceId: '12345',
// //         isShowPassword: true));
// //     add(
// //       CreateLoginEvent(),
// //     );
// //     print(emit);
// //   }
// //
// //   /// Requests permission to access the camera and storage, and displays a model
// //   /// sheet for selecting images.
// //   ///
// //   /// Throws an error if permission is denied or an error occurs while selecting images.
// //   onReady(BuildContext context) async {
// //     await PermissionManager.askForPermission(Permission.camera);
// //     await PermissionManager.askForPermission(Permission.storage);
// //     List<String?>? imageList = [];
// //     await FileManager().showModelSheetForImage(getImages: (value) async {
// //       imageList = value;
// //     });
// //   }
// //
// //   /// Calls [https://nodedemo.dhiwise.co/device/auth/login] with the provided event and emits the state.
// //   ///
// //   /// The [CreateLoginEvent] parameter is used for handling event data
// //   /// The [emit] parameter is used for emitting the state
// //   ///
// //   /// Throws an error if an error occurs during the API call process.
// //   FutureOr<void> _callLoginDeviceAuth(
// //       CreateLoginEvent event,
// //       Emitter<LoginState> emit,
// //       ) async {
// //     var postLoginDeviceAuthReq = PostLoginDeviceAuthReq(email:'adnanpk44@gmail.com',password: 'admin123',deviceId: '12345',deviceType: 'mobile');
// //     await _repository.loginDeviceAuth(
// //       headers: {
// //         'Content-Type': 'application/json',
// //       },
// //       requestData: postLoginDeviceAuthReq.toJson()
// //       // {
// //       //   'email':'adnanpk44@gmail.com',
// //       //   'password':'admin123',
// //       //   'device_type':'mobile',
// //       //   'device_id':'12345'
// //       // },
// //     ).then((value) async {
// //      ;
// //       postLoginDeviceAuthResp = value;
// //       print( postLoginDeviceAuthReq.toJson());
// //       _onLoginDeviceAuthSuccess(value, emit);
// //     }).onError((error, stackTrace) {
// //       //implement error call
// //       _onLoginDeviceAuthError();
// //     });
// //   }
// //
// //   void _onLoginDeviceAuthSuccess(
// //       PostLoginDeviceAuthResp resp,
// //       Emitter<LoginState> emit,
// //       ) {
// //     print(resp.success);
// //   }
// //   void _onLoginDeviceAuthError() {
// //
// //     //implement error method body...
// //   }
// // }
// import 'dart:convert';
// import 'package:doctak_app/presentation/login_screen/bloc/login_state.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:http/http.dart' as http;
// import 'login_event.dart';
//
// class LoginBloc extends Bloc<LoginEvent, LoginState> {
//   LoginBloc() : super(LoginInitial());
//
//   @override
//   Stream<LoginState> mapEventToState(LoginEvent event) async* {
//     if (event is LoginButtonPressed) {
//       yield LoginLoading();
//
//       try {
//         // Simulate a network request (in a real app, replace with API call)
//         final response = await http.post(
//           Uri.parse('your_login_api_url'),
//           body: {
//             'email': event.username,
//             'password': event.password,
//           },
//         );
//
//         // Parse the response
//         final data = json.decode(response.body);
//
//         if (response.statusCode == 200) {
//           yield LoginSuccess(username: event.username);
//         } else {
//           yield LoginFailure(error: data['error']);
//         }
//       } catch (e) {
//         yield LoginFailure(error: 'An error occurred');
//       }
//     }
//   }
// }
import 'package:bloc/bloc.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/presentation/login_screen/bloc/login_state.dart';
import 'package:dio/dio.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../core/utils/app/AppData.dart';
import 'login_event.dart';
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService apiService = ApiService(Dio());
  LoginBloc() : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<ChangePasswordVisibilityEvent>(_changePasswordVisibility);
  }
  void _onLoginButtonPressed(LoginButtonPressed event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    ProgressDialogUtils.showProgressDialog();
    try {
      final response = await apiService.login(
        event.username,
        event.password,
        'mobile',
        '123456'
      );
      log(response);
      if (response.success==true) {
        ProgressDialogUtils.hideProgressDialog();
        if (response.user!.emailVerifiedAt == null) {
          // showVerifyMessage(context);
          return;
        }
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response.token??'');
        await prefs.setString('userId', response.user?.id??'');
        await prefs.setString('name', '${response.user?.firstName??''} ${response.user?.lastName??''}');
        await prefs.setString('profile_pic', response.user?.profilePic??'');
        await prefs.setString('email', response.user?.email ?? '');
        await prefs.setString('phone', response.user?.phone ?? '');
        await prefs.setString('background', response.user?.background ?? '');
        await prefs.setString('specialty', response.user?.specialty??'');
        await prefs.setString('licenseNo', response.user?.licenseNo ?? '');
        await prefs.setString('title', response.user?.title ?? '');
        await prefs.setString('city', response.user?.city ?? '');
        await prefs.setString('countryOrigin', response.user?.countryOrigin ?? '');
        await prefs.setString('college', response.user?.college ?? '');
        await prefs.setString('clinicName', response.user?.clinicName ?? '');
        await prefs.setString('dob', response.user?.dob ?? '');
        await prefs.setString('user_type', response.user?.userType ?? '');
        await prefs.setString('countryName',  response.country?.countryName?? '');
        await prefs.setString('currency',  response.country?.currency?? '');
        if(response.university !=null) {
          await prefs.setString('university',  response.university?.name ?? '');
        }
        await prefs.setString('practicingCountry', response.user?.practicingCountry?? '');
        await prefs.setString('gender', response.user?.gender ?? '');
        await prefs.setString('country', response.user?.country??'');
        String? userToken = prefs.getString('token')??'';
        String? userId = prefs.getString('userId')??'';
        String? name = prefs.getString('name')??'';
        String? profile_pic = prefs.getString('profile_pic')??'';
        String? background = prefs.getString('background')??'';
        String? email = prefs.getString('email')??'';
        String? specialty = prefs.getString('specialty')??'';
        String? userType = prefs.getString('user_type')??'';
        String? university = prefs.getString('university') ?? '';
        String? countryName = prefs.getString('country') ?? '';
        String? currency = prefs.getString('currency') ?? '';

        if (userToken != '') {
          AppData.userToken = userToken;
          AppData.logInUserId = userId;
          AppData.name = name;
          AppData.profile_pic = profile_pic;
          AppData.university= university;
          AppData.userType= userType;
          AppData.background = background;
          AppData.email = email;
          AppData.specialty = specialty;
          AppData.countryName = countryName;
          AppData.currency = currency;
        }
         emit(LoginSuccess(username: event.username));
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
  _changePasswordVisibility(
      ChangePasswordVisibilityEvent event,
      Emitter<LoginState> emit,
      ) {
    emit(state.copyWith(isShowPassword: event.value));
  }

}