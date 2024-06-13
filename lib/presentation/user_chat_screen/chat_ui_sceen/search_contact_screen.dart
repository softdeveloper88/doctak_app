import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../home_screen/utils/SVCommon.dart';
import 'chat_room_screen.dart';

class SearchContactScreen extends StatefulWidget {
  @override
  _SearchContactScreenState createState() => _SearchContactScreenState();
}

class _SearchContactScreenState extends State<SearchContactScreen> {
  TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  ChatBloc chatBloc = ChatBloc();

  @override
  void initState() {
    setStatusBarColor(svGetScaffoldColor());

    chatBloc.add(LoadContactsEvent(page: 1, keyword: ''));
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
      chatBloc.add(LoadContactsEvent(page: 1, keyword: query));
      print('Search query: $query');
      // Replace this with your actual search logic and API calls
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        leading: IconButton(
          icon:  Icon(Icons.arrow_back_ios_new_rounded,
              color: svGetBodyColor()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        surfaceTintColor: context.cardColor,
        backgroundColor: context.cardColor,
        centerTitle: true,
        title:  Text('Search Contacts',style: GoogleFonts.poppins(fontSize:16,fontWeight:FontWeight.w500),),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 8.0),
            margin: const EdgeInsets.only(
              left: 16,
              top: 16.0,
              bottom: 16.0,
              right: 16,
            ),
            decoration: BoxDecoration(
                color: context.dividerColor.withOpacity(0.4),
                borderRadius: radius(5),
                border: Border.all(color: Colors.black, width: 0.3)),
            child: Center(
              child: AppTextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textFieldType: TextFieldType.NAME,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search Here ',
                  hintStyle: secondaryTextStyle(color: svGetBodyColor()),
                  suffixIcon: Image.asset('images/socialv/icons/ic_Search.png',
                          height: 16,
                          width: 16,
                          fit: BoxFit.cover,
                          color: svGetBodyColor())
                      .paddingAll(16),
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
          BlocConsumer<ChatBloc, ChatState>(
            bloc: chatBloc,
            // listenWhen: (previous, current) => current is SearchPeopleState,
            // buildWhen: (previous, current) => current is! SearchPeopleState,
            listener: (BuildContext context, ChatState state) {
              if (state is DataError) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text(state.errorMessage),
                  ),
                );
              }
            },

            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return  Expanded(
                    child: Center(child: CircularProgressIndicator(color: svGetBodyColor(),)));
              } else if (state is PaginationLoadedState) {
                // print(state.drugsModel.length);
                // return _buildPostList(context);
                var bloc = chatBloc;
                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (bloc.contactPageNumber <= bloc.contactNumberOfPage) {
                        if (index ==
                            bloc.searchContactsList.length -
                                bloc.contactNextPageTrigger) {
                          bloc.add(
                              CheckIfNeedMoreContactDataEvent(index: index));
                        }
                      }
                      return bloc.contactNumberOfPage !=
                                  bloc.contactPageNumber - 1 &&
                              index >= bloc.searchContactsList.length - 1
                          ?  Center(
                              child: CircularProgressIndicator(color: svGetBodyColor(),),
                            )
                          :
                          // Padding(
                          //       padding: const EdgeInsets.all(8.0),
                          //       child: Material(
                          //                               elevation: 2,
                          //                               shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(8),
                          //                               ),
                          //                               child: Padding(
                          //       padding: const EdgeInsets.all(10.0),
                          //       child: ListTile(
                          //         leading:GestureDetector(
                          //           onTap: (){
                          //             SVProfileFragment(userId:bloc.searchContactsList[index].id).launch(context);
                          //
                          //           },
                          //           child: Container(
                          //             width: 60,
                          //             height: 60,
                          //             decoration: BoxDecoration(
                          //               shape: BoxShape.circle,
                          //               boxShadow: [
                          //                 BoxShadow(
                          //                   color: Colors.grey.withOpacity(0.5),
                          //                   spreadRadius: 2,
                          //                   blurRadius: 5,
                          //                   offset: const Offset(0, 3),
                          //                 ),
                          //               ],
                          //             ),
                          //             child: CircleAvatar(
                          //               radius: 30,
                          //               backgroundImage: CachedNetworkImageProvider(
                          //                 '${AppData.imageUrl}${bloc.searchContactsList[index].profilePic}',
                          //               ),
                          //             ),
                          //           ),
                          //         ),
                          //         // GestureDetector(
                          //         //   onTap: (){
                          //         //     SVProfileFragment(userId:bloc.searchContactsList[index].id).launch(context);
                          //         //   },
                          //         //   child: CircleAvatar(
                          //         //     radius: 30,
                          //         //     backgroundImage: CachedNetworkImageProvider(
                          //         //         '${AppData.imageUrl}${bloc.searchContactsList[index].profilePic}'
                          //         //     ),
                          //         //   ),
                          //         // ),
                          //         title: Text(
                          //           '${bloc.searchContactsList[index].firstName} ${bloc.searchContactsList[index].lastName}',
                          //           style: const TextStyle(
                          //             fontWeight: FontWeight.bold,
                          //             fontSize: 16,
                          //           ),
                          //         ),
                          //         trailing: const Icon(
                          //           Icons.chat, // Use the chat icon or any other icon you prefer
                          //           color: Colors.blue, // Set the color of the icon
                          //         ),
                          //         onTap: () {
                          //           ChatRoomScreen(username: '${bloc.searchContactsList[index].firstName} ${bloc.searchContactsList[index].lastName}',profilePic: '${bloc.searchContactsList[index].profilePic}',id: '${bloc.searchContactsList[index].id}',roomId: '',).launch(context);
                          //
                          //           // Add navigation logic or any other action on contact tap
                          //         },
                          //       ),
                          //                               ),
                          //                             ),
                          //     );
                          Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InkWell(
                                onTap: () {
                                  ChatRoomScreen(
                                    username:
                                        '${bloc.searchContactsList[index].firstName??''} ${bloc.searchContactsList[index].lastName??""}',
                                    profilePic:
                                        '${bloc.searchContactsList[index].profilePic}',
                                    id: '${bloc.searchContactsList[index].id}',
                                    roomId: '',
                                  ).launch(context);

                                  // ChatRoomScreen(
                                  //   username:
                                  //   '${bloc.searchContactsList[index].firstName} ${bloc.searchContactsList[index].lastName}',
                                  //   profilePic:
                                  //   '${bloc.searchContactsList[index].profilePic}',
                                  //   id: '',
                                  //   roomId:
                                  //   '${bloc.searchContactsList[index].roomId}',
                                  // ).launch(context);

                                  // Add navigation logic or any other action on contact tap
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
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
                                                      spreadRadius: 2,
                                                      blurRadius: 5,
                                                      offset:
                                                          const Offset(0, 3),
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
                                                                '${AppData.imageUrl}${bloc.searchContactsList[index].profilePic.validate()}',
                                                            height: 56,
                                                            width: 56,
                                                            fit: BoxFit.cover)
                                                        .cornerRadiusWithClipRRect(
                                                            30),
                                              ),
                                            ),
                                            10.width,
                                            SizedBox(
                                              width: 70.w,
                                              child: Text(
                                                  "${bloc.searchContactsList[index].firstName.validate()} ${bloc.searchContactsList[index].lastName.validate()}",
                                                  overflow: TextOverflow.clip,
                                                  style: GoogleFonts.poppins(
                                                      color: svGetBodyColor(),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // isLoading ? const CircularProgressIndicator(color: svGetBodyColor(),):  AppButton(
                                      //   shapeBorder: RoundedRectangleBorder(borderRadius: radius(10)),
                                      //   text:widget.element.isFollowedByCurrentUser == true ? 'Unfollow':'Follow',
                                      //   textStyle: boldTextStyle(color:  widget.element.isFollowedByCurrentUser != true ?SVAppColorPrimary:buttonUnSelectColor,size: 10),
                                      //   onTap:  () async {
                                      //     setState(() {
                                      //       isLoading = true; // Set loading state to true when button is clicked
                                      //     });
                                      //
                                      //     // Perform API call
                                      //     widget.onTap();
                                      //
                                      //     setState(() {
                                      //       isLoading = false; // Set loading state to false after API response
                                      //     });
                                      //   },
                                      //   elevation: 0,
                                      //   color: widget.element.isFollowedByCurrentUser == true ?SVAppColorPrimary:buttonUnSelectColor,
                                      // ),
                                      // ElevatedButton(
                                      //   // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      //   onPressed: () async {
                                      //     setState(() {
                                      //       isLoading = true; // Set loading state to true when button is clicked
                                      //     });
                                      //
                                      //     // Perform API call
                                      //     await widget.onTap();
                                      //
                                      //     setState(() {
                                      //       isLoading = false; // Set loading state to false after API response
                                      //     });
                                      //   },
                                      //   child: isLoading
                                      //       ? CircularProgressIndicator(color: svGetBodyColor(),) // Show progress indicator if loading
                                      //       : Text(widget.element.isFollowedByCurrentUser == true ? 'Unfollow' : 'Follow', style: boldTextStyle(color: Colors.white, size: 10)),
                                      //   style: ElevatedButton.styleFrom(
                                      //     // primary: Colors.blue, // Change button color as needed
                                      //     elevation: 0,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                      // SVProfileFragment().launch(context);
                    },
                    itemCount: bloc.searchContactsList.length,
                  ),
                );
              } else if (state is DataError) {
                return Expanded(
                  child: Center(
                    child: Text(state.errorMessage),
                  ),
                );
              } else {
                return const Expanded(
                    child: Center(child: Text('Something went wrong')));
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
