import 'package:bloc/bloc.dart';
import 'package:doctak_app/data/apiClient/services/network_api_service.dart';
import 'package:doctak_app/data/apiClient/services/organization_profile_api_service.dart';
import 'package:doctak_app/presentation/organization_profile/bloc/organization_profile_event.dart';
import 'package:doctak_app/presentation/organization_profile/bloc/organization_profile_state.dart';

class OrganizationProfileBloc
    extends Bloc<OrganizationProfileEvent, OrganizationProfileState> {
  OrganizationProfileBloc({
    OrganizationProfileApiService? api,
    NetworkApiService? networkApi,
  })  : _api = api ?? OrganizationProfileApiService(),
        _networkApi = networkApi ?? NetworkApiService(),
        super(OrganizationProfileInitial()) {
    on<LoadOrganizationProfileEvent>(_onLoad);
    on<ToggleOrganizationFollowEvent>(_onToggleFollow);
  }

  final OrganizationProfileApiService _api;
  final NetworkApiService _networkApi;

  Future<void> _onLoad(
    LoadOrganizationProfileEvent event,
    Emitter<OrganizationProfileState> emit,
  ) async {
    emit(OrganizationProfileLoading());
    try {
      final profile = await _api.getPublicProfile(event.identifier);
      emit(OrganizationProfileLoaded(profile: profile));
    } catch (e) {
      emit(OrganizationProfileError(e.toString()));
    }
  }

  Future<void> _onToggleFollow(
    ToggleOrganizationFollowEvent event,
    Emitter<OrganizationProfileState> emit,
  ) async {
    final current = state;
    if (current is! OrganizationProfileLoaded) return;

    emit(current.copyWith(isFollowBusy: true));
    final orgId = current.profile.organization.id;
    final isFollowing =
        current.profile.viewer?.isFollowingOrganization ?? false;

    try {
      if (isFollowing) {
        await _networkApi.unfollowOrganization(orgId);
      } else {
        await _networkApi.followOrganization(orgId);
      }

      final followerCount = current.profile.organization.followerCount +
          (isFollowing ? -1 : 1);

      emit(
        OrganizationProfileLoaded(
          profile: current.profile.copyWith(
            organization: current.profile.organization
                .copyWith(followerCount: followerCount < 0 ? 0 : followerCount),
            viewer: current.profile.viewer
                ?.copyWith(isFollowingOrganization: !isFollowing),
          ),
        ),
      );
    } catch (_) {
      emit(current.copyWith(isFollowBusy: false));
    }
  }
}
