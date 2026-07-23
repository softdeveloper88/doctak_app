import 'package:bloc/bloc.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/subscription_api_service.dart';
import 'package:doctak_app/data/models/subscription/premium_page_model.dart';
import 'package:doctak_app/data/models/subscription/subscription_data_model.dart';
import 'package:doctak_app/data/models/subscription/subscription_plan_model.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionApiService _api = SubscriptionApiService.instance;

  SubscriptionBloc() : super(SubscriptionInitial()) {
    on<LoadSubscriptionData>(_onLoad);
    on<RefreshSubscriptionStatus>(_onRefresh);
    on<TogglePricingPeriod>(_onTogglePeriod);
  }

  Future<T?> _safeCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (_) {
      return null;
    }
  }

  Future<void> _onLoad(LoadSubscriptionData event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    try {
      // Parallel load; each call catches its own errors (avoids Future.catchError type crashes).
      final statusFuture = _safeCall(_api.getStatus);
      final plansFuture = _safeCall(_api.getPlans);
      final premiumFuture = _safeCall(_api.getPremiumPage);

      final SubscriptionStatusResponse? statusResp = await statusFuture;
      final SubscriptionPlansResponse? plansResp = await plansFuture;
      final PremiumPageResponse? premiumPageResp = await premiumFuture;

      if (statusResp == null && plansResp == null && premiumPageResp == null) {
        throw Exception('All subscription endpoints failed');
      }

      final status = statusResp?.subscription ?? AppData.subscriptionData ?? SubscriptionData.free();
      final features = statusResp?.features ?? AppData.featuresMap ?? FeaturesMap(features: {});
      if (statusResp != null) {
        AppData.updateSubscriptionData(statusResp.subscription, statusResp.features);
      }

      emit(SubscriptionLoaded(
        status: status,
        features: features,
        plans: plansResp?.plans ?? const [],
        monetizationEnabled: plansResp?.monetizationEnabled ?? true,
        showYearly: false,
        premiumPage: premiumPageResp,
      ));
    } catch (_) {
      if (AppData.subscriptionData != null) {
        emit(SubscriptionLoaded(
          status: AppData.subscriptionData!,
          features: AppData.featuresMap ?? FeaturesMap(features: {}),
          plans: const [],
          monetizationEnabled: true,
          showYearly: false,
        ));
      } else {
        emit(const SubscriptionError('Could not load subscription data. Please try again.'));
      }
    }
  }

  Future<void> _onRefresh(RefreshSubscriptionStatus event, Emitter<SubscriptionState> emit) async {
    try {
      final statusResp = await _api.getStatus();
      AppData.updateSubscriptionData(statusResp.subscription, statusResp.features);

      if (state is SubscriptionLoaded) {
        final current = state as SubscriptionLoaded;
        emit(current.copyWith(
          status: statusResp.subscription,
          features: statusResp.features,
        ));
      }
    } catch (_) {/* ignore silent refresh errors */}
  }

  void _onTogglePeriod(TogglePricingPeriod event, Emitter<SubscriptionState> emit) {
    if (state is SubscriptionLoaded) {
      emit((state as SubscriptionLoaded).copyWith(showYearly: event.showYearly));
    }
  }
}
