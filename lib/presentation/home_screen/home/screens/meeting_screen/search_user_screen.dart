import 'dart:async';
import 'dart:convert';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/bloc/meeting_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:doctak_app/widgets/profile_list_item_card.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/shimmer_widget.dart';

/// One UI 8.5 Theme Helper for Search User Screen
class _OneUITheme {
  final OneUITheme shared;

  _OneUITheme(BuildContext context) : shared = OneUITheme.of(context);

  bool get isDark => shared.isDark;
  Color get background => shared.scaffoldBackground;
  Color get surface => shared.cardBackground;
  Color get surfaceVariant => shared.surfaceVariant;
  Color get textPrimary => shared.textPrimary;
  Color get textSecondary => shared.textSecondary;
  Color get textTertiary => shared.textTertiary;
  Color get accent => shared.primary;
  Color get divider => shared.divider;
  Color get border => shared.border;

  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  List<BoxShadow> get avatarShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}

class SearchUserScreen extends StatefulWidget {
  String? channel;

  SearchUserScreen({this.channel, super.key});
  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
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
    meetingBloc.close();
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
      appBar: DoctakSearchableAppBar(
        title: translation(context).lbl_search_friends,
        searchHint: translation(context).lbl_search_by_name_or_email,
        searchController: _searchController,
        onSearchChanged: _onSearchChanged,
        startWithSearch: true,
        showBackButton: true,
      ),
      body: Column(
        children: [
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
                        if (bloc.contactNumberOfPage != bloc.contactPageNumber - 1 && index >= bloc.searchContactsList.length - 1) {
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
                            decoration: BoxDecoration(color: theme.surfaceVariant.withValues(alpha: 0.5), shape: BoxShape.circle),
                            child: Icon(Icons.person_search, color: theme.textTertiary, size: 48),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            translation(context).msg_no_user_found,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.textSecondary),
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
                  child: Text(translation(context).msg_something_went_wrong, style: TextStyle(color: theme.textSecondary)),
                );
              }
            },
          ),
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildUserCard(MeetingBloc bloc, int index, _OneUITheme theme) {
    final contact = bloc.searchContactsList[index];
    final fullName = "${contact.firstName.validate()} ${contact.lastName.validate()}";
    final profilePic = contact.profilePic.validate();

    return ProfileListItemCard(
      title: fullName,
      avatarUrl: profilePic.isNotEmpty ? AppData.fullImageUrl(profilePic) : null,
      onTap: () => ProfileNavigation.openUser(context, contact.id),
      trailing: isSending == index
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.accent),
            )
          : ProfileListActionButton(
              label: translation(context).lbl_send_invite,
              color: theme.accent,
              filled: true,
              compact: true,
              onTap: () async {
                isSending = index;
                setState(() {});
                await sendInviteMeeting(widget.channel, contact.id).then((invite) {
                  isSending = -1;
                  setState(() {});
                  final responseData = json.decode(jsonEncode(invite.data));
                  toast(responseData['message']);
                });
              },
            ),
    );
  }
}
