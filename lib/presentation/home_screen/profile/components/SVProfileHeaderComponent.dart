import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/network/custom_cache_manager.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/unified_gallery_picker.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/presentation/followers_screen/follower_screen.dart';
import 'package:doctak_app/presentation/network_screen/network_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/profile_image_screen/profile_image_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/components/moderation/block_user_dialog.dart';
import 'package:doctak_app/widgets/communication/communication_gate.dart';
import 'package:doctak_app/presentation/home_screen/home/components/moderation/report_content_bottom_sheet.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'SVProfilePostsComponent.dart';

// ── Primary blue matching the design reference ──
const Color _kPrimary = Color(0xFF1D4ED8);

// ── Frosted glass circle button used on the cover area ──
class _CoverButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CoverButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}

// ── Stat item used inside the stats card ──
class StatItem extends StatelessWidget {
  final String count;
  final String label;
  final Function() onTap;
  final IconData icon;
  final bool showBorder;

  const StatItem({
    required this.count,
    required this.label,
    required this.onTap,
    required this.icon,
    this.showBorder = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: showBorder
              ? BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(
                      color: theme.isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                )
              : null,
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontFamily: 'Inter',
                  color: theme.isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SVProfileHeaderComponent extends StatefulWidget {
  UserProfile? userProfile;
  ProfileBloc? profileBoc;
  bool? isMe;
  bool viewAsPublic;

  SVProfileHeaderComponent({
    this.userProfile,
    this.profileBoc,
    this.isMe,
    this.viewAsPublic = false,
    super.key,
  });

  @override
  State<SVProfileHeaderComponent> createState() =>
      _SVProfileHeaderComponentState();
}

class _SVProfileHeaderComponentState extends State<SVProfileHeaderComponent>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _profileImageAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _profileImageAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════
          //  COVER IMAGE + OVERLAY BUTTONS
          // ═══════════════════════════════════════════
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Non-positioned child to define the Stack size including overflow area
              // 200px cover + 60px space for avatar/buttons overflow
              const SizedBox(height: 260, width: double.infinity),
              // ── Cover image ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                onTap: () => ProfileImageScreen(
                  imageUrl: '${widget.userProfile?.coverPicture}',
                ).launch(context),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [const Color(0xFFDBEAFE), const Color(0xFFEFF6FF)],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCoverImage(),
                      // Subtle gradient overlay like the reference
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),

              // ── Overlay action buttons ──
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button (other users) or empty space (own profile)
                    if (!(widget.isMe ?? false))
                      _CoverButton(
                        icon: Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward_ios
                            : Icons.arrow_back_ios_new,
                        onTap: () => Navigator.pop(context),
                      )
                    else
                      const SizedBox(width: 40),
                    // Right-side actions
                    Row(
                      children: [
                        if (widget.isMe ?? false)
                          _CoverButton(
                            icon: Icons.camera_alt_outlined,
                            onTap: () async {
                              final hasPermission =
                                  await PermissionUtils.requestGalleryPermissionWithUI(
                                    context, showRationale: false);
                              if (hasPermission) _showFileOptions(false);
                            },
                          ),
                        if (!(widget.isMe ?? false)) ...[
                          _CoverButton(
                            icon: Icons.share,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (!(widget.isMe ?? false))
                          _buildMoreOptionsButton(theme),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Avatar positioned to overlap the cover ──
              PositionedDirectional(
                top: 200 - 56, // half of avatar hangs over cover
                start: 20,
                child: ScaleTransition(
                  scale: _profileImageAnimation,
                  child: _buildAvatar(theme),
                ),
              ),

              // ── Follow + Message buttons (other users) / Camera (own) ──
              PositionedDirectional(
                top: 200 + 8,
                end: 20,
                child: _buildActionButtons(theme),
              ),
            ],
          ),

          // ── Name + Points badge ──
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.userProfile?.user?.firstName ?? ''} ${widget.userProfile?.user?.lastName ?? ''}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isMe ?? false) ...[                  
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          translation(context).lbl_points_format('300'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Specialty + Location ──
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 4),
            child: Row(
              children: [
                if (widget.userProfile?.user?.specialty != null &&
                    widget.userProfile!.user!.specialty!.isNotEmpty) ...[
                  Icon(Icons.medical_services, size: 14, color: _kPrimary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.userProfile!.user!.specialty!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
                if (widget.userProfile?.user?.specialty != null &&
                    widget.userProfile!.user!.specialty!.isNotEmpty &&
                    _hasLocation()) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('•', style: TextStyle(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1), fontSize: 14)),
                  ),
                ],
                if (_hasLocation())
                  Flexible(
                    child: Text(
                      _locationText(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Inter',
                        color: textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          //  STATS CARD
          // ═══════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  StatItem(
                    count: '${widget.userProfile?.totalPosts ?? '0'}',
                    label: translation(context).lbl_posts,
                    onTap: () {},
                    icon: Icons.article_rounded,
                    showBorder: true,
                  ),
                  StatItem(
                    count: '${widget.profileBoc?.fullProfile?.stats?.totalConnections ?? widget.userProfile?.totalFollows?.totalFollowings ?? '0'}',
                    label: translation(context).lbl_connections_short,
                    onTap: () {
                      const NetworkScreen(initialTab: 3).launch(context);
                    },
                    icon: Icons.people_alt_rounded,
                    showBorder: true,
                  ),
                  StatItem(
                    count: widget.userProfile?.totalFollows?.totalFollowers ?? '0',
                    label: translation(context).lbl_followers,
                    onTap: () {
                      final userId = (widget.isMe ?? false)
                          ? AppData.logInUserId
                          : (widget.userProfile?.user?.id ?? '');
                      FollowerScreen(isFollowersScreen: true, userId: userId).launch(context);
                    },
                    icon: Icons.person_add_rounded,
                    showBorder: true,
                  ),
                  StatItem(
                    count: widget.userProfile?.totalFollows?.totalFollowings ?? '0',
                    label: translation(context).lbl_following,
                    onTap: () {
                      final userId = (widget.isMe ?? false)
                          ? AppData.logInUserId
                          : (widget.userProfile?.user?.id ?? '');
                      FollowerScreen(isFollowersScreen: false, userId: userId).launch(context);
                    },
                    icon: Icons.person_add_rounded,
                  ),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════
          //  TAB SECTION
          // ═══════════════════════════════════════════
          SVProfilePostsComponent(widget.profileBoc!, viewAsPublic: widget.viewAsPublic),
        ],
      ),
    );
  }

  // ── Cover image widget ──
  Widget _buildCoverImage() {
    final coverPic = widget.userProfile?.coverPicture;
    final isDefault = coverPic == null ||
        coverPic.isEmpty ||
        coverPic.contains('default-profile-bg.jpg');

    if (isDefault) {
      return Image.asset(
        'assets/images/img_cover.png',
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      key: ValueKey('cover_${coverPic}_${widget.profileBoc?.imageVersion ?? 0}'),
      imageUrl: coverPic!,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      cacheManager: CustomCacheManager(),
      placeholder: (context, url) => Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      errorWidget: (context, url, error) => Image.asset(
        'assets/images/img_cover.png',
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  // ── Avatar with verified badge ──
  Widget _buildAvatar(OneUITheme theme) {
    return Stack(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.isDark ? const Color(0xFF0F172A) : Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => ProfileImageScreen(
              imageUrl: '${widget.userProfile?.profilePicture}',
            ).launch(context),
            child: Hero(
              tag: 'profile-image',
              child: ClipOval(
                child: Container(
                  color: theme.isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: (widget.userProfile?.profilePicture == null || widget.userProfile!.profilePicture!.isEmpty)
                      ? Image.asset(
                          'images/socialv/faces/face_5.png',
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          key: ValueKey(
                              'profile_${widget.userProfile?.profilePicture}_${widget.profileBoc?.imageVersion ?? 0}'),
                          imageUrl: widget.userProfile!.profilePicture!,
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                          cacheManager: CustomCacheManager(),
                          placeholder: (context, url) => Container(
                            width: 104,
                            height: 104,
                            color: theme.isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: theme.primary))),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'images/socialv/faces/face_5.png',
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        // Verified badge (bottom-end)
        PositionedDirectional(
          bottom: 4,
          end: 4,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.isDark ? const Color(0xFF0F172A) : Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(Icons.verified, size: 14, color: Colors.white),
          ),
        ),
        // Camera button for own profile
        if (widget.isMe ?? false)
          PositionedDirectional(
            top: 0,
            end: 0,
            child: GestureDetector(
              onTap: () async {
                final hasPermission =
                    await PermissionUtils.requestGalleryPermissionWithUI(
                        context, showRationale: false);
                if (hasPermission) _showFileOptions(true);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.isDark ? const Color(0xFF0F172A) : Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  // ── Action buttons (Follow/Connect/Message for other users) ──
  Widget _buildActionButtons(OneUITheme theme) {
    if (widget.isMe ?? false) return const SizedBox.shrink();

    final connectionStatus = widget.profileBoc?.fullProfile?.connectionStatus ?? 'none';
    final friendRequestId = widget.profileBoc?.fullProfile?.friendRequestId;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Follow button — pill shaped, filled
        GestureDetector(
          onTap: () {
            if (widget.userProfile!.isFollowing ?? false) {
              widget.profileBoc?.add(
                  SetUserFollow(widget.userProfile?.user?.id ?? '', 'unfollow'));
              widget.userProfile!.isFollowing = false;
            } else {
              widget.profileBoc?.add(
                  SetUserFollow(widget.userProfile?.user?.id ?? '', 'follow'));
              widget.userProfile!.isFollowing = true;
            }
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: (widget.userProfile?.isFollowing ?? false)
                  ? (theme.isDark ? Colors.white12 : const Color(0xFFF1F5F9))
                  : _kPrimary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: (widget.userProfile?.isFollowing ?? false)
                  ? null
                  : [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              (widget.userProfile?.isFollowing ?? false)
                  ? translation(context).lbl_following
                  : translation(context).lbl_follow,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: (widget.userProfile?.isFollowing ?? false)
                    ? theme.textSecondary
                    : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Connect button — pill shaped, outlined or filled based on status
        _buildConnectButton(theme, connectionStatus, friendRequestId),
        const SizedBox(width: 8),
        // Message icon button — outlined circle
        GestureDetector(
          onTap: () {
            final userId = '${widget.userProfile?.user?.id}';
            final userName = '${widget.userProfile?.user?.firstName} ${widget.userProfile?.user?.lastName}';
            CommunicationGate.guardMessage(
              context: context,
              targetUserId: userId,
              targetUserName: userName,
              onAllowed: () {
                ChatRoomScreen(
                  username: userName,
                  profilePic: '${widget.userProfile?.profilePicture ?? ''}',
                  id: userId,
                  conversationId: 0,
                ).launch(context);
              },
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: theme.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              size: 20,
              color: theme.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectButton(OneUITheme theme, String connectionStatus, String? friendRequestId) {
    final userId = widget.userProfile?.user?.id ?? '';

    // Already connected — show checkmark pill
    if (connectionStatus == 'connected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.isDark ? const Color(0xFF1E3A2F) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: const Color(0xFF059669)),
            const SizedBox(width: 4),
            Text(
              translation(context).lbl_connections_short,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: Color(0xFF059669),
              ),
            ),
          ],
        ),
      );
    }

    // Pending sent — show "Pending" with cancel on tap
    if (connectionStatus == 'pending_sent') {
      return GestureDetector(
        onTap: () {
          if (friendRequestId != null && friendRequestId.isNotEmpty) {
            widget.profileBoc?.add(CancelConnectionRequestEvent(friendRequestId));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.isDark ? Colors.white12 : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 15,
                  color: theme.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                translation(context).lbl_pending,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  color: theme.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No connection / rejected / cancelled — show "Connect" button
    return GestureDetector(
      onTap: () {
        widget.profileBoc?.add(SendConnectionRequestEvent(userId));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _kPrimary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add_alt_1_rounded, size: 16, color: _kPrimary),
            const SizedBox(width: 4),
            Text(
              translation(context).lbl_connect,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: _kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── More options button (report / block) ──
  Widget _buildMoreOptionsButton(OneUITheme theme) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardBackground,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.more_vert, size: 20,
                color: theme.isDark ? Colors.white70 : Colors.grey[700]),
          ),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'Report',
          child: Row(
            children: [
              Icon(CupertinoIcons.flag, color: theme.warning, size: 20),
              const SizedBox(width: 12),
              Text(translation(context).lbl_report_user,
                  style: TextStyle(
                      color: theme.warning,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Block',
          child: Row(
            children: [
              Icon(CupertinoIcons.hand_raised, color: theme.deleteRed, size: 20),
              const SizedBox(width: 12),
              Text(translation(context).lbl_block_user,
                  style: TextStyle(
                      color: theme.deleteRed,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'Report') {
          ReportContentBottomSheet.show(
            context: context,
            contentId: widget.userProfile?.user?.id ?? '',
            contentType: 'user',
            contentOwnerName:
                '${widget.userProfile?.user?.firstName ?? ''} ${widget.userProfile?.user?.lastName ?? ''}',
          );
        } else if (value == 'Block') {
          BlockUserDialog.show(
            context: context,
            userId: widget.userProfile?.user?.id ?? '',
            userName:
                '${widget.userProfile?.user?.firstName ?? ''} ${widget.userProfile?.user?.lastName ?? ''}',
            onUserBlocked: () => Navigator.of(context).pop(),
          );
        }
      },
    );
  }

  // ── Helpers ──
  bool _hasLocation() {
    final user = widget.userProfile?.user;
    return (user?.state != null && user!.state!.isNotEmpty) ||
        (user?.country != null && user!.country!.isNotEmpty);
  }

  String _locationText() {
    final user = widget.userProfile?.user;
    final parts = <String>[];
    if (user?.state != null && user!.state!.isNotEmpty) parts.add(user.state!);
    if (user?.country != null && user!.country!.isNotEmpty) parts.add(user.country!);
    return parts.join(', ');
  }

  // ignore: unused_field
  File? _selectedFile;

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
