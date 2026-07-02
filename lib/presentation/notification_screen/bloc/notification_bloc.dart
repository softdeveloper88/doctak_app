import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/notification_counter_service.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/anousment_model/announcement_detail_model.dart';
import 'package:doctak_app/data/models/anousment_model/announcement_model.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_state.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:stream_transform/stream_transform.dart';
import 'dart:async';
import '../../../core/utils/app/AppData.dart';
import '../../../data/models/notification_model/notification_model.dart';
import '../../../data/apiClient/services/network_api_service.dart';
import 'notification_event.dart';

/// Debounce transformer to prevent rapid event firing
EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  final NetworkApiService _networkApi = NetworkApiService();
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Data> notificationsList = [];
  AnnouncementModel? announcementModel;
  AnnouncementDetailModel? announcementDetailModel;
  int totalNotifications = 0;
  NotificationModel? notificationsModel;
  final int nextPageTrigger = 1;
  String emailVerified = '';
  String activeFilter = ''; // '' = all, 'unread' = unread only
  bool isLoadingMore = false;
  bool hasCompletedInitialLoad = false;
  StreamSubscription<int>? _counterSubscription;

  NotificationBloc() : super(const PaginationLoadingState()) {
    on<NotificationLoadPageEvent>(_onGetNotification);
    on<GetPost>(_onGetNotification1);
    on<NotificationDetailPageEvent>(_onGetJobDetail);
    on<AnnouncementEvent>(_getAnnouncement);
    on<AnnouncementDetailEvent>(_getAnnouncementDetail);
    on<NotificationCounter>(_counterNotification);
    on<ReadNotificationEvent>(_readNotification);
    on<AcceptConnectionRequestEvent>(_acceptConnection);
    on<DeclineConnectionRequestEvent>(_declineConnection);
    on<NotificationCheckIfNeedMoreDataEvent>((event, emit) async {
      if (isLoadingMore) return;
      if (pageNumber > numberOfPage) return;
      if (event.index == notificationsList.length - nextPageTrigger) {
        isLoadingMore = true;
        emit(_loadedState(loadingMore: true));
        add(NotificationLoadPageEvent(page: pageNumber, readStatus: activeFilter));
      }
    });

    _counterSubscription =
        NotificationCounterService().countStream.listen((count) {
      totalNotifications = count;
      if (!hasCompletedInitialLoad) {
        return;
      }
      if (count > 0 &&
          notificationsList.isEmpty &&
          state is! PaginationLoadingState) {
        add(NotificationLoadPageEvent(page: 1, readStatus: activeFilter));
        return;
      }
      if (state is! PaginationLoadingState) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(_loadedState());
      }
    });
  }

  PaginationLoadedState _loadedState({bool? loadingMore}) {
    return PaginationLoadedState(
      notificationCount: totalNotifications,
      itemCount: notificationsList.length,
      isLoadingMore: loadingMore ?? isLoadingMore,
    );
  }

  @override
  Future<void> close() {
    _counterSubscription?.cancel();
    return super.close();
  }

  Future<void> _onGetNotification(
    NotificationLoadPageEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final isFirstPage = event.page == 1;
    final filter = event.readStatus ?? activeFilter;

    if (isFirstPage) {
      notificationsList.clear();
      pageNumber = 1;
      numberOfPage = 1;
      activeFilter = filter;
      isLoadingMore = false;
      emit(PaginationLoadingState());
    }

    try {
      if (event.readStatus == 'mark-read') {
        await apiManager.readAllSelectedNotifications(
          'Bearer ${AppData.userToken}',
        );
        for (var n in notificationsList) {
          n.isRead = 1;
        }
        totalNotifications = 0;
        NotificationCounterService().reset();
        isLoadingMore = false;
        hasCompletedInitialLoad = true;
        emit(_loadedState());
        return;
      }

      final pageToFetch = isFirstPage ? 1 : (event.page ?? pageNumber);
      final apiFilter = filter == 'unread' ? 'unread' : null;
      var response = await apiManager.getMyNotifications(
        'Bearer ${AppData.userToken}',
        '$pageToFetch',
        filter: apiFilter,
      ) as NotificationModel;

      var items = response.notifications?.data ?? [];

      // If unread filter returns nothing but the badge still shows unread,
      // fall back to loading all and filtering client-side.
      if (isFirstPage &&
          filter == 'unread' &&
          items.isEmpty &&
          (response.unreadCount ?? 0) > 0) {
        final allResponse = await apiManager.getMyNotifications(
          'Bearer ${AppData.userToken}',
          '1',
        ) as NotificationModel;
        items = (allResponse.notifications?.data ?? [])
            .where((item) => item.isUnread)
            .toList();
        if (items.isNotEmpty) {
          response = allResponse;
        }
      }

      notificationsModel = response;
      numberOfPage = response.notifications?.lastPage ?? 1;
      if (isFirstPage) {
        notificationsList
          ..clear()
          ..addAll(items);
      } else {
        notificationsList.addAll(items);
      }
      if (response.unreadCount != null) {
        totalNotifications = response.unreadCount!;
        NotificationCounterService().setCount(totalNotifications);
      }

      pageNumber = pageToFetch + 1;
      hasCompletedInitialLoad = true;

      isLoadingMore = false;
      emit(_loadedState());
    } catch (e) {
      print(e);
      isLoadingMore = false;
      hasCompletedInitialLoad = true;
      if (notificationsList.isEmpty) {
        emit(DataError('Failed to load notifications'));
      } else {
        emit(_loadedState());
      }
    }
  }

  Future<String?> _resolveRequestId({
    String? requestId,
    String? fromUserId,
  }) async {
    if (fromUserId != null && fromUserId.isNotEmpty) {
      final bySender =
          await _networkApi.findPendingReceivedRequestIdByUserId(fromUserId);
      if (bySender != null && bySender.isNotEmpty) return bySender;
    }
    if (requestId != null && requestId.isNotEmpty) return requestId;
    return null;
  }

  Future<void> _acceptConnection(
    AcceptConnectionRequestEvent event,
    Emitter<NotificationState> emit,
  ) async {
    _markConnectionNotificationHandledLocally(event.notificationId, emit);
    try {
      final requestId = await _resolveRequestId(
        requestId: event.requestId,
        fromUserId: event.fromUserId,
      );
      if (requestId == null || requestId.isEmpty) {
        if (event.fromUserId != null && event.fromUserId!.isNotEmpty) {
          await _networkApi.acceptFriendRequest(event.fromUserId!);
        } else {
          throw Exception('Could not resolve connection request');
        }
      } else {
        try {
          await _networkApi.acceptFriendRequest(requestId);
        } catch (_) {
          if (event.fromUserId != null && event.fromUserId!.isNotEmpty) {
            await _networkApi.acceptFriendRequest(event.fromUserId!);
          } else {
            rethrow;
          }
        }
      }
      await _persistConnectionNotificationRead(event.notificationId);
    } catch (e) {
      print(e);
      add(NotificationLoadPageEvent(page: 1, readStatus: activeFilter));
    }
  }

  Future<void> _declineConnection(
    DeclineConnectionRequestEvent event,
    Emitter<NotificationState> emit,
  ) async {
    _markConnectionNotificationHandledLocally(event.notificationId, emit);
    try {
      final requestId = await _resolveRequestId(
        requestId: event.requestId,
        fromUserId: event.fromUserId,
      );
      if (requestId == null || requestId.isEmpty) {
        if (event.fromUserId != null && event.fromUserId!.isNotEmpty) {
          await _networkApi.rejectFriendRequest(event.fromUserId!);
        } else {
          throw Exception('Could not resolve connection request');
        }
      } else {
        try {
          await _networkApi.rejectFriendRequest(requestId);
        } catch (_) {
          if (event.fromUserId != null && event.fromUserId!.isNotEmpty) {
            await _networkApi.rejectFriendRequest(event.fromUserId!);
          } else {
            rethrow;
          }
        }
      }
      await _persistConnectionNotificationRead(event.notificationId);
    } catch (e) {
      print(e);
      add(NotificationLoadPageEvent(page: 1, readStatus: activeFilter));
    }
  }

  void _markConnectionNotificationHandledLocally(
    int notificationId,
    Emitter<NotificationState> emit,
  ) {
    notificationsList.removeWhere((n) => n.id == notificationId);
    if (totalNotifications > 0) {
      totalNotifications -= 1;
      NotificationCounterService().setCount(totalNotifications);
    }
    emit(_loadedState());
  }

  Future<void> _persistConnectionNotificationRead(int notificationId) async {
    try {
      await apiManager.readNotification(
        'Bearer ${AppData.userToken}',
        notificationId.toString(),
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> _readNotification(
    ReadNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await apiManager.readNotification(
        'Bearer ${AppData.userToken}',
        event.notificationId ?? "",
      );

      final index = notificationsList.indexWhere(
        (e) => e.id.toString() == event.notificationId,
      );
      if (index >= 0) {
        notificationsList[index].isRead = 1;
      }

      if (totalNotifications > 0) {
        totalNotifications = totalNotifications - 1;
        NotificationCounterService().setCount(totalNotifications);
      }

      emit(_loadedState());
    } catch (e) {
      print(e);
      emit(_loadedState());
    }
  }

  Future<void> _counterNotification(
    NotificationCounter event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Refresh the count from server via the counter service
      final counterService = NotificationCounterService();
      await counterService.refreshFromServer();
      totalNotifications = counterService.unreadCount;

      if (!hasCompletedInitialLoad) {
        return;
      }

      // Check email verification status (one-time check, cached after first success)
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      if (((await prefs.getString('email_verified_at')) ?? '') == '') {
        try {
          Dio dio = Dio();
          var response2 = await dio.post(
            '${AppData.remoteUrl2}/check-email-verified',
            options: Options(
              headers: {
                'Authorization': 'Bearer ${AppData.userToken}',
              },
            ),
          );
          if (response2.statusCode == 200) {
            emailVerified = response2.data['email_verified_at'] ?? "";
            await prefs.setString(
              'email_verified_at',
              response2.data['email_verified_at'] ?? '',
            );
          }
        } catch (_) {}
      }

      emit(_loadedState());
    } catch (e) {
      emit(DataError('No Data Found'));
    }
  }

  Future<void> _getAnnouncement(
    AnnouncementEvent event,
    Emitter<NotificationState> emit,
  ) async {
    // emit(DrugsDataInitial());
    emit(PaginationLoadingState());

    // ProgressDialogUtils.showProgressDialog();
    try {
      Dio dio = Dio();

      final prefs = SecureStorageService.instance;
      await prefs.initialize();

      Response response = await dio.get(
        '${AppData.remoteUrl2}/announcement', // Add query parameters
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppData.userToken}', // Set headers
          },
        ),
      );

      announcementModel = AnnouncementModel.fromJson(response.data);

      print('${announcementModel?.toJson()}');

      emit(PaginationLoadedState());

      // emit(DataLoaded(notificationsList));
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState());

      emit(DataError('No Data Found'));
    }
  }

  Future<void> _getAnnouncementDetail(
    AnnouncementDetailEvent event,
    Emitter<NotificationState> emit,
  ) async {
    // emit(DrugsDataInitial());
    emit(PaginationLoadingState());

    // ProgressDialogUtils.showProgressDialog();
    try {
      Dio dio = Dio();

      final prefs = SecureStorageService.instance;
      await prefs.initialize();

      Response response = await dio.get(
        '${AppData.remoteUrl2}/announcements/${event.announcementId}', // Add query parameters
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppData.userToken}', // Set headers
          },
        ),
      );

      announcementDetailModel = AnnouncementDetailModel.fromJson(response.data);

      emit(PaginationLoadedState());

      // emit(DataLoaded(notificationsList));
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState());

      emit(DataError('No Data Found'));
    }
  }

  Future<void> _onGetJobDetail(
    NotificationDetailPageEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(PaginationLoadingState());
    // try {
    // JobDetailModel response = await apiManager.getJobsDetails(
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

  Future<void> _onGetNotification1(
    GetPost event,
    Emitter<NotificationState> emit,
  ) async {
    // emit(PaginationInitialState());
    // ProgressDialogUtils.showProgressDialog();

    // emit(PaginationLoadingState());
    // try {
    //   JobsModel response = await apiManager.getJobsList(
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
