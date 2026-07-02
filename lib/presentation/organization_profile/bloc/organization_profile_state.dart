import 'package:doctak_app/data/models/organization_profile/organization_public_profile_model.dart';
import 'package:equatable/equatable.dart';

abstract class OrganizationProfileState extends Equatable {
  const OrganizationProfileState();

  @override
  List<Object?> get props => [];
}

class OrganizationProfileInitial extends OrganizationProfileState {}

class OrganizationProfileLoading extends OrganizationProfileState {}

class OrganizationProfileLoaded extends OrganizationProfileState {
  const OrganizationProfileLoaded({
    required this.profile,
    this.isFollowBusy = false,
  });

  final OrganizationPublicProfileModel profile;
  final bool isFollowBusy;

  OrganizationProfileLoaded copyWith({
    OrganizationPublicProfileModel? profile,
    bool? isFollowBusy,
  }) {
    return OrganizationProfileLoaded(
      profile: profile ?? this.profile,
      isFollowBusy: isFollowBusy ?? this.isFollowBusy,
    );
  }

  @override
  List<Object?> get props => [profile, isFollowBusy];
}

class OrganizationProfileError extends OrganizationProfileState {
  const OrganizationProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
