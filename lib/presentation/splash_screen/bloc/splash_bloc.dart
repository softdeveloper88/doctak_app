import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_state.dart';
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

  Future<void> _listCountryList(LoadDropdownData event,
      Emitter<SplashState> emit) async {
    var firstDropdownValues = await _onGetCountries();
    print("DD ${firstDropdownValues!.countries!}");
    emit(CountriesDataLoaded(countriesModel: firstDropdownValues,
        countryFlag: event.countryFlag,
        typeValue: event.typeValue,
        searchTerms: event.searchTerms));
    // add(LoadDropdownData(event.newValue,event.typeValue));
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

  Future<void> _listCountryList1(LoadDropdownData1 event,
      Emitter<SplashState> emit) async {
    try {
      final response = await postService.getConferenceCountries(
        'Bearer ${AppData.userToken}',
      );
      print('333s${response.data['countries']}');

      emit(CountriesDataLoaded1(countriesModelList: response.data['countries'],
          countryName: event.countryName,
          searchTerms: event.searchTerms));
      // add(LoadDropdownData(event.newValue,event.typeValue));
    } catch (e) {
      // emit(CountriesDataError('$e'));
    }
  }
}