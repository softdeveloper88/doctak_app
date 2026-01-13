import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/add_post_event.dart';

class TagFriendsListBottomSheet extends StatefulWidget {
  final AddPostBloc searchPeopleBloc;

  const TagFriendsListBottomSheet(this.searchPeopleBloc, {Key? key})
    : super(key: key);

  @override
  State<TagFriendsListBottomSheet> createState() =>
      _TagFriendsListBottomSheetState();
}

class _TagFriendsListBottomSheetState extends State<TagFriendsListBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    widget.searchPeopleBloc.add(LoadPageEvent(page: 1, name: ''));
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textTertiary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.person_2_fill,
                    color: theme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tag Friends',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: theme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Mention people in your post',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: theme.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search Field - One UI 8.5 Style
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.inputBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.border, width: 0.5),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Icon(
                    CupertinoIcons.search,
                    color: theme.textTertiary,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      color: theme.textPrimary,
                    ),
                    onChanged: (name) {
                      widget.searchPeopleBloc.add(
                        LoadPageEvent(page: 1, name: name),
                      );
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search friends...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: theme.textTertiary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        widget.searchPeopleBloc.add(
                          LoadPageEvent(page: 1, name: ''),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.textTertiary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 14,
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Selected Friends Section
          BlocBuilder<AddPostBloc, AddPostState>(
            bloc: widget.searchPeopleBloc,
            builder: (context, state) {
              if (widget.searchPeopleBloc.selectedSearchPeopleData.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.primary.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            size: 16,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Selected (${widget.searchPeopleBloc.selectedSearchPeopleData.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: theme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget
                            .searchPeopleBloc
                            .selectedSearchPeopleData
                            .map((person) {
                              return _buildSelectedChip(person, theme);
                            })
                            .toList(),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          // Divider
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: theme.divider,
          ),
          // Friends List
          Expanded(
            child: BlocBuilder<AddPostBloc, AddPostState>(
              bloc: widget.searchPeopleBloc,
              builder: (context, state) {
                if (state is PaginationLoadingState) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoActivityIndicator(
                          color: theme.primary,
                          radius: 14,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading friends...',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state is PaginationLoadedState) {
                  final bloc = widget.searchPeopleBloc;
                  if (bloc.searchPeopleData.isEmpty) {
                    return _buildEmptyState(theme);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: bloc.searchPeopleData.length,
                    itemBuilder: (context, index) {
                      if (bloc.pageNumber <= bloc.numberOfPage) {
                        if (index ==
                            bloc.searchPeopleData.length -
                                bloc.nextPageTrigger) {
                          bloc.add(CheckIfNeedMoreDataEvent(index: index));
                        }
                      }

                      if (bloc.numberOfPage != bloc.pageNumber - 1 &&
                          index >= bloc.searchPeopleData.length - 1) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CupertinoActivityIndicator(
                              color: theme.primary,
                            ),
                          ),
                        );
                      }

                      final person = bloc.searchPeopleData[index];
                      final isSelected = bloc.selectedSearchPeopleData.any(
                        (p) => p.id == person.id,
                      );

                      return _buildFriendListItem(person, isSelected, theme);
                    },
                  );
                } else if (state is DataError) {
                  return _buildErrorState(state.errorMessage, theme);
                }
                return _buildEmptyState(theme);
              },
            ),
          ),
          // Done Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              border: Border(top: BorderSide(color: theme.divider, width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChip(dynamic person, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primary, theme.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                person.firstName?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${person.firstName ?? ''} ${person.lastName ?? ''}'.trim(),
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              widget.searchPeopleBloc.add(
                SelectFriendEvent(userData: person, isAdd: false),
              );
            },
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: theme.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(CupertinoIcons.xmark, size: 10, color: theme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendListItem(
    dynamic person,
    bool isSelected,
    OneUITheme theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? theme.primary.withOpacity(0.08)
            : theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            widget.searchPeopleBloc.add(
              SelectFriendEvent(userData: person, isAdd: !isSelected),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? theme.primary.withOpacity(0.3)
                    : theme.border,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.primary.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: person.profilePic?.isNotEmpty == true
                        ? CachedNetworkImage(
                            imageUrl: '${AppData.imageUrl}${person.profilePic}',
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.avatarBackground,
                              child: Center(
                                child: CupertinoActivityIndicator(
                                  color: theme.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildAvatarPlaceholder(person, theme),
                          )
                        : _buildAvatarPlaceholder(person, theme),
                  ),
                ),
                const SizedBox(width: 14),
                // Name
                Expanded(
                  child: Text(
                    '${person.firstName ?? ''} ${person.lastName ?? ''}'.trim(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: theme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Selection Indicator
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? theme.primary : theme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? null
                        : Border.all(color: theme.border, width: 1.5),
                  ),
                  child: isSelected
                      ? const Icon(
                          CupertinoIcons.checkmark,
                          color: Colors.white,
                          size: 16,
                        )
                      : Icon(
                          CupertinoIcons.plus,
                          color: theme.textTertiary,
                          size: 16,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(dynamic person, OneUITheme theme) {
    return Container(
      color: theme.avatarBackground,
      child: Center(
        child: Text(
          person.firstName?.substring(0, 1).toUpperCase() ?? '?',
          style: TextStyle(
            color: theme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.person_2,
              size: 40,
              color: theme.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No friends found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 40,
              color: theme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
