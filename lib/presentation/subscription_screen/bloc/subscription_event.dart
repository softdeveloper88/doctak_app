import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

/// Load both subscription status and plans list (used on first open)
class LoadSubscriptionData extends SubscriptionEvent {
  const LoadSubscriptionData();
}

/// Refresh only status (e.g. after returning from web purchase)
class RefreshSubscriptionStatus extends SubscriptionEvent {
  const RefreshSubscriptionStatus();
}

/// Toggle between monthly/yearly pricing view
class TogglePricingPeriod extends SubscriptionEvent {
  final bool showYearly;
  const TogglePricingPeriod(this.showYearly);
  @override
  List<Object?> get props => [showYearly];
}
