import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/anousment_model/announcement_detail_model.dart';
import 'package:doctak_app/data/models/anousment_model/announcement_model.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_state.dart';
import 'package:doctak_app/presentation/notification_screen/notifications_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app/AppData.dart';
import '../../../data/models/notification_model/notification_model.dart';
import 'notification_event.dart';


class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiService postService = ApiService(Dio());
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Data> notificationsList = [];
  AnnouncementModel? announcementModel;
  AnnouncementDetailModel? announcementDetailModel;
  int totalNotifications=0;
  NotificationModel? notificationsModel;
  final int nextPageTrigger = 1;
  String emailVerified='';
  NotificationBloc() : super(PaginationInitialState()) {
    on<NotificationLoadPageEvent>(_onGetNotification);
    on<GetPost>(_onGetNotification1);
    on<NotificationDetailPageEvent>(_onGetJobDetail);
    on<AnnouncementEvent>(_getAnnouncement);
    on<AnnouncementDetailEvent>(_getAnnouncementDetail);
    on<NotificationCounter>(_counterNotification);
    on<ReadNotificationEvent>(_readNotification);
    on<NotificationCheckIfNeedMoreDataEvent>((event, emit) async {
      // emit(PaginationLoadingState());
      if (event.index == notificationsList.length - nextPageTrigger) {
        print('length ${notificationsList.length}');
        add(NotificationLoadPageEvent(page: pageNumber,readStatus: ''));

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
    try {
    NotificationModel response;
    print('status ${event.readStatus}');

    if(event.readStatus=='') {
       response = await postService.getMyNotifications(
        'Bearer ${AppData.userToken}',
        '$pageNumber',
      );
       print(response.toJson());
       numberOfPage = response.notifications?.lastPage ?? 0;
       if (pageNumber < numberOfPage + 1) {
         pageNumber = pageNumber + 1;
         notificationsList.addAll(response.notifications?.data?? []);
       }


    }else if(event.readStatus=='mark-read'){
      var response = await postService.readAllSelectedNotifications(
          'Bearer ${AppData.userToken}',

      );
      // notificationsModel.notifications?.data. where((e)=>e.isRead==1)=0;
      print(response.data);

    }

    emit(PaginationLoadedState());

    // emit(DataLoaded(notificationsList));
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState());

      emit(DataError('No Data Found'));
    }
  }
  _readNotification(ReadNotificationEvent event, Emitter<NotificationState> emit) async {
    // emit(DrugsDataInitial());

    // ProgressDialogUtils.showProgressDialog();
    try {


     var response = await postService.readNotification(
        'Bearer ${AppData.userToken}',
        event.notificationId??""
      );

     // totalNotifications=notificationsList.where((e)=>e.isRead!=1).length;
    if(totalNotifications>0) {
      totalNotifications = -1;

      notificationsModel?.notifications?.data?[notificationsList.indexWhere((
          e) => e.id.toString() == event.notificationId)].isRead = 1;
    }
    emit(PaginationLoadedState());

    // emit(DataLoaded(notificationsList));
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState());

      emit(DataError('No Data Found'));
    }
  }
  _counterNotification(NotificationCounter event, Emitter<NotificationState> emit) async {
    // emit(DrugsDataInitial());

    // ProgressDialogUtils.showProgressDialog();
    try {

    Dio dio = Dio();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    var response = await dio.get(
      '${AppData.remoteUrl}/notifications/unread/count', // Add query parameters
      options: Options(headers: {
        'Authorization': 'Bearer ${AppData.userToken}',  // Set headers
      }),
    );
    if((prefs.getString('email_verified_at')??'')=='') {
      var response2 = await dio.post(
        '${AppData.remoteUrl2}/check-email-verified', // Add query parameters
        options: Options(headers: {
          'Authorization': 'Bearer ${AppData.userToken}', // Set headers
        }),
      );
      if (response2.statusCode == 200) {
        print("check email verified");
        emailVerified= response2.data['email_verified_at'];
        prefs.setString('email_verified_at', response2.data['email_verified_at']??'');
      }else{
        print("check email verified not");

      }
    }
    totalNotifications=response.data['unread_count'].toInt();
    print('totalNotifications  $totalNotifications');

   // notificationsModel.notifications?.data?[notificationsList.indexWhere((e)=>e.id.toString()==event.notificationId)].isRead=1;

    emit(PaginationLoadedState());

    // emit(DataLoaded(notificationsList));
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState());

      emit(DataError('No Data Found'));
    }
  }
 _getAnnouncement(AnnouncementEvent event, Emitter<NotificationState> emit) async {
    // emit(DrugsDataInitial());
   emit(PaginationLoadingState());

    // ProgressDialogUtils.showProgressDialog();
    try {

    Dio dio = Dio();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    Response response = await dio.get(
      '${AppData.remoteUrl2}/announcement', // Add query parameters
      options: Options(headers: {
        'Authorization': 'Bearer ${AppData.userToken}',  // Set headers
      }),
    );

     announcementModel=AnnouncementModel.fromJson(response.data);

    print('${announcementModel?.toJson()}');

     emit(PaginationLoadedState());

    // emit(DataLoaded(notificationsList));
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState());

      emit(DataError('No Data Found'));
    }
  }
  _getAnnouncementDetail(AnnouncementDetailEvent event, Emitter<NotificationState> emit) async {
    // emit(DrugsDataInitial());
    emit(PaginationLoadingState());

    // ProgressDialogUtils.showProgressDialog();
    try {

    Dio dio = Dio();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    Response response = await dio.get(
      '${AppData.remoteUrl2}/announcements/${event.announcementId}', // Add query parameters
      options: Options(headers: {
        'Authorization': 'Bearer ${AppData.userToken}',  // Set headers
      }),
    );

    announcementDetailModel=AnnouncementDetailModel.fromJson(response.data);

     emit(PaginationLoadedState());

    // emit(DataLoaded(notificationsList));
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState());

      emit(DataError('No Data Found'));
    }
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
