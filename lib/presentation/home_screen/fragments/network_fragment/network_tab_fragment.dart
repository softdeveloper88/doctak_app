import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/presentation/home_screen/fragments/network_fragment/network_search_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/network_fragment/network_widgets.dart';
import 'package:doctak_app/presentation/home_screen/fragments/network_fragment/organizations_discover_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/network_fragment/people_you_may_know_screen.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/network_screen/bloc/network_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/presentation/organization_profile/organization_profile_screen.dart';

import '../../../../localization/app_localization.dart';

class NetworkTabFragment extends StatefulWidget {
  final VoidCallback openDrawer;
  const NetworkTabFragment({super.key, required this.openDrawer});

  @override
  State<NetworkTabFragment> createState() => _NetworkTabFragmentState();
}

class _NetworkTabFragmentState extends State<NetworkTabFragment> {
  final NetworkBloc _bloc = NetworkBloc();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _suggestionsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bloc.add(const LoadNetworkHomeEvent());
    _scrollController.addListener(_onScroll);
    _suggestionsScrollController.addListener(_onSuggestionsScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_bloc.connectionsHasMore && !_bloc.isLoadingMore) {
        _bloc.add(LoadConnectionsEvent(page: _bloc.connectionsPage + 1));
      }
    }
  }

  void _onSuggestionsScroll() {
    if (_suggestionsScrollController.position.pixels >=
        _suggestionsScrollController.position.maxScrollExtent - 150) {
      if (_bloc.suggestionsHasMore && !_bloc.isLoadingMore) {
        _bloc.add(LoadSuggestionsEvent(page: _bloc.suggestionsPage + 1));
      }
    }
  }

  int get _connectionsBadgeCount {
    final fromStats = int.tryParse(
      _bloc.networkStats['connections']?.toString() ?? '',
    );
    if (fromStats != null && fromStats > 0) return fromStats;
    return _bloc.connections.isNotEmpty ? _bloc.connections.length : 0;
  }

  Future<void> _refresh() async {
    _bloc.add(const LoadNetworkHomeEvent(silent: true));
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _suggestionsScrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<NetworkBloc, NetworkState>(
        bloc: _bloc,
        listener: (context, state) {
          if (state is NetworkActionSuccessState) {
            toast(state.message);
          } else if (state is NetworkErrorState) {
            toast(state.message);
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackground,
          appBar: DoctakAppBar(
            title: 'Network',
            showBackButton: false,
            automaticallyImplyLeading: false,
            titleColor: theme.textPrimary,
            titleFontSize: NetworkTypography.screenTitle,
            titleFontWeight: FontWeight.w700,
            centerTitle: false,
            toolbarHeight: 56,
            actions: [
              IconButton(
                icon: Icon(
                  CupertinoIcons.search,
                  size: 20,
                  color: theme.iconColor,
                ),
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  AppNavigator.push(
                    context,
                    const NetworkSearchScreen(),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: BlocBuilder<NetworkBloc, NetworkState>(
                  bloc: _bloc,
                  builder: (context, state) {
                    final isInitialLoading =
                        !_bloc.hasLoadedHome && state is NetworkLoadingState;
                    if (isInitialLoading) {
                      return const NetworkHomeShimmer();
                    }

                    return RefreshIndicator(
                      color: theme.primary,
                      onRefresh: _refresh,
                      child: _buildNetworkHomeBody(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkHomeBody() {
    final hasInvitations =
        _bloc.hasLoadedRequests && _bloc.pendingCount > 0;

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (hasInvitations)
          NetworkInvitationsBanner(
            count: _bloc.pendingCount,
            subtitle: _bloc.invitationSubtitle,
            previewNames: _bloc.invitationPreviewNames,
            onReview: () => _showInvitationsSheet(context),
          ),
        Padding(
          padding: EdgeInsets.only(
            top: hasInvitations
                ? NetworkLayout.sectionTopSpacing
                : NetworkLayout.firstSectionTopSpacing,
          ),
          child: _buildPeopleYouMayKnowSection(context),
        ),
        Padding(
          padding: const EdgeInsets.only(top: NetworkLayout.sectionTopSpacing),
          child: _buildOrganizationsSection(context),
        ),
        Padding(
          padding: const EdgeInsets.only(top: NetworkLayout.sectionTopSpacing),
          child: _buildConnectionsSection(context),
        ),
      ],
    );
  }

  void _showInvitationsSheet(BuildContext context) {
    final theme = OneUITheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final requests = _bloc.friendRequests;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  translation(context).lbl_connection_requests,
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: NetworkTypography.sectionTitle,
                  ),
                ),
                const SizedBox(height: 12),
                if (requests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No pending invitations',
                        style: theme.bodySecondary,
                      ),
                    ),
                  )
                else
                  ...requests.map((request) {
                    final person = networkPersonFromRequest(request);
                    final requestId = networkRequestId(request);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          NetworkUserAvatar(
                            imageUrl: networkPersonAvatar(person),
                            name: networkPersonName(person),
                            size: 42,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  networkPersonName(person),
                                  style: theme.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: NetworkTypography.listName,
                                  ),
                                ),
                                Text(
                                  networkPersonHeadline(person),
                                  style: theme.bodySecondary.copyWith(
                                    fontSize: NetworkTypography.listSubtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: requestId.isEmpty
                                ? null
                                : () {
                                    _bloc.add(
                                      AcceptFriendRequestEvent(
                                        requestId: requestId,
                                      ),
                                    );
                                    Navigator.pop(sheetContext);
                                  },
                            child: Text(translation(context).lbl_accept),
                          ),
                          IconButton(
                            onPressed: requestId.isEmpty
                                ? null
                                : () {
                                    _bloc.add(
                                      RejectFriendRequestEvent(
                                        requestId: requestId,
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeopleYouMayKnowSection(BuildContext context) {
    final theme = OneUITheme.of(context);
    final suggestions = _bloc.suggestions;
    final isLoading = !_bloc.hasLoadedSuggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NetworkSectionHeader(
          title: translation(context).lbl_people_you_may_know,
          actionLabel: suggestions.isNotEmpty
              ? translation(context).lbl_see_all
              : null,
          onAction: suggestions.isNotEmpty
              ? () => AppNavigator.push(
                    context,
                    const PeopleYouMayKnowScreen(),
                  )
              : null,
        ),
        SizedBox(
          height: NetworkLayout.personCardHeight,
          child: isLoading
              ? NetworkHorizontalCardsShimmer(
                  cardWidth: networkPersonCardWidth(context),
                  height: NetworkLayout.personCardHeight,
                )
              : suggestions.isEmpty
                  ? Center(
                      child: Text(
                        translation(context).lbl_no_suggestions,
                        style: theme.bodySecondary,
                      ),
                    )
                  : ListView.builder(
                      controller: _suggestionsScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsetsDirectional.only(
                        start: NetworkLayout.horizontalListPadding,
                        end: NetworkLayout.horizontalListPadding,
                        bottom: 4,
                      ),
                      itemCount: suggestions.length +
                          (_bloc.suggestionsHasMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i >= suggestions.length) {
                          return const SizedBox(
                            width: 48,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        final person = suggestions[i];
                        return NetworkPersonCard(
                          person: person,
                          onConnect: () => _toggleConnect(person),
                          onTap: () => _openProfile(person),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildOrganizationsSection(BuildContext context) {
    final theme = OneUITheme.of(context);
    final organizations = _bloc.organizations;
    final isLoading = !_bloc.hasLoadedOrganizations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NetworkSectionHeader(
          title: 'Organizations',
          actionLabel: organizations.isNotEmpty ? 'See all' : null,
          onAction: organizations.isNotEmpty
              ? () => AppNavigator.push(
                    context,
                    const OrganizationsDiscoverScreen(),
                  )
              : null,
        ),
        SizedBox(
          height: NetworkLayout.organizationCardHeight,
          child: isLoading
              ? NetworkHorizontalCardsShimmer(
                  cardWidth: networkOrganizationCardWidth(context),
                  height: NetworkLayout.organizationCardHeight,
                  kind: NetworkHorizontalShimmerKind.organization,
                )
              : organizations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'No organizations to show yet',
                          style: theme.bodySecondary,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsetsDirectional.only(
                        start: NetworkLayout.horizontalListPadding,
                        end: NetworkLayout.horizontalListPadding,
                        bottom: 4,
                      ),
                      itemCount: organizations.length,
                      itemBuilder: (context, index) {
                        final org = organizations[index];
                        return NetworkOrganizationCard(
                          organization: org,
                          onFollowToggle: () => _bloc.add(
                            ToggleOrganizationFollowEvent(
                              organizationId: org['id']?.toString() ?? '',
                            ),
                          ),
                          onOpen: () => _openOrganization(org),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildConnectionsSection(BuildContext context) {
    final theme = OneUITheme.of(context);
    final connections = _bloc.connections;
    final isLoading = !_bloc.hasLoadedConnections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NetworkSectionHeader(
          title: translation(context).lbl_your_connections,
          badgeCount: _connectionsBadgeCount,
        ),
        if (isLoading)
          const NetworkConnectionsListShimmer()
        else if (connections.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                translation(context).lbl_no_connections,
                style: theme.bodySecondary,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NetworkLayout.connectionsHorizontalInset,
            ),
            child: Container(
              decoration: networkSurfaceCard(theme),
              child: Column(
                children: connections.asMap().entries.map((entry) {
                  final person = entry.value;
                  final name = networkPersonName(person);
                  return Column(
                    children: [
                      _ConnectionListTile(
                        name: name,
                        subtitle: networkPersonHeadline(person),
                        avatarUrl: networkPersonAvatar(person),
                        userId: person['id']?.toString() ?? '',
                        isVerified: person['is_verified'] == true ||
                            person['is_verified'] == 1,
                        onMessage: () {
                          ChatRoomScreen(
                            username: name,
                            profilePic: networkPersonAvatar(person) ?? '',
                            id: person['id']?.toString() ?? '',
                            conversationId: 0,
                          ).launch(
                            context,
                            pageRouteAnimation: PageRouteAnimation.Slide,
                          );
                        },
                      ),
                      if (entry.key < connections.length - 1)
                        Divider(
                          color: theme.border.withValues(alpha: 0.07),
                          height: 1,
                          indent: 72,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        if (_bloc.connectionsHasMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
      ],
    );
  }

  void _toggleConnect(Map<String, dynamic> person) {
    if (person['friendRequestSent'] == true) {
      _bloc.add(
        CancelFriendRequestEvent(
          requestId: person['friendRequestId']?.toString() ?? '',
          userId: person['id']?.toString() ?? '',
        ),
      );
    } else {
      _bloc.add(SendFriendRequestEvent(userId: person['id']?.toString() ?? ''));
    }
  }

  void _openProfile(Map<String, dynamic> person) {
    ProfileNavigation.openFromMap(context, person);
  }

  Future<void> _openOrganization(Map<String, dynamic> org) async {
    final slug = org['slug']?.toString();
    final id = org['id']?.toString() ?? '';
    final identifier = (slug != null && slug.isNotEmpty) ? slug : id;
    if (identifier.isEmpty) return;
    OrganizationProfileScreen(identifier: identifier).launch(
      context,
      pageRouteAnimation: PageRouteAnimation.Slide,
    );
  }

}

class _ConnectionListTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final String userId;
  final bool isVerified;
  final VoidCallback onMessage;

  const _ConnectionListTile({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.userId,
    this.isVerified = false,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return InkWell(
      onTap: () => ProfileNavigation.openUser(context, userId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            NetworkUserAvatar(
              imageUrl: avatarUrl,
              name: name,
              size: NetworkLayout.connectionAvatarSize,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall.copyWith(
                            fontSize: NetworkTypography.listName,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        theme.buildVerifiedBadge(size: 16),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySecondary.copyWith(
                        fontSize: NetworkTypography.listSubtitle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onMessage,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 20,
                      color: theme.textTertiary,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      translation(context).lbl_message,
                      style: theme.bodySecondary.copyWith(
                        fontSize: NetworkTypography.listAction,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
