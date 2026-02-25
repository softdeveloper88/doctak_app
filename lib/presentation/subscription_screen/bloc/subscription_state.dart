import 'package:equatable/equatable.dart';
import 'package:doctak_app/data/models/subscription/premium_page_model.dart';
import 'package:doctak_app/data/models/subscription/subscription_data_model.dart';
import 'package:doctak_app/data/models/subscription/subscription_plan_model.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final SubscriptionData status;
  final FeaturesMap features;
  final List<SubscriptionPlanItem> plans;
  final bool monetizationEnabled;
  final bool showYearly;

  // Premium page data from the /premium-page endpoint (synced with web)
  final PremiumPageResponse? premiumPage;

  const SubscriptionLoaded({
    required this.status,
    required this.features,
    required this.plans,
    this.monetizationEnabled = true,
    this.showYearly = false,
    this.premiumPage,
  });

  SubscriptionLoaded copyWith({
    SubscriptionData? status,
    FeaturesMap? features,
    List<SubscriptionPlanItem>? plans,
    bool? monetizationEnabled,
    bool? showYearly,
    PremiumPageResponse? premiumPage,
  }) {
    return SubscriptionLoaded(
      status: status ?? this.status,
      features: features ?? this.features,
      plans: plans ?? this.plans,
      monetizationEnabled: monetizationEnabled ?? this.monetizationEnabled,
      showYearly: showYearly ?? this.showYearly,
      premiumPage: premiumPage ?? this.premiumPage,
    );
  }

  @override
  List<Object?> get props => [status, features, plans, monetizationEnabled, showYearly, premiumPage];
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
  @override
  List<Object?> get props => [message];
}
