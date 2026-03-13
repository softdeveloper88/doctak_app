import 'package:equatable/equatable.dart';

abstract class CmeProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CmeLoadProfileEvent extends CmeProfileEvent {}

class CmeLoadTranscriptEvent extends CmeProfileEvent {}

class CmeLoadAchievementsEvent extends CmeProfileEvent {}
