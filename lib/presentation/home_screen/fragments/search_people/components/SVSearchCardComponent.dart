import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/data/models/search_people_model/search_people_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../bloc/search_people_bloc.dart';

class SVSearchCardComponent extends StatefulWidget {
  final Data element;
  final Function onTap;
  final SearchPeopleBloc bloc;

  const SVSearchCardComponent({
    required this.element,
    required this.onTap,
    required this.bloc,
    super.key,
  });

  @override
  _SVSearchCardComponentState createState() => _SVSearchCardComponentState();
}

class _SVSearchCardComponentState extends State<SVSearchCardComponent> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.cardBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Picture
          _buildProfileAvatar(theme),
          const SizedBox(width: 12),
          // User Info
          Expanded(child: _buildUserInfo(theme)),
          const SizedBox(width: 12),
          // Follow/Unfollow Button
          _buildFollowButton(theme),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(OneUITheme theme) {
    return GestureDetector(
      onTap: () {
        SVProfileFragment(
          userId: widget.element.id,
        ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.avatarBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: widget.element.profilePic?.isEmpty ?? true
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primary.withOpacity(0.15),
                        theme.secondary.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.element.firstName?.substring(0, 1).toUpperCase() ?? 'U'}',
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl:
                      '${AppData.imageUrl}${widget.element.profilePic.validate()}',
                  height: 56,
                  width: 56,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.avatarBackground,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.avatarBackground,
                    child: Center(
                      child: Icon(Icons.person, color: theme.primary, size: 28),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(OneUITheme theme) {
    return GestureDetector(
      onTap: () {
        SVProfileFragment(
          userId: widget.element.id,
        ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  "${widget.element.firstName ?? ''} ${widget.element.lastName ?? ''}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall,
                ),
              ),
              if (widget.element.isFollowedByCurrentUser ?? false) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            capitalizeWords(
              widget.element.specialty ??
                  widget.element.userType ??
                  "Medical Professional",
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.bodySecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton(OneUITheme theme) {
    final bool isFollowing = widget.element.isFollowedByCurrentUser == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? Container(
              width: 90,
              height: 36,
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: theme.radiusFull,
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primary,
                  ),
                ),
              ),
            )
          : InkWell(
              onTap: () async {
                setState(() {
                  isLoading = true;
                });
                await widget.onTap();
                setState(() {
                  isLoading = false;
                });
              },
              borderRadius: theme.radiusFull,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isFollowing
                      ? LinearGradient(
                          colors: [theme.primary, theme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isFollowing ? null : theme.primary.withOpacity(0.1),
                  borderRadius: theme.radiusFull,
                  border: Border.all(
                    color: isFollowing
                        ? Colors.transparent
                        : theme.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  isFollowing
                      ? translation(context).lbl_unfollow
                      : translation(context).lbl_follow,
                  style: TextStyle(
                    color: isFollowing ? Colors.white : theme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
    );
  }
}
