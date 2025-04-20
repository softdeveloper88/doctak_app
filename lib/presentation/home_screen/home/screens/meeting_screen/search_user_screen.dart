import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/bloc/meeting_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/bloc/meeting_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/bloc/meeting_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../../../user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import '../../../utils/shimmer_widget.dart';


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
    setStatusBarColor(svGetScaffoldColor());

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
      // Replace this with your actual search logic and API calls
    });
  }
  int isSending=-1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        surfaceTintColor: context.cardColor,
        backgroundColor: context.cardColor,
        centerTitle: false,
        title: const Text(
          'Search Friends',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: svGetScaffoldColor(),
            padding: const EdgeInsets.all(10.0),
            child: Container(
              padding: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                  color: context.dividerColor.withOpacity(0.4),
                  borderRadius: radius(5),
                  border: Border.all(color: Colors.black, width: 0.5)),
              child: Center(
                child: AppTextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textFieldType: TextFieldType.NAME,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search by name or email ',
                    hintStyle: secondaryTextStyle(
                      color: svGetBodyColor(),
                      fontFamily: 'Poppins',
                    ),
                    suffixIcon: Image.asset(
                        'images/socialv/icons/ic_Search.png',
                        height: 16,
                        width: 16,
                        fit: BoxFit.cover,
                        color: svGetBodyColor())
                        .paddingAll(16),
                  ),
                ),
              ),
            ),
          ),
          // TextField(
          //   controller: _searchController,
          //   decoration: InputDecoration(
          //     labelText: 'Search',
          //     hintText: 'Enter your search query...',
          //     prefixIcon: const Icon(Icons.search),
          //     border: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(10.0),
          //     ),
          //   ),
          //   onChanged: _onSearchChanged,
          // ),
          BlocBuilder<MeetingBloc, MeetingState>(
            bloc: meetingBloc,
            // listenWhen: (previous, current) => current is SearchPeopleState,
            // buildWhen: (previous, current) => current is! SearchPeopleState,
            // listener: (BuildContext context, MeetingState state) {
            //   if (state is DataError) {
            //     showDialog(
            //       context: context,
            //       builder: (context) => AlertDialog(
            //         content: Text(''),
            //       ),
            //     );
            //   }
            // },

            builder: (context, state) {
              if (state is MeetingsLoading) {
                return const Expanded(child: UserShimmer());
              } else if (state is MeetingsLoaded) {
                // print(state.drugsModel.length);
                // return _buildPostList(context);
                var bloc = meetingBloc;
                if(bloc.searchContactsList.isNotEmpty) {
                  return Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      // physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        if (bloc.contactPageNumber <=
                            bloc.contactNumberOfPage) {
                          if (index ==
                              bloc.searchContactsList.length -
                                  bloc.nextPageTrigger) {
                            bloc.add(CheckIfNeedMoreUserDataEvent(index: index,query: _searchController.text));
                          }
                        }
                        if (bloc.contactNumberOfPage !=
                            bloc.contactPageNumber - 1 &&
                            index >= bloc.searchContactsList.length - 1) {
                          return const SizedBox(
                              height: 200,
                              child: UserShimmer());
                        } else {
                          return Container(
                            margin: const EdgeInsets.only(
                                top: 8.0, left: 8.0, right: 8.0),
                            decoration: BoxDecoration(
                                color: svGetScaffoldColor(),
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () {


                                // Add navigation logic or any other action on contact tap
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 10),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        SVProfileFragment(
                                            userId: bloc
                                                .searchContactsList[
                                            index]
                                                .id)
                                            .launch(context);
                                      },
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey
                                                  .withOpacity(0.5),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: bloc
                                            .searchContactsList[
                                        index]
                                            .profilePic ==
                                            ''
                                            ? Image.asset(
                                            'images/socialv/faces/face_5.png',
                                            height: 56,
                                            width: 56,
                                            fit: BoxFit.cover)
                                            .cornerRadiusWithClipRRect(
                                            8)
                                            .cornerRadiusWithClipRRect(
                                            8)
                                            : CachedNetworkImage(
                                            imageUrl:
                                            '${AppData.imageUrl}${bloc
                                                .searchContactsList[index]
                                                .profilePic.validate()}',
                                            height: 56,
                                            width: 56,
                                            fit: BoxFit.cover)
                                            .cornerRadiusWithClipRRect(
                                            30),
                                      ),
                                    ),
                                    10.width,
                                    Expanded(
                                      child: Text(
                                          "${bloc
                                              .searchContactsList[index]
                                              .firstName
                                              .validate()} ${bloc
                                              .searchContactsList[index]
                                              .lastName.validate()}",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: svGetBodyColor(),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16)),
                                    ),
                                   isSending==index?const CircularProgressIndicator(): MaterialButton(
                                      color: Colors.blue,
                                      minWidth: 80,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)
                                      ),
                                      onPressed: () async {
                                        isSending=index;
                                        setState(() {});
                                        await sendInviteMeeting(widget.channel,bloc
                                            .searchContactsList[index].id).then((invite){
                                          isSending=-1;
                                          setState(() {});
                                          Map<String, dynamic> responseData = json.decode(jsonEncode(invite.data));
                                             toast(responseData['message']);
                                        });
                                      },
                                      child: const Text('Send Invite',style: TextStyle(color: Colors.white,fontSize: 14),),)
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        // SVProfileFragment().launch(context);
                      },
                      itemCount: bloc.searchContactsList.length,
                    ),
                  );
                }else{
                  return const Expanded(child: Center(child: Text('No user found',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,fontFamily: 'Poppins'),)));

                }
              } else if (state is MeetingsError) {
                return RetryWidget(
                    errorMessage: "Something went wrong please try again",
                    onRetry: () {
                      try {
                        meetingBloc.add(LoadSearchUserEvent(page: 1, keyword: _searchController.text,));
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    });
              } else {
                return const Center(child: Text('Something went wrong'));
              }
            },
          ),
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()

          // Add your list or search results display here
        ],
      ),
    );
  }
}
