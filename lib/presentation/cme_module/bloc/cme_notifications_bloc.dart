import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_notification_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cme_notifications_event.dart';
import 'cme_notifications_state.dart';

class CmeNotificationsBloc
    extends Bloc<CmeNotificationsEvent, CmeNotificationsState> {
  List<CmeNotificationData> notificationsList = [];
  int unreadCount = 0;

  CmeNotificationsBloc() : super(CmeNotificationsInitialState()) {
    on<CmeLoadNotificationsEvent>(_onLoadNotifications);
    on<CmeMarkNotificationReadEvent>(_onMarkRead);
    on<CmeMarkAllNotificationsReadEvent>(_onMarkAllRead);
  }

  Future<void> _onLoadNotifications(CmeLoadNotificationsEvent event,
      Emitter<CmeNotificationsState> emit) async {
    emit(CmeNotificationsLoadingState());
    try {
      final response = await CmeApiService.getNotifications();
      notificationsList = response.notifications ?? [];
      unreadCount = response.unreadCount ?? 0;
      emit(CmeNotificationsLoadedState());
    } catch (e) {
      emit(CmeNotificationsErrorState('$e'));
    }
  }

  Future<void> _onMarkRead(CmeMarkNotificationReadEvent event,
      Emitter<CmeNotificationsState> emit) async {
    try {
      await CmeApiService.markNotificationAsRead(event.notificationId);
      final index = notificationsList
          .indexWhere((n) => n.id == event.notificationId);
      if (index != -1) {
        notificationsList[index].isRead = true;
        if (unreadCount > 0) unreadCount--;
      }
      emit(CmeNotificationsLoadedState());
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(CmeMarkAllNotificationsReadEvent event,
      Emitter<CmeNotificationsState> emit) async {
    try {
      await CmeApiService.markAllNotificationsRead();
      for (var n in notificationsList) {
        n.isRead = true;
      }
      unreadCount = 0;
      emit(CmeNotificationsLoadedState());
    } catch (_) {}
  }
}
