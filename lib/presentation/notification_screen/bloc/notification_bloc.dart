import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_state.dart';
import 'package:doctak_app/presentation/notification_screen/notifications_provider.dart';
import 'package:equatable/equatable.dart';
import '../../../core/utils/app/AppData.dart';
import '../../../data/models/notification_model/notification_model.dart';
import 'notification_event.dart';


class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiService postService = ApiService(Dio());
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Data> notificationsList = [];
  int totalNotifications=0;
  NotificationsModel notificationsModel = NotificationsModel();
  final int nextPageTrigger = 1;

  NotificationBloc() : super(PaginationInitialState()) {
    on<NotificationLoadPageEvent>(_onGetNotification);
    on<GetPost>(_onGetNotification1);
    on<NotificationDetailPageEvent>(_onGetJobDetail);
    on<NotificationCheckIfNeedMoreDataEvent>((event, emit) async {
      // emit(PaginationLoadingState());
      if (event.index == notificationsList.length - nextPageTrigger) {
        add(NotificationLoadPageEvent(page: pageNumber));
      }
    });
  }

  _onGetNotification(NotificationLoadPageEvent event, Emitter<NotificationState> emit) async {
    // emit(DrugsDataInitial());

    if (event.page == 1) {
      print('object clear');
      notificationsList.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
    }
    // ProgressDialogUtils.showProgressDialog();
    // try {
    NotificationsModel response = await postService.getMyNotifications(
        'Bearer ${AppData.userToken}',
        '$pageNumber',
    );
    numberOfPage = response.notifications?.lastPage ?? 0;
    if (pageNumber < numberOfPage + 1) {
      pageNumber = pageNumber + 1;
      notificationsList.addAll(response.notifications?.data?? []);
    }
    totalNotifications=notificationsList.where((e)=>e.isRead!=1).length;
    print(totalNotifications);

    emit(PaginationLoadedState());

    // emit(DataLoaded(notificationsList));
    // } catch (e) {
    //   print(e);
    //
    //   // emit(PaginationLoadedState());
    //
    //   emit(DataError('No Data Found'));
    // }
  }

  _onGetJobDetail(NotificationDetailPageEvent event, Emitter<NotificationState> emit) async {
    emit(PaginationLoadingState());
    // try {
    // JobDetailModel response = await postService.getJobsDetails(
    //     'Bearer ${AppData.userToken}', event.jobId.toString());
    // jobDetailModel = response;
    // emit(PaginationLoadedState());
    // emit(DataLoaded(notificationsList));
    // } catch (e) {
    //   print(e);
    //
    //   // emit(PaginationLoadedState());
    //
    //   emit(DataError('No Data Found'));
    // }
  }

  _onGetNotification1(GetPost event, Emitter<NotificationState> emit) async {
    // emit(PaginationInitialState());
    // ProgressDialogUtils.showProgressDialog();

    // emit(PaginationLoadingState());
    // try {
    //   JobsModel response = await postService.getJobsList(
    //       'Bearer ${AppData.userToken}',
    //       "1",
    //       event.countryId,
    //       event.searchTerm,
    //       'false');
    //   print("ddd${response.jobs?.data!.length}");
    //   notificationsList.clear();
    //   notificationsList.addAll(response.jobs?.data ?? []);
    //   emit(PaginationLoadedState());
    //   // emit(DataLoaded(notificationsList));
    // } catch (e) {
    //   // ProgressDialogUtils.hideProgressDialog();
    //   print(e);
    //
    //   emit(DataError('No Data Found'));
    // }
  }
}
