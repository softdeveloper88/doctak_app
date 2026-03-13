import 'package:equatable/equatable.dart';

abstract class CmeGamificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CmeLoadGamificationEvent extends CmeGamificationEvent {}

class CmeLoadBadgesEvent extends CmeGamificationEvent {}

class CmeLoadLeaderboardEvent extends CmeGamificationEvent {}
