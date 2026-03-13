import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/presentation/home_screen/fragments/network_fragment/network_search_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/presentation/network_screen/bloc/network_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../localization/app_localization.dart';
import 'people_you_may_know_screen.dart';

/// ═══════════════════════════════════════════════════════
///  MY NETWORK TAB FRAGMENT
///  Bottom nav embedded screen matching the reference design:
///    - Connection Requests (horizontal scroll cards)
///    - People You May Know (horizontal scroll cards)
///    - Your Connections (vertical list with Message action)
/// ═══════════════════════════════════════════════════════
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
    // Load all three sections in parallel
    _bloc.add(const LoadFriendRequestsEvent(type: 'received'));
    _bloc.add(const LoadSuggestionsEvent());
    _bloc.add(const LoadConnectionsEvent());
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
          appBar: _buildAppBar(context, theme),
          body: BlocBuilder<NetworkBloc, NetworkState>(
            bloc: _bloc,
            builder: (context, state) {
              return RefreshIndicator(
                color: theme.primary,
                onRefresh: () async {
                  _bloc.add(const LoadFriendRequestsEvent(type: 'received'));
                  _bloc.add(const LoadSuggestionsEvent());
                  _bloc.add(const LoadConnectionsEvent());
                  // Wait a bit for the data to load
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    // ── Connection Requests Section ──
                    _buildConnectionRequestsSection(context, theme),
                    // ── People You May Know Section ──
                    _buildPeopleYouMayKnowSection(context, theme),
                    // ── Your Connections Section ──
                    _buildConnectionsSection(context, theme),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, OneUITheme theme) {
    return DoctakAppBar(
      title: translation(context).lbl_my_network,
      showBackButton: false,
      actions: [
        theme.buildIconButton(
          child: Icon(CupertinoIcons.search, size: 22, color: theme.iconColor),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NetworkSearchScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  CONNECTION REQUESTS (Horizontal scroll cards)
  // ═══════════════════════════════════════════════════════
  Widget _buildConnectionRequestsSection(BuildContext context, OneUITheme theme) {
    final requests = _bloc.friendRequests;
    final isLoading = !_bloc.hasLoadedRequests;

    // Hide entire section when loaded and empty
    if (!isLoading && requests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: translation(context).lbl_connection_requests,
          count: requests.isNotEmpty ? '${requests.length}' : null,
        ),
        SizedBox(
          height: 190,
          child: isLoading
              ? _buildHorizontalShimmer(theme)
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
                  itemCount: requests.length,
                  itemBuilder: (ctx, i) {
                    final request = requests[i];
                    final person = request['sender'] as Map<String, dynamic>? ?? request;
                    final requestId = request['id']?.toString() ?? '0';
                    return _ConnectionRequestCard(
                      name: '${person['first_name'] ?? ''} ${person['last_name'] ?? ''}'.trim(),
                      subtitle: _buildHeadline(person),
                      avatarUrl: AppData.fullImageUrl(person['profile_pic'] as String?),
                      onAccept: () => _bloc.add(AcceptFriendRequestEvent(requestId: requestId)),
                      onIgnore: () => _bloc.add(RejectFriendRequestEvent(requestId: requestId)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  PEOPLE YOU MAY KNOW (Horizontal scroll cards)
  // ═══════════════════════════════════════════════════════
  Widget _buildPeopleYouMayKnowSection(BuildContext context, OneUITheme theme) {
    final suggestions = _bloc.suggestions;
    final isLoading = !_bloc.hasLoadedSuggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  translation(context).lbl_people_you_may_know,
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              if (!isLoading && suggestions.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PeopleYouMayKnowScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          translation(context).lbl_see_all,
                          style: theme.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: theme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 195,
          child: isLoading
              ? _buildHorizontalShimmer(theme)
              : suggestions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          translation(context).lbl_no_suggestions,
                          style: theme.bodySecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _suggestionsScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
                      itemCount: suggestions.length + (_bloc.suggestionsHasMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        // Loading indicator at end
                        if (i >= suggestions.length) {
                          return Container(
                            width: 80,
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                              ),
                            ),
                          );
                        }
                        final person = suggestions[i];
                        final mutualCount = person['mutualCount'] ?? person['mutual_count'] ?? 0;
                        final mutualCountInt = mutualCount is int ? mutualCount : int.tryParse(mutualCount.toString()) ?? 0;
                        final mutualFriends = (person['mutualFriends'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
                        final specialty = person['specialty'] as String? ?? '';
                        return _SuggestionCard(
                          name: person['fullName'] as String? ??
                              '${person['first_name'] ?? ''} ${person['last_name'] ?? ''}'.trim(),
                          specialty: specialty,
                          mutualCount: mutualCountInt,
                          mutualFriends: mutualFriends,
                          avatarUrl: AppData.fullImageUrl(person['profilePicUrl'] as String? ??
                              person['profile_pic'] as String?),
                          isRequestSent: person['friendRequestSent'] == true,
                          onConnect: () {
                            if (person['friendRequestSent'] == true) {
                              _bloc.add(CancelFriendRequestEvent(
                                requestId: person['friendRequestId']?.toString() ?? '',
                                userId: person['id']?.toString() ?? '',
                              ));
                            } else {
                              _bloc.add(SendFriendRequestEvent(
                                userId: person['id']?.toString() ?? '',
                              ));
                            }
                          },
                          onTap: () {
                            SVProfileFragment(userId: person['id']?.toString() ?? '')
                                .launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  YOUR CONNECTIONS (Vertical list with Message)
  // ═══════════════════════════════════════════════════════
  Widget _buildConnectionsSection(BuildContext context, OneUITheme theme) {
    final connections = _bloc.connections;
    final isLoading = !_bloc.hasLoadedConnections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: translation(context).lbl_your_connections,
          count: connections.isNotEmpty
              ? '${connections.length}${_bloc.connectionsHasMore ? '+' : ''}'
              : null,
          bottomPadding: 8,
        ),
        if (isLoading)
          const ProfileListShimmer()
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
          ...connections.asMap().entries.map((entry) {
            final i = entry.key;
            final person = entry.value;
            return Column(
              children: [
                _ConnectionListTile(
                  name: '${person['first_name'] ?? ''} ${person['last_name'] ?? ''}'.trim(),
                  subtitle: _buildHeadline(person),
                  avatarUrl: AppData.fullImageUrl(person['profile_pic'] as String?),
                  userId: person['id']?.toString() ?? '',
                  onMessage: () {
                    ChatRoomScreen(
                      username: '${person['first_name'] ?? ''} ${person['last_name'] ?? ''}',
                      profilePic: person['profile_pic'] ?? '',
                      id: person['id']?.toString() ?? '',
                      conversationId: 0,
                    ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                ),
                if (i < connections.length - 1)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 84, end: 20),
                    child: Divider(color: theme.border.withValues(alpha: 0.2), height: 1),
                  ),
              ],
            );
          }),
        if (_bloc.connectionsHasMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
      ],
    );
  }

  String _buildHeadline(Map<String, dynamic> person) {
    final specialty = person['specialty'] as String? ?? '';
    final country = person['country'] as String? ?? '';
    if (specialty.isNotEmpty && country.isNotEmpty) {
      return '${capitalizeWords(specialty)} $country';
    }
    return specialty.isNotEmpty ? capitalizeWords(specialty) : country;
  }

  Widget _buildHorizontalShimmer(OneUITheme theme) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.only(start: 16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        width: 180,
        margin: const EdgeInsetsDirectional.only(end: 10),
        decoration: _networkCardDecoration(theme),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary.withValues(alpha: 0.4)),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  CONNECTION REQUEST CARD (Horizontal)
// ═══════════════════════════════════════════════════════
class _ConnectionRequestCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback onAccept;
  final VoidCallback onIgnore;

  const _ConnectionRequestCard({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.onAccept,
    required this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      width: 180,
      margin: const EdgeInsetsDirectional.only(end: 10),
      decoration: _networkCardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            NetworkUserAvatar(imageUrl: avatarUrl, name: name, size: 48),
            const SizedBox(height: 8),
            Text(
              name.isNotEmpty ? name : translation(context).lbl_unknown,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.titleSmall.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.bodySecondary.copyWith(fontSize: 11),
              ),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: NetworkActionButton(
                    label: translation(context).lbl_accept,
                    filled: true,
                    onTap: onAccept,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: NetworkActionButton(
                    label: translation(context).lbl_ignore,
                    filled: false,
                    onTap: onIgnore,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SUGGESTION CARD (People You May Know — Horizontal)
// ═══════════════════════════════════════════════════════
class _SuggestionCard extends StatelessWidget {
  final String name;
  final String specialty;
  final int mutualCount;
  final List<Map<String, dynamic>> mutualFriends;
  final String? avatarUrl;
  final bool isRequestSent;
  final VoidCallback onConnect;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.name,
    this.specialty = '',
    required this.mutualCount,
    this.mutualFriends = const [],
    required this.avatarUrl,
    required this.isRequestSent,
    required this.onConnect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsetsDirectional.only(end: 10),
        decoration: _networkCardDecoration(theme),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            children: [
              NetworkUserAvatar(imageUrl: avatarUrl, name: name, size: 48),
              const SizedBox(height: 8),
              Text(
                name.isNotEmpty ? name : translation(context).lbl_unknown,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.titleSmall.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              if (specialty.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  capitalizeWords(specialty),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.bodySecondary.copyWith(fontSize: 11),
                ),
              ],
              const SizedBox(height: 6),
              if (mutualCount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Overlapping mutual friend avatars
                    if (mutualFriends.isNotEmpty)
                      SizedBox(
                        width: mutualFriends.length == 1 ? 22 : (mutualFriends.length == 2 ? 34 : 46),
                        height: 22,
                        child: Stack(
                          children: mutualFriends.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final mf = entry.value;
                            final pic = AppData.fullImageUrl(mf['profile_pic'] as String? ?? '');
                            return PositionedDirectional(
                              start: idx * 12.0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.cardBackground, width: 1.5),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: pic.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: pic,
                                          width: 22,
                                          height: 22,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            color: theme.primary.withValues(alpha: 0.15),
                                            child: Icon(Icons.person, size: 12, color: theme.primary),
                                          ),
                                          errorWidget: (_, __, ___) => Container(
                                            color: theme.primary.withValues(alpha: 0.15),
                                            child: Icon(Icons.person, size: 12, color: theme.primary),
                                          ),
                                        )
                                      : Container(
                                          color: theme.primary.withValues(alpha: 0.15),
                                          child: Center(
                                            child: Text(
                                              (mf['name'] as String? ?? 'U').isNotEmpty
                                                  ? (mf['name'] as String)[0].toUpperCase()
                                                  : 'U',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: theme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    else
                      // Fallback: person icons if no mutual friend details
                      SizedBox(
                        width: 30,
                        height: 18,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              child: Icon(Icons.person, size: 16, color: theme.primary.withValues(alpha: 0.7)),
                            ),
                            Positioned(
                              left: 10,
                              child: Icon(Icons.person, size: 16, color: theme.primary.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$mutualCount ${translation(context).lbl_mutual_connections}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: NetworkActionButton(
                  label: isRequestSent
                      ? translation(context).lbl_cancel
                      : translation(context).lbl_connect,
                  filled: !isRequestSent,
                  onTap: onConnect,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  YOUR CONNECTION LIST TILE (Vertical list with Message)
// ═══════════════════════════════════════════════════════
class _ConnectionListTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final String userId;
  final VoidCallback onMessage;

  const _ConnectionListTile({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.userId,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return InkWell(
      onTap: () => SVProfileFragment(userId: userId)
          .launch(context, pageRouteAnimation: PageRouteAnimation.Slide),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            // Avatar
            NetworkUserAvatar(imageUrl: avatarUrl, name: name, size: 50),
            const SizedBox(width: 14),
            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : translation(context).lbl_unknown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySecondary.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Message button
            GestureDetector(
              onTap: onMessage,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_outline_rounded, size: 18, color: theme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    translation(context).lbl_message,
                    style: theme.bodySecondary.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? count;
  final double bottomPadding;

  const _SectionHeader({
    required this.title,
    this.count,
    this.bottomPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
      child: Row(
        children: [
          Text(
            title,
            style: theme.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: theme.radiusFull,
              ),
              child: Text(
                count!,
                style: theme.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

BoxDecoration _networkCardDecoration(OneUITheme theme) {
  return theme.cardDecoration;
}

// Shared widgets (NetworkUserAvatar, NetworkActionButton, etc.)
// are imported from people_you_may_know_screen.dart

