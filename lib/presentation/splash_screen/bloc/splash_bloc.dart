import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/ads_model/ads_setting_model.dart';
import 'package:doctak_app/data/models/ads_model/ads_type_model.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import '../../../data/models/countries_model/countries_model.dart';
import 'splash_event.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final ApiServiceManager apiManager = ApiServiceManager();

  SplashBloc() : super(CountriesDataInitial()) {
    on<LoadDropdownData>(_listCountryList);
    on<LoadDropdownData1>(_listCountryList1);

    // on<UpdateFirstDropdownValue>(_listCountryList);
    // on<UpdateFirstDropdownValue>(_listCountryList);
  }

  Future<void> _listCountryList(
    LoadDropdownData event,
    Emitter<SplashState> emit,
  ) async {
    var firstDropdownValues = await _onGetCountries();
    // Check if countries data was successfully loaded
    if (firstDropdownValues != null) {
      // print("DD ${firstDropdownValues.countries!}");
      firstDropdownValues.countries?.add(
        Countries(
          id: -1,
          countryName: 'Select Country',
          createdAt: '',
          updatedAt: '',
          isRegistered: '',
          countryCode: '',
          countryMask: '',
          currency: '',
          flag: 'Select Country',
        ),
      );
      getNewDeviceToken();
      emit(
        CountriesDataLoaded(
          countriesModel: firstDropdownValues,
          countryFlag: event.countryFlag,
          typeValue: event.typeValue,
          searchTerms: event.searchTerms,
        ),
      );
    }
    // If firstDropdownValues is null, _onGetCountries already emitted an error state
    // add(LoadDropdownData(event.newValue,event.typeValue));
  }

  /// Safely get FCM token with retry logic for FIS_AUTH_ERROR
  Future<String?> _getSafeFcmToken() async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } catch (e) {
        debugPrint("FCM token attempt $attempt failed: $e");

        if (e.toString().contains('FIS_AUTH_ERROR')) {
          try {
            await FirebaseMessaging.instance.deleteToken();
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (_) {}
        }

        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }
    return null;
  }

  getNewDeviceToken() async {
    try {
      // Ensure Firebase is initialized before getting token
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase not initialized, skipping device token update');
        return;
      }

      final token = await _getSafeFcmToken();
      if (token == null) {
        debugPrint('FCM token is null after all retries');
        return;
      }

      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      String deviceId = '';
      String deviceType = '';
      if (Platform.isAndroid) {
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
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      String deviceToken = await prefs.getString('device_token') ?? '';

      if (deviceToken.isNotEmpty && deviceToken != token) {
        try {
          print("new Token $token");
          Dio dio = Dio();
          try {
            Response response = await dio.post(
              '${AppData.remoteUrl}/update-token', // Add query parameters
              data: FormData.fromMap({
                'device_id': deviceId,
                'device_type': deviceType,
                'user_id': AppData.logInUserId,
                'device_token': token,
              }),
              options: Options(
                headers: {
                  'Authorization': 'Bearer ${AppData.userToken}', // Set headers
                },
              ),
            );

            print("response ${response.data}");
          } catch (e) {
            print('Error: $e');
          }
          // emit(DataLoaded(drugsData));
        } catch (e) {
          // ProgressDialogUtils.hideProgressDialog();
          print(e);
        }
      }
    } catch (e) {
      debugPrint('Error getting device token: $e');
      // Continue without token - app should still work
    }
  }

  Future<CountriesModel?> _onGetCountries() async {
    // emit(DataLoading());
    try {
      final response = await apiManager.getCountries().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Countries API call timed out');
          throw TimeoutException('Failed to load countries in time');
        },
      );
      // print(response.countries!.length.toString());
      // if (response.countries!.isNotEmpty) {
      // emit(DataSuccess(countriesModel: response));
      // List<String> list = [];
      // list.add('Select Country');
      // for (var element in response.countries!) {
      //   list.add(element.countryName!);
      // }
      return response;
      // } else {
      //   return [];
      //   emit(DataFailure(error: 'Failed to load data'));
      // }
    } catch (e) {
      print('Error loading countries: $e');
      // Don't emit here, will be handled in event handler
      return null; // Explicitly return null when an error occurs
    }
  }

  Future<void> _listCountryList1(
    LoadDropdownData1 event,
    Emitter<SplashState> emit,
  ) async {
    try {
      final response = await apiManager
          .getConferenceCountries('Bearer ${AppData.userToken}')
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Conference countries API call timed out');
              throw TimeoutException('Failed to load conference countries');
            },
          );
      print(response.data);
      List<dynamic> data = response.data['countries'];
      emit(
        CountriesDataLoaded1(
          countriesModelList: data,
          countryName: event.countryName,
          searchTerms: event.searchTerms,
        ),
      );
      // add(LoadDropdownData(event.newValue,event.typeValue));
    } catch (e) {
      print('Error loading conference countries: $e');
      emit(CountriesDataError('$e'));
    }
  }
}
