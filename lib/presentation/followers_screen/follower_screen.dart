import 'dart:async';

import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/followers_screen/bloc/followers_bloc.dart';
import 'package:doctak_app/presentation/followers_screen/component/follower_widget.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FollowerScreen extends StatefulWidget {
  final Function? backPress;
  final bool isFollowersScreen;
  final String userId;

  const FollowerScreen({
    this.backPress,
    super.key,
    required this.isFollowersScreen,
    required this.userId,
  });

  @override
  State<FollowerScreen> createState() => _FollowerScreenState();
}

class _FollowerScreenState extends State<FollowerScreen> {
  final FollowersBloc _followersBloc = FollowersBloc();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _followersBloc.add(
      FollowersLoadPageEvent(page: 1, searchTerm: '', userId: widget.userId),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _followersBloc.close();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _followersBloc.add(
        FollowersLoadPageEvent(
          page: 1,
          searchTerm: query,
          userId: widget.userId,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: BlocBuilder<FollowersBloc, FollowersState>(
        bloc: _followersBloc,
        builder: (context, state) {
          final data = _followersBloc.followerDataModel;
          final followersCount = data?.totalFollows?.totalFollowers ?? '';
          final followingCount = data?.totalFollows?.totalFollowings ?? '';
          final currentCount = widget.isFollowersScreen ? followersCount : followingCount;

          return Column(
            children: [
              // ── AppBar with count badge ──
              _FollowerAppBar(
                title: widget.isFollowersScreen
                    ? translation(context).lbl_followers
                    : translation(context).lbl_following,
                count: currentCount,
                isFollowersScreen: widget.isFollowersScreen,
              ),

              // ── Always-visible search bar ──
              Container(
                color: theme.cardBackground,
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                child: _SearchBar(
                  controller: _searchController,
                  hintText: translation(context).lbl_search_people,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
              ),

              // ── List ──
              Expanded(child: _buildList(state, theme)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(FollowersState state, OneUITheme theme) {
    if (state is FollowersPaginationLoadingState ||
        state is FollowersPaginationInitialState) {
      return const ProfileListShimmer();
    }

    final items = widget.isFollowersScreen
        ? (_followersBloc.followerDataModel?.followers ?? [])
        : (_followersBloc.followerDataModel?.following ?? []);

    if (items.isEmpty) {
      return _EmptyState(isFollowers: widget.isFollowersScreen, theme: theme);
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final dynamic element = items[index];
        return FollowerWidget(
          userId: widget.userId,
          bloc: _followersBloc,
          element: element,
          isFollowersScreen: widget.isFollowersScreen,
          showMutualIndicator:
              widget.isFollowersScreen && (element.isCurrentlyFollow == true),
          onTap: () async {
            final isFollowing = element.isCurrentlyFollow == true;
            if (isFollowing) {
              _followersBloc.add(SetUserFollow(element.id ?? '', 'unfollow'));
              element.isCurrentlyFollow = false;
            } else {
              _followersBloc.add(SetUserFollow(element.id ?? '', 'follow'));
              element.isCurrentlyFollow = true;
            }
          },
        );
      },
    );
  }
}

// ── Compact AppBar with count badge ──────────────────────────────────────────

class _FollowerAppBar extends StatelessWidget {
  final String title;
  final String count;
  final bool isFollowersScreen;

  const _FollowerAppBar({
    required this.title,
    required this.count,
    required this.isFollowersScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return DoctakAppBar(
      title: title,
      titleIcon: isFollowersScreen
          ? Icons.people_rounded
          : Icons.person_add_rounded,
      actions: [
        if (count.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.primary,
                  ),
                ),
              ),
            ),
          ),
        IconButton(
          icon: Icon(CupertinoIcons.search, size: 20, color: theme.iconColor),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.inputBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: 13.5, color: theme.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 13, color: theme.textSecondary),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 19,
            color: theme.textSecondary,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: theme.textSecondary,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFollowers;
  final OneUITheme theme;

  const _EmptyState({required this.isFollowers, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFollowers
                  ? Icons.people_outline_rounded
                  : Icons.person_add_disabled_rounded,
              size: 48,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFollowers ? 'No followers yet' : 'Not following anyone yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isFollowers
                  ? "When people follow you, they'll appear here"
                  : 'Start following people to see them here',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: theme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
