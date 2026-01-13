import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/bloc/meeting_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/shimmer_widget.dart';

/// One UI 8.5 Theme Helper for Search User Screen
class _OneUITheme {
  final bool isDark;
  
  _OneUITheme(BuildContext context) : isDark = Theme.of(context).brightness == Brightness.dark;
  
  // Background colors
  Color get background => isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F7F7);
  Color get surface => isDark ? const Color(0xFF1B2838) : Colors.white;
  Color get surfaceVariant => isDark ? const Color(0xFF2D3E50) : const Color(0xFFF0F0F0);
  
  // Text colors
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1C1C1E);
  Color get textSecondary => isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF8E8E93);
  Color get textTertiary => isDark ? Colors.white.withOpacity(0.5) : const Color(0xFFC7C7CC);
  
  // Accent & semantic colors
  Color get accent => const Color(0xFF0A84FF);
  Color get divider => isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
  Color get border => isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08);
  
  // Shadows
  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  List<BoxShadow> get avatarShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}

class SearchUserScreen extends StatefulWidget {
  String? channel;

  SearchUserScreen({this.channel,super.key});
  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  MeetingBloc meetingBloc = MeetingBloc();

  @override
  void initState() {
    meetingBloc.add(LoadSearchUserEvent(page: 1, keyword: ''));
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      meetingBloc.add(LoadSearchUserEvent(page: 1, keyword: query));
      print('Search query: $query');
    });
  }
  
  int isSending = -1;
  
  @override
  Widget build(BuildContext context) {
    final theme = _OneUITheme(context);
    
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        surfaceTintColor: theme.surface,
        backgroundColor: theme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          translation(context).lbl_search_friends,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: theme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // One UI styled search bar
          Container(
            color: theme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: translation(context).lbl_search_by_name_or_email,
                  hintStyle: TextStyle(
                    color: theme.textTertiary,
                    fontFamily: 'Poppins',
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.search,
                      color: theme.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // User list
          BlocBuilder<MeetingBloc, MeetingState>(
            bloc: meetingBloc,
            builder: (context, state) {
              if (state is MeetingsLoading) {
                return const Expanded(child: UserShimmer());
              } else if (state is MeetingsLoaded) {
                var bloc = meetingBloc;
                if (bloc.searchContactsList.isNotEmpty) {
                  return Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        if (bloc.contactPageNumber <= bloc.contactNumberOfPage) {
                          if (index == bloc.searchContactsList.length - bloc.nextPageTrigger) {
                            bloc.add(CheckIfNeedMoreUserDataEvent(index: index, query: _searchController.text));
                          }
                        }
                        if (bloc.contactNumberOfPage != bloc.contactPageNumber - 1 &&
                            index >= bloc.searchContactsList.length - 1) {
                          return const SizedBox(height: 200, child: UserShimmer());
                        } else {
                          return _buildUserCard(bloc, index, theme);
                        }
                      },
                      itemCount: bloc.searchContactsList.length,
                    ),
                  );
                } else {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.surfaceVariant.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_search,
                              color: theme.textTertiary,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            translation(context).msg_no_user_found,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              } else if (state is MeetingsError) {
                return RetryWidget(
                  errorMessage: translation(context).msg_something_went_wrong_retry,
                  onRetry: () {
                    try {
                      meetingBloc.add(LoadSearchUserEvent(page: 1, keyword: _searchController.text));
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  },
                );
              } else {
                return Center(
                  child: Text(
                    translation(context).msg_something_went_wrong,
                    style: TextStyle(color: theme.textSecondary),
                  ),
                );
              }
            },
          ),
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
    );
  }

  Widget _buildUserCard(MeetingBloc bloc, int index, _OneUITheme theme) {
    final contact = bloc.searchContactsList[index];
    final fullName = "${contact.firstName.validate()} ${contact.lastName.validate()}";
    final hasProfilePic = contact.profilePic != null && contact.profilePic!.isNotEmpty;
    
    // Generate avatar color based on name
    final avatarColors = [
      const Color(0xFF34C759), // Green
      const Color(0xFF5856D6), // Purple
      const Color(0xFFFF9500), // Orange
      const Color(0xFFFF2D55), // Pink
      const Color(0xFF00C7BE), // Teal
      const Color(0xFFFFCC00), // Yellow
      const Color(0xFF007AFF), // Blue
      const Color(0xFFAF52DE), // Purple light
    ];
    final avatarColor = avatarColors[fullName.hashCode.abs() % avatarColors.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: theme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            SVProfileFragment(userId: contact.id).launch(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with One UI styling
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: theme.avatarShadow,
                  ),
                  child: hasProfilePic
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: CachedNetworkImage(
                            imageUrl: '${AppData.imageUrl}${contact.profilePic.validate()}',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.surfaceVariant,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.accent,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildInitialsAvatar(fullName, avatarColor),
                          ),
                        )
                      : _buildInitialsAvatar(fullName, avatarColor),
                ),
                const SizedBox(width: 14),
                
                // Name
                Expanded(
                  child: Text(
                    fullName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Send Invite button - One UI styled
                isSending == index
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.accent,
                        ),
                      )
                    : Material(
                        color: theme.accent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () async {
                            isSending = index;
                            setState(() {});
                            await sendInviteMeeting(widget.channel, contact.id).then((invite) {
                              isSending = -1;
                              setState(() {});
                              Map<String, dynamic> responseData = json.decode(jsonEncode(invite.data));
                              toast(responseData['message']);
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Text(
                              translation(context).lbl_send_invite,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInitialsAvatar(String name, Color bgColor) {
    final initials = name.isNotEmpty 
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'U';
    
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
