import 'package:dio/dio.dart';
import 'package:doctak_app/core/errors/failures.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/conference_model/search_conference_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'conference_event.dart';
import 'conference_state.dart';


class ConferenceBloc extends Bloc<ConferenceEvent, ConferenceState> {
  final ApiService postService = ApiService(Dio());
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Data> conferenceList = [];
  final int nextPageTrigger = 1;

  ConferenceBloc() : super(PaginationInitialState()) {
    on<LoadPageEvent>(_onGetJobs);
    // on<GetConferences>(_onGetJobs1);
    on<LoadDropdownData>(_listCountryList);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      // emit(PaginationLoadingState());
      if (event.index == conferenceList.length - nextPageTrigger) {
        add(LoadPageEvent(page: pageNumber));
      }
    });
  }
  _onGetJobs(LoadPageEvent event, Emitter<ConferenceState> emit) async {
    // emit(DrugsDataInitial());
    print('33 ${event.page}');
    if (event.page == 1) {
      conferenceList.clear();
      pageNumber=1;
      emit(PaginationLoadingState());
      print(event.countryName);
      print(event.searchTerm);
    }
    // ProgressDialogUtils.showProgressDialog();
    try {
      SearchConferenceModel response = await postService.searchConferences(
          'Bearer ${AppData.userToken}',
          '${pageNumber}',
          event.countryName??"Pakistan",
          event.searchTerm??'');
      numberOfPage = response.conferences?.lastPage ?? 0;
      if (pageNumber < numberOfPage+1) {
        pageNumber = pageNumber + 1;
        conferenceList.addAll(response.conferences?.data ?? []);
      }
      emit(PaginationLoadedState());

      // emit(DataLoaded(conferenceList));
    } catch (e) {
      print(e);

      emit(PaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }

  // _onGetJobs1(GetConferences event, Emitter<ConferenceState> emit) async {
  //   // emit(PaginationInitialState());
  //   // ProgressDialogUtils.showProgressDialog();
  //   // emit(PaginationLoadingState());
  //   try {
  //     final response = await postService.searchConferences(
  //         'Bearer ${AppData.userToken}',
  //         "1",
  //         "USA",
  //         event.searchTerm);
  //     // print("ddd${response.data?.data!.length}");
  //     conferenceList.clear();
  //     conferenceList.addAll(response.conferences?.data ?? []);
  //     emit(PaginationLoadedState());
  //     // emit(DataLoaded(conferenceList));
  //   } catch (e) {
  //     // ProgressDialogUtils.hideProgressDialog();
  //     print(e);
  //
  //     emit(DataError('No Data Found'));
  //   }
  // }
  Future<void> _listCountryList(LoadDropdownData event, Emitter<ConferenceState> emit) async {
    try {
      final response = await postService.getConferenceCountries(
        'Bearer ${AppData.userToken}',
      );
     print('333s${response.data['countries']}');

      emit(CountriesDataLoaded(countriesModel:response.data['countries'],
          countryName: event.countryName,
          searchTerms: event.searchTerms));
      // add(LoadDropdownData(event.newValue,event.typeValue));
    }catch(e){
      emit(DataError('$e'));
    }
  }

  // Future<List<String>> _onGetCountries() async {
  //   // emit(DataLoading());
  //   try {
  //     final response = await postService.getConferenceCountries(
  //       'Bearer ${AppData.userToken}',
  //     );
  //
  //     return response.data;
  //
  //   } catch (e) {
  //     print(e);
  //     emit(DataError( 'An error occurred'));
  //   }
  // }

}
