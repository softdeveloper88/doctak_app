import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/add_post_bloc.dart';

class OtherFeatureComponent extends StatefulWidget {
  final Function? onColorChange;
  final Color? colorValue;
  final AddPostBloc searchPeopleBloc;

  const OtherFeatureComponent({
    this.onColorChange,
    this.colorValue,
    required this.searchPeopleBloc,
    Key? key,
  }) : super(key: key);

  @override
  State<OtherFeatureComponent> createState() => _OtherFeatureComponentState();
}

class _OtherFeatureComponentState extends State<OtherFeatureComponent> {
  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Column(
      children: [
        // Tag Friends Button - One UI 8.5 List Item Style
        Material(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              svShowShareBottomSheet(context, widget.searchPeopleBloc);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.border, width: 0.5),
              ),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.person_2_fill,
                      color: theme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translation(context).lbl_tag_friends,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        BlocBuilder<AddPostBloc, AddPostState>(
                          bloc: widget.searchPeopleBloc,
                          builder: (context, state) {
                            final count = widget.searchPeopleBloc
                                .selectedSearchPeopleData.length;
                            return Text(
                              count > 0
                                  ? '$count friend${count > 1 ? 's' : ''} tagged'
                                  : 'Mention people in your post',
                              style: TextStyle(
                                color: count > 0
                                    ? theme.primary
                                    : theme.textTertiary,
                                fontSize: 12,
                                fontWeight: count > 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                fontFamily: 'Poppins',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Arrow Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      color: theme.textTertiary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Tagged Friends Preview
        BlocBuilder<AddPostBloc, AddPostState>(
          bloc: widget.searchPeopleBloc,
          builder: (context, state) {
            if (state is PaginationLoadedState &&
                widget.searchPeopleBloc.selectedSearchPeopleData.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.border, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(theme.isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.person_2,
                          size: 14,
                          color: theme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tagged Friends',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Tags Wrap
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget
                          .searchPeopleBloc.selectedSearchPeopleData
                          .map((element) {
                        return _buildTagChip(element, theme);
                      }).toList(),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildTagChip(dynamic element, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(theme.isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primary,
                  theme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${element.firstName?.substring(0, 1).toUpperCase() ?? '?'}',
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
          // Name
          Text(
            '${element.firstName ?? ''} ${element.lastName ?? ''}'.trim(),
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 6),
          // Remove Button
          GestureDetector(
            onTap: () {
              widget.searchPeopleBloc.add(
                SelectFriendEvent(userData: element, isAdd: false),
              );
            },
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: theme.textTertiary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.xmark,
                size: 10,
                color: theme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
