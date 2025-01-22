import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/ads_model/ads_setting_model.dart';
import 'package:doctak_app/data/models/ads_model/ads_type_model.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../data/models/countries_model/countries_model.dart';
import 'splash_event.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final ApiService postService = ApiService(Dio());

  SplashBloc() : super(CountriesDataInitial()) {
    on<LoadDropdownData>(_listCountryList);
    on<LoadDropdownData1>(_listCountryList1);

    // on<UpdateFirstDropdownValue>(_listCountryList);
    // on<UpdateFirstDropdownValue>(_listCountryList);
  }

  Future<void> _listCountryList(
      LoadDropdownData event, Emitter<SplashState> emit) async {
    var firstDropdownValues = await _onGetCountries();
    // print("DD ${firstDropdownValues!.countries!}");
    firstDropdownValues?.countries?.add(Countries(
      id: -1,
      countryName:'Select Country',
      createdAt:'',
      updatedAt:'',
      isRegistered:'',
      countryCode:'',
      countryMask:'',
      currency:'',
      flag:'Select Country',
    ));
    getNewDeviceToken();
    emit(CountriesDataLoaded(
        countriesModel: firstDropdownValues!,
        countryFlag: event.countryFlag,
        typeValue: event.typeValue,
        searchTerms: event.searchTerms));
    // add(LoadDropdownData(event.newValue,event.typeValue));
  }
  getNewDeviceToken() async {
    await FirebaseMessaging.instance.getToken().then((token) async {
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String deviceToken = await prefs.getString('device_token') ?? '';

      if (deviceToken.isNotEmpty && deviceToken != token) {
        try {
          print("new Token $token");
          Dio dio = Dio();
          try {
            Response response = await dio.post(
              '${AppData.remoteUrl}/update-token', // Add query parameters
              data: FormData.fromMap({
                'device_id':deviceId,
                'device_type':deviceType,
                'user_id':AppData.logInUserId,
                'device_token':token,
              }),
              options: Options(headers: {
                'Authorization': 'Bearer ${AppData.userToken}',  // Set headers
              }),
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
    });
  }

  Future<CountriesModel?> _onGetCountries() async {
    // emit(DataLoading());
    try {
      final response = await postService.getCountries();
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
      print(e);
      emit(CountriesDataError('An error occurred'));
    }
  }
  Future<void> _listCountryList1(
      LoadDropdownData1 event, Emitter<SplashState> emit) async {
    // try {
      final response = await postService.getConferenceCountries(
        'Bearer ${AppData.userToken}',
      );
      print('data get ${response.data['countries']}');
     List<dynamic> data= response.data['countries'];
      emit(CountriesDataLoaded1(
          countriesModelList:data,
          countryName: event.countryName,
          searchTerms: event.searchTerms));
      // add(LoadDropdownData(event.newValue,event.typeValue));
    // } catch (e) {
    //   emit(CountriesDataError('$e'));
    // }
  }
}
