import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart';

import '/core/app_export.dart';

part 'sign_up_event.dart';

part 'sign_up_state.dart';

/// A bloc that manages the state of a SignUp according to the event that is dispatched to it.

class DropdownBloc extends Bloc<DropdownEvent, DropdownState> {
  final ApiService apiService = ApiService(Dio());
  bool isVisiblePassword = false;
  bool isDoctorRole = true;

  DropdownBloc() : super(DropdownInitial()) {
    // Register the event handler for LoadDropdownValues
    // on<LoadDropdownValues>((event, emit) async {
    //   try {
    //     // Simulate fetching dynamic values from an API or other source
    //     List<String>? firstDropdownValues = await _onGetCountries();
    //     emit(DropdownLoaded(
    //       firstDropdownValues!,
    //       firstDropdownValues.first,
    //       [],
    //       'Select Country',
    //     ));
    //   } catch (e) {
    //     emit(DropdownError('Failed to load dropdown values'));
    //   }
    // });
    // Register the event handler for UpdateSecondDropdownValues
    // on<UpdateSecondDropdownValues>((event, emit) async {
    //   // Simulate fetching second dropdown values based on the first dropdown selection
    //   List<String> secondDropdownValues = await _onGetStates(event.selectedFirstDropdownValue);
    //   emit(DropdownLoaded(
    //     (state as DropdownLoaded).firstDropdownValues,
    //     (state as DropdownLoaded).selectedFirstDropdownValue,
    //     secondDropdownValues,
    //     secondDropdownValues.first,
    //   ));
    // });
    on<LoadDropdownValues>(_loadDropdownValues);
    // on<UpdateFirstDropdownValue>(_updateFirstDropdownValue);
    // on<UpdateSecondDropdownValues>(_updateSecondDropdownValues);
    // on<UpdateSpecialtyDropdownValue>(_updateSpecialtyDropdownValues);
    // on<UpdateUniversityDropdownValues>(_updateUniversityDropdownValues);
    on<TogglePasswordVisibility>(_changePasswordVisibility);
    on<ChangeDoctorRole>(_changeDoctorRole);
    on<SignUpButtonPressed>(_onSignUpButtonPressed);
    // on<Check>(_changePasswordVisibility);
  }

  void _updateFirstDropdownValue(
      UpdateFirstDropdownValue event, Emitter<DropdownState> emit) {
    emit(DropdownLoaded(
      (state as DropdownLoaded).firstDropdownValues,
      event.newValue,
      [],
      'Select State',
      (state as DropdownLoaded).specialtyDropdownValue,
      'select Specialty',
      [],
      '',
      false,
      (state as DropdownLoaded).isDoctorRole,
    ));
    print("DD ${event.newValue}");
    add(UpdateSecondDropdownValues(event.newValue));
  }

  void _loadDropdownValues(
      LoadDropdownValues event, Emitter<DropdownState> emit) async {
    try {
      // Simulate fetching dynamic values from an API or other source
      emit(DataLoaded(false, true));
      print('daa');
    } catch (e) {
      emit(DropdownError('Failed to load dropdown values1'));
    }
  }

  // void _updateSecondDropdownValues(UpdateSecondDropdownValues event,
  //     Emitter<DropdownState> emit) async {
  //   // Simulate fetching second dropdown values based on the first dropdown selection
  //   List<String> secondDropdownValues = await _onGetStates(
  //       event.selectedFirstDropdownValue);
  //   List<String>? universityDropdownValues = await _onGetUniversities(
  //       secondDropdownValues!.first);
  //   // log(universityDropdownValues!.toList().toString());
  //   emit(DropdownLoaded(
  //     (state as DropdownLoaded).firstDropdownValues,
  //     (state as DropdownLoaded).selectedFirstDropdownValue,
  //     secondDropdownValues,
  //     secondDropdownValues.first,
  //     (state as DropdownLoaded).specialtyDropdownValue,
  //     (state as DropdownLoaded).selectedSpecialtyDropdownValue,
  //     [],
  //     '',
  //     !(state as DropdownLoaded).isPasswordVisible,
  //     (state as DropdownLoaded).isDoctorRole,
  //   ));
  //   print("DD ${secondDropdownValues.first}");
  // }

  // void _updateUniversityDropdownValues(UpdateUniversityDropdownValues event,
  //     Emitter<DropdownState> emit) async {
  //   // Simulate fetching second dropdown values based on the first dropdown selection
  //   List<String>? secondDropdownValues = await _onGetUniversities(
  //       event.selectedStateDropdownValue);
  //   emit(DropdownLoaded(
  //     (state as DropdownLoaded).firstDropdownValues,
  //     (state as DropdownLoaded).selectedFirstDropdownValue,
  //     (state as DropdownLoaded).secondDropdownValues,
  //     (state as DropdownLoaded).selectedSecondDropdownValue,
  //     (state as DropdownLoaded).specialtyDropdownValue,
  //     (state as DropdownLoaded).selectedSpecialtyDropdownValue,
  //     secondDropdownValues ?? [],
  //     secondDropdownValues?.first == '' ? ' ' : secondDropdownValues?.first,
  //     !(state as DropdownLoaded).isPasswordVisible,
  //     (state as DropdownLoaded).isDoctorRole,
  //   ));
  // }
  //
  // void _updateSpecialtyDropdownValues(UpdateSpecialtyDropdownValue event,
  //     Emitter<DropdownState> emit) async {
  //   // Simulate fetching second dropdown values based on the first dropdown selection
  //   List<String>? secondDropdownValues = await _onGetSpecialty();
  //   emit(DropdownLoaded(
  //     (state as DropdownLoaded).firstDropdownValues,
  //     (state as DropdownLoaded).selectedFirstDropdownValue,
  //     (state as DropdownLoaded).secondDropdownValues,
  //     (state as DropdownLoaded).selectedSecondDropdownValue,
  //     secondDropdownValues!,
  //     secondDropdownValues.first,
  //     [],
  //     '',
  //     !(state as DropdownLoaded).isPasswordVisible,
  //     (state as DropdownLoaded).isDoctorRole,
  //   ));
  // }

  void _changePasswordVisibility(
      TogglePasswordVisibility event, Emitter<DropdownState> emit) {
    emit(DataLoaded(
      !(state as DataLoaded).isPasswordVisible,
      (state as DataLoaded).isDoctorRole,
    ));
  }

  void _changeDoctorRole(ChangeDoctorRole event, Emitter<DropdownState> emit) {
    emit(DataLoaded(
      !(state as DataLoaded).isPasswordVisible,
      (state as DataLoaded).isDoctorRole,
    ));
  }

  // @override
  // Stream<DropdownState> mapEventToState(DropdownEvent event) async* {
  //   if (event is LoadDropdownValues) {
  //     try {
  //       // Simulate fetching dynamic values from an API or other source
  //       List<String>? firstDropdownValues = await _onGetCountries();
  //       List<String>? specialtyDropdownValues = await _onGetSpecialty();
  //       yield DropdownLoaded(
  //           firstDropdownValues!,
  //           firstDropdownValues.first,
  //           [],
  //           'select States',
  //           specialtyDropdownValues!,
  //           specialtyDropdownValues.first,
  //           [],
  //           ' Select University',
  //           false,
  //           (state as DropdownLoaded).isDoctorRole
  //       );
  //     } catch (e) {
  //       yield DropdownError('Failed to load dropdown valuess');
  //     }
  //   } else if (event is UpdateFirstDropdownValue) {
  //     yield DropdownLoaded(
  //       (state as DropdownLoaded).firstDropdownValues,
  //       event.newValue,
  //       (state as DropdownLoaded).secondDropdownValues,
  //       'Select country',
  //       (state as DropdownLoaded).specialtyDropdownValue,
  //       '',
  //       (state as DropdownLoaded).universityDropdownValue,
  //       (state as DropdownLoaded).selectedUniversityDropdownValue,
  //       false,
  //       (state as DropdownLoaded).isDoctorRole,
  //
  //       // DropdownItem(0, 'Select Second Dropdown'),
  //     );
  //     print("123" + event.newValue);
  //
  //     add(UpdateSecondDropdownValues(event.newValue));
  //   } else if (event is UpdateSecondDropdownValues) {
  //     // Simulate fetching second dropdown values based on the selection made in the first dropdown
  //     List<String>? secondDropdownValues = await _onGetStates(
  //         event.selectedFirstDropdownValue);
  //     yield DropdownLoaded(
  //         (state as DropdownLoaded).firstDropdownValues,
  //         (state as DropdownLoaded).selectedFirstDropdownValue,
  //         secondDropdownValues!,
  //         secondDropdownValues.first,
  //         (state as DropdownLoaded).specialtyDropdownValue,
  //         (state as DropdownLoaded).selectedSpecialtyDropdownValue,
  //         (state as DropdownLoaded).universityDropdownValue,
  //         (state as DropdownLoaded).selectedUniversityDropdownValue,
  //         false,
  //         (state as DropdownLoaded).isDoctorRole
  //     );
  //     print("123" + event.selectedFirstDropdownValue);
  //     add(UpdateUniversityDropdownValues(event.selectedFirstDropdownValue));
  //   } else if (event is UpdateUniversityDropdownValues) {
  //     yield DropdownLoaded(
  //         (state as DropdownLoaded).firstDropdownValues,
  //         (state as DropdownLoaded).selectedFirstDropdownValue,
  //         (state as DropdownLoaded).secondDropdownValues,
  //         (state as DropdownLoaded).selectedSecondDropdownValue,
  //         (state as DropdownLoaded).specialtyDropdownValue,
  //         (state as DropdownLoaded).selectedSpecialtyDropdownValue,
  //         (state as DropdownLoaded).universityDropdownValue,
  //         (state as DropdownLoaded).selectedUniversityDropdownValue,
  //         false,
  //         (state as DropdownLoaded).isDoctorRole);
  //   }
  // }

  Future<List<String>?> _onGetCountries() async {
    // emit(DataLoading());
    try {
      final response = await apiService.getCountries();
      print(response.countries!.length.toString());
      if (response.countries!.isNotEmpty) {
        // emit(DataSuccess(countriesModel: response));
        List<String> list = [];
        // list.add('Select Country');
        for (var element in response.countries!) {
          list.add(element.countryName!);
        }
        return list;
      } else {
        return [];
        // emit(DataFailure(error: 'Failed to load data'));
      }
    } catch (e) {
      print(e);
      // emit(DataFailure(error: 'An error occurred'));
    }
  }

  Future<List<String>?> _onGetSpecialty() async {
    // emit(DataLoading());
    try {
      final response = await apiService.getSpecialty();
      if (response.data!.isNotEmpty) {
        // emit(DataSuccess(countriesModel: response));
        List<String> list = [];
        list.add('select Specialty');
        response.data!.forEach((element) {
          list.add(element['name']!);
        });
        return list;
      } else {
        return [];
        // emit(DataFailure(error: 'Failed to load data'));
      }
    } catch (e) {
      print(e);
      // emit(DataFailure(error: 'An error occurred'));
    }
  }

  _onGetStates(String value) async {
    // emit(DataLoading());
    try {
      final response = await apiService.getStates(value);
      // if (response.data!.isNotEmpty) {
      // emit(DataSuccess(countriesModel: response));
      List<String> list = [];
      response.data!.forEach((element) {
        list.add(element['state_name']!);
      });
      return list;
    } catch (e) {
      print(e);
      // emit(DataFailure(error: 'An error occurred'));
    }
  }

  Future<List<String>>? _onGetUniversities(String value) async {
    // emit(DataLoading());
    try {
      final response = await apiService.getUniversityByStates(value);
      print(response.data);
      // if (response.data!.isNotEmpty) {
      // emit(DataSuccess(countriesModel: response));
      log('response ${response.data}');
      List<String> list = [];
      // list.clear();
      // list.add('Add new University');
      response.data?.forEach((element) {
        if (element['name'] != null) {
          list.add(element['name']!);
        }
      });
      return list;
      // } else {
      //   return [];
      //   // emit(DataFailure(error: 'Failed to load data'));
      // }
    } catch (e) {
      return [];
      print(e);
      // emit(DataFailure(error: 'An error occurred'));
    }
  }

  void _onSignUpButtonPressed(SignUpButtonPressed event, Emitter<DropdownState> emit) async {
    ProgressDialogUtils.showProgressDialog();
    try {
      print(event.firstName);
      final response = await apiService.register(
          event.firstName, event.lastName,event.username, event.password, event.userType);
      if (response.response.statusCode == 200) {
        // print('rese ${JsonEncoder(response.data['message'])}');
        ProgressDialogUtils.hideProgressDialog();
        // var data=JsonDecoder(response.response.data);
        // var d=jsonEncode(data);
        // print(data);
        print('rese ${response.response.data}');

        emit(DropdownLoaded1(response: response.response.data));
      } else {
        emit(DropdownLoaded1(response: response.response.data));
        print('rese ${response.response.data}');
        ProgressDialogUtils.hideProgressDialog();
        // emit(LoginFailure(error: 'Invalid credentials'));
      }
    } catch (e) {
      print(e);
      emit(DropdownLoaded1(response: ''));

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
