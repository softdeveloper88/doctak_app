import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/followers_screen/bloc/followers_bloc.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/profile_list_item_card.dart';
import 'package:flutter/material.dart';

class FollowerWidget extends StatefulWidget {
  final dynamic element;
  final String userId;
  final Function onTap;
  final FollowersBloc bloc;
  final bool showMutualIndicator;
  final bool isFollowersScreen;

  const FollowerWidget({
    super.key,
    required this.element,
    required this.onTap,
    required this.bloc,
    required this.userId,
    this.showMutualIndicator = false,
    this.isFollowersScreen = false,
  });

  @override
  State<FollowerWidget> createState() => _FollowerWidgetState();
}

class _FollowerWidgetState extends State<FollowerWidget> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    preloadSpecialties().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isOwn = widget.userId == AppData.logInUserId;

    Widget? trailingWidget;
    if (isOwn) {
      trailingWidget = !isLoading
          ? ProfileListActionButton(
              label: widget.element.isCurrentlyFollow == true
                  ? translation(context).lbl_unfollow
                  : translation(context).lbl_follow,
              icon: widget.element.isCurrentlyFollow == true
                  ? Icons.person_remove_outlined
                  : Icons.person_add_outlined,
              color: theme.primary,
              filled: widget.element.isCurrentlyFollow == true,
              compact: true,
              onTap: () async {
                setState(() => isLoading = true);
                try {
                  await widget.onTap();
                } finally {
                  if (mounted) setState(() => isLoading = false);
                }
              },
            )
          : SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              ),
            );
    }

    return ProfileListItemCard(
      title: (widget.element.name?.toString().trim().isNotEmpty == true)
          ? widget.element.name
          : 'Unknown',
      subtitle: capitalizeWords(
        specialtyLabelOrNull(widget.element.specialty?.toString()) ?? 'Doctor',
      ),
      metaText: widget.showMutualIndicator ? '↩ Follows you back' : null,
      avatarUrl: widget.element.profilePic ?? '',
      onTap: () {
        ProfileNavigation.openUser(context, widget.element.id?.toString());
      },
      titleSuffix: widget.element.isVerified == true
          ? const VerifiedBadge(size: 16)
          : null,
      trailing: trailingWidget,
    );
  }
}

