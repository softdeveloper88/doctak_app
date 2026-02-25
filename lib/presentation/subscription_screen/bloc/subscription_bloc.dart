import 'package:bloc/bloc.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/subscription_api_service.dart';
import 'package:doctak_app/data/models/subscription/subscription_data_model.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionApiService _api = SubscriptionApiService.instance;

  SubscriptionBloc() : super(SubscriptionInitial()) {
    on<LoadSubscriptionData>(_onLoad);
    on<RefreshSubscriptionStatus>(_onRefresh);
    on<TogglePricingPeriod>(_onTogglePeriod);
  }

  Future<void> _onLoad(LoadSubscriptionData event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    try {
      // Fetch status + plans + premium-page in parallel
      final statusFuture = _api.getStatus();
      final plansFuture = _api.getPlans();
      final premiumPageFuture = _api.getPremiumPage();

      final statusResp = await statusFuture;
      final plansResp = await plansFuture;
      final premiumPageResp = await premiumPageFuture;

      // Update AppData global subscription state
      AppData.updateSubscriptionData(statusResp.subscription, statusResp.features);

      emit(SubscriptionLoaded(
        status: statusResp.subscription,
        features: statusResp.features,
        plans: plansResp.plans,
        monetizationEnabled: plansResp.monetizationEnabled,
        showYearly: false,
        premiumPage: premiumPageResp,
      ));
    } catch (e) {
      // Fall back to locally cached data from AppData if API fails
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
    // Silently refresh without resetting to loading if already loaded
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

