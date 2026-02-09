import 'dart:io';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/unified_gallery_picker.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/presentation/followers_screen/follower_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/profile_image_screen/profile_image_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/components/moderation/block_user_dialog.dart';
import 'package:doctak_app/presentation/home_screen/home/components/moderation/report_content_bottom_sheet.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import 'SVProfilePostsComponent.dart';

// Stat item widget for posts/followers/following with improved design
class StatItem extends StatelessWidget {
  final String count;
  final String label;
  final Function() onTap;
  final IconData icon;

  const StatItem({
    required this.count,
    required this.label,
    required this.onTap,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: theme.primary),
                const SizedBox(width: 6),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SVProfileHeaderComponent extends StatefulWidget {
  UserProfile? userProfile;
  ProfileBloc? profileBoc;
  bool? isMe;

  SVProfileHeaderComponent({
    this.userProfile,
    this.profileBoc,
    this.isMe,
    super.key,
  });

  @override
  State<SVProfileHeaderComponent> createState() =>
      _SVProfileHeaderComponentState();
}

// Points card with improved design
Widget _buildPointsCard(BuildContext context) {
  final theme = OneUITheme.of(context);
  return Card(
    elevation: theme.isDark ? 0 : 2.0,
    color: theme.cardBackground,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: theme.primary.withValues(alpha: 0.2), width: 1),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                translation(context).lbl_your_earned_points,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '300',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SVProfileHeaderComponentState extends State<SVProfileHeaderComponent>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _headerController;
  late Animation<double> _profileImageAnimation;
  late Animation<double> _headerOpacityAnimation;
  late Animation<double> _headerScaleAnimation;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();

    // Profile image animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Header collapse animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _profileImageAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _headerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeInOut),
    );

    _headerScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    // Add scroll listener for smooth header effects
    _scrollController.addListener(_onScroll);

    // Start animations
    _controller.forward();
    _headerController.forward();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _isHeaderCollapsed = _scrollOffset > 200;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _headerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 80),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Background Image with gradient overlay
              InkWell(
                onTap: () {
                  ProfileImageScreen(
                    imageUrl: '${widget.userProfile?.coverPicture}',
                  ).launch(context);
                },
                child: Container(
                  height: 260,
                  width: double.maxFinite,
                  decoration: const BoxDecoration(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover image - now fills entire space
                      widget.userProfile?.coverPicture == null ||
                              widget.userProfile?.coverPicture ==
                                  'public/new_assets/assets/images/page-img/default-profile-bg.jpg'
                          ? Image.asset(
                              'assets/images/img_cover.png',
                              width: double.maxFinite,
                              height: 260,
                              fit: BoxFit.cover,
                            )
                          : CustomImageView(
                              imagePath: widget.userProfile?.coverPicture ?? '',
                              height: 260,
                              width: double.maxFinite,
                              fit: BoxFit.cover,
                              placeHolder: 'assets/images/img_cover.png',
                            ),

                      // Gradient overlay
                      Container(
                        width: double.maxFinite,
                        height: 260,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Back button with improved styling
              if (!(widget.isMe ?? false))
                Positioned(
                  top: 40,
                  left: 16,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.cardBackground,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: theme.border, width: 1),
                      boxShadow: theme.isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back_ios,
                        size: 18,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                ),

              // Camera icon for cover photo with improved styling
              if (widget.isMe ?? false)
                Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    onPressed: () async {
                      // Use PermissionUtils for proper permission handling on both iOS and Android
                      final hasPermission =
                          await PermissionUtils.requestGalleryPermissionWithUI(
                            context,
                            showRationale: false,
                          );

                      if (hasPermission) {
                        _showFileOptions(false);
                      }
                    },
                    icon: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: theme.primary,
                        border: Border.all(
                          color: theme.scaffoldBackground,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: theme.isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                ),
                              ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),

              // Curved top for profile content
              Positioned(
                top: 230,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: theme.isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, -2),
                            ),
                          ],
                  ),
                ),
              ),

              // Profile picture with animated scale effect
              Positioned(
                right: (100.w / 2) - 60,
                top: 180,
                child: ScaleTransition(
                  scale: _profileImageAnimation,
                  child: Stack(
                    children: [
                      // Profile Picture with improved styling
                      Container(
                        margin: const EdgeInsets.all(10),
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.scaffoldBackground,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          color: theme.surfaceVariant,
                          boxShadow: theme.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ],
                        ),
                        child: Hero(
                          tag: 'profile-image',
                          child: ClipOval(
                            child: widget.userProfile?.profilePicture == null
                                ? Image.asset(
                                    'images/socialv/faces/face_5.png',
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  )
                                : CustomImageView(
                                    imagePath:
                                        widget.userProfile?.profilePicture ??
                                        '',
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    placeHolder:
                                        'images/socialv/faces/face_5.png',
                                  ),
                          ),
                        ),
                      ).onTap(() async {
                        ProfileImageScreen(
                          imageUrl: '${widget.userProfile?.profilePicture}',
                        ).launch(context);
                      }),

                      // Camera icon for profile picture with improved styling
                      if (widget.isMe ?? false)
                        Positioned(
                          top: 10,
                          right: 5,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                // Use PermissionUtils for proper permission handling on both iOS and Android
                                final hasPermission =
                                    await PermissionUtils.requestGalleryPermissionWithUI(
                                      context,
                                      showRationale: false,
                                    );

                                if (hasPermission) {
                                  _showFileOptions(true);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: theme.primary,
                                  border: Border.all(
                                    color: theme.scaffoldBackground,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: theme.isDark
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 5,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: [
              // Profile Image
              const SizedBox(height: 30),

              // User name with verification badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${widget.userProfile?.user?.firstName ?? ''} ${widget.userProfile?.user?.lastName ?? ''}',
                    style: TextStyle(
                      color: svGetBodyColor(),
                      fontSize: 20, // Increased font size
                      fontWeight: FontWeight.w600,
                    ),
                  ), // Made font bolder
                  8.width, // More spacing
                  Image.asset(
                    'images/socialv/icons/ic_TickSquare.png',
                    height: 16,
                    width: 16,
                    fit: BoxFit.cover,
                  ),
                ],
              ),

              // Location information
              SizedBox(
                width: 80.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 14, color: theme.primary),
                    4.width,
                    Text(
                      '${widget.userProfile?.user?.state ?? ''} ${widget.userProfile?.user?.state != null ? ',' : ''}${widget.userProfile?.user?.country ?? ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500, // Made font bolder
                      ),
                    ),
                  ],
                ),
              ),

              // Specialty
              if (widget.userProfile?.user?.specialty != null &&
                  widget.userProfile!.user!.specialty!.isNotEmpty)
                SizedBox(
                  width: 80.w,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 14,
                        color: theme.primary,
                      ),
                      4.width,
                      Flexible(
                        child: Text(
                          widget.userProfile?.user?.specialty ?? '',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: svGetBodyColor(),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // About me text
              if (widget.userProfile?.profile?.aboutMe != null &&
                  widget.userProfile!.profile!.aboutMe!.isNotEmpty)
                Container(
                  width: 90.w,
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    widget.userProfile?.profile?.aboutMe ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: svGetBodyColor(),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),

              // Points card for the user's own profile
              if (widget.isMe ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: _buildPointsCard(context),
                ),

              // Message and Follow buttons for other users' profiles
              if (widget.isMe != true)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Message button with improved styling
                      InkWell(
                        onTap: () {
                          ChatRoomScreen(
                            username:
                                '${widget.userProfile?.user?.firstName} ${widget.userProfile?.user?.lastName}',
                            profilePic:
                                '${widget.userProfile?.profilePicture?.replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', '')}',
                            id: '${widget.userProfile?.user?.id}',
                            roomId: '',
                          ).launch(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardBackground,
                            border: Border.all(color: theme.primary),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: theme.isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: theme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/icon/ic_message.svg',
                                color: theme.primary,
                                width: 20,
                                height: 20,
                              ),
                              8.width,
                              Text(
                                translation(context).lbl_message,
                                style: TextStyle(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Follow button with improved styling
                      MaterialButton(
                        height: 40.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minWidth: 110,
                        onPressed: () {
                          if (widget.userProfile!.isFollowing ?? false) {
                            widget.profileBoc?.add(
                              SetUserFollow(
                                widget.userProfile?.user?.id ?? '',
                                'unfollow',
                              ),
                            );

                            widget.userProfile!.isFollowing = false;
                          } else {
                            widget.profileBoc?.add(
                              SetUserFollow(
                                widget.userProfile?.user?.id ?? '',
                                'follow',
                              ),
                            );

                            widget.userProfile!.isFollowing = true;
                          }
                          setState(() {});
                        },
                        elevation: theme.isDark ? 0 : 2,
                        color: widget.userProfile?.isFollowing ?? false
                            ? theme.surfaceVariant
                            : SVAppColorPrimary,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.userProfile?.isFollowing ?? false
                                  ? Icons.check
                                  : Icons.person_add_alt_1_rounded,
                              color: widget.userProfile?.isFollowing ?? false
                                  ? theme.textSecondary
                                  : Colors.white,
                              size: 18,
                            ),
                            6.width,
                            Text(
                              widget.userProfile?.isFollowing ?? false
                                  ? translation(context).lbl_following
                                  : translation(context).lbl_follow,
                              style: TextStyle(
                                color: widget.userProfile?.isFollowing ?? false
                                    ? theme.textSecondary
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // More options (Report/Block) button
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: theme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.border),
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            CupertinoIcons.ellipsis,
                            color: theme.textSecondary,
                            size: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: theme.cardBackground,
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          itemBuilder: (context) => [
                            // Report User option
                            PopupMenuItem(
                              value: 'Report',
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.flag,
                                    color: theme.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Report User',
                                    style: TextStyle(
                                      color: theme.warning,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Block User option
                            PopupMenuItem(
                              value: 'Block',
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.hand_raised,
                                    color: theme.deleteRed,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Block User',
                                    style: TextStyle(
                                      color: theme.deleteRed,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'Report') {
                              // Show report bottom sheet
                              ReportContentBottomSheet.show(
                                context: context,
                                contentId:
                                    int.tryParse(
                                      widget.userProfile?.user?.id ?? '0',
                                    ) ??
                                    0,
                                contentType: 'user',
                                contentOwnerName:
                                    '${widget.userProfile?.user?.firstName ?? ''} ${widget.userProfile?.user?.lastName ?? ''}',
                              );
                            } else if (value == 'Block') {
                              // Show block dialog
                              BlockUserDialog.show(
                                context: context,
                                userId:
                                    int.tryParse(
                                      widget.userProfile?.user?.id ?? '0',
                                    ) ??
                                    0,
                                userName:
                                    '${widget.userProfile?.user?.firstName ?? ''} ${widget.userProfile?.user?.lastName ?? ''}',
                                onUserBlocked: () {
                                  // Navigate back after blocking
                                  Navigator.of(context).pop();
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Stats row (posts, followers, following)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.border, width: 1),
                    bottom: BorderSide(color: theme.border, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Posts stat
                    GestureDetector(
                      onTap: () {},
                      child: StatItem(
                        count: '${widget.userProfile?.totalPosts ?? ''}',
                        label: translation(context).lbl_posts,
                        onTap: () {},
                        icon: Icons.article_rounded,
                      ),
                    ),

                    // Followers stat
                    GestureDetector(
                      onTap: () {
                        if (!(widget.isMe ?? false)) {
                          FollowerScreen(
                            isFollowersScreen: true,
                            userId: widget.userProfile?.user?.id ?? '',
                          ).launch(context);
                        } else {
                          FollowerScreen(
                            isFollowersScreen: true,
                            userId: AppData.logInUserId,
                          ).launch(context);
                        }
                      },
                      child: StatItem(
                        count:
                            widget.userProfile?.totalFollows?.totalFollowings ??
                            '',
                        label: translation(context).lbl_followers,
                        onTap: () {
                          if (!(widget.isMe ?? false)) {
                            FollowerScreen(
                              isFollowersScreen: true,
                              userId: widget.userProfile?.user?.id ?? '',
                            ).launch(context);
                          } else {
                            FollowerScreen(
                              isFollowersScreen: true,
                              userId: AppData.logInUserId,
                            ).launch(context);
                          }
                        },
                        icon: Icons.people_alt_rounded,
                      ),
                    ),

                    // Following stat
                    GestureDetector(
                      onTap: () {
                        if (!(widget.isMe ?? false)) {
                          FollowerScreen(
                            isFollowersScreen: false,
                            userId: widget.userProfile?.user?.id ?? '',
                          ).launch(context);
                        } else {
                          FollowerScreen(
                            isFollowersScreen: false,
                            userId: AppData.logInUserId,
                          ).launch(context);
                        }
                      },
                      child: StatItem(
                        count:
                            widget.userProfile?.totalFollows?.totalFollowers ??
                            '',
                        label: translation(context).lbl_followings,
                        onTap: () {
                          if (!(widget.isMe ?? false)) {
                            FollowerScreen(
                              isFollowersScreen: false,
                              userId: widget.userProfile?.user?.id ?? '',
                            ).launch(context);
                          } else {
                            FollowerScreen(
                              isFollowersScreen: false,
                              userId: AppData.logInUserId,
                            ).launch(context);
                          }
                        },
                        icon: Icons.person_add_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              Container(color: svGetBgColor(), height: 10),

              // Profile posts component
              SVProfilePostsComponent(widget.profileBoc!),
            ],
          ),
        ],
      ),
    );
  }

  var _selectedFile;

  // Use unified gallery picker for consistent experience
  void _showFileOptions(bool isProfilePic) {
    _pickFromUnifiedGallery(isProfilePic);
  }

  Future<void> _pickFromUnifiedGallery(bool isProfilePic) async {
    final File? file = await UnifiedGalleryPicker.pickSingleImage(
      context,
      title: isProfilePic
          ? translation(context).lbl_update_profile_picture
          : translation(context).lbl_update_cover_photo,
    );

    if (file != null) {
      setState(() {
        _selectedFile = file;
        widget.profileBoc!.add(
          UpdateProfilePicEvent(
            filePath: file.path,
            isProfilePicture: isProfilePic,
          ),
        );
      });
    }
  }
}
