import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/SVCommon.dart';
import 'bloc/likes_bloc.dart';

class LikesListScreen extends StatefulWidget {
  int id;

  LikesListScreen({required this.id, Key? key}) : super(key: key);

  @override
  State<LikesListScreen> createState() => _LikesListScreenState();
}

class _LikesListScreenState extends State<LikesListScreen> {
  LikesBloc likesBloc = LikesBloc();

  @override
  void initState() {
    likesBloc.add(LoadPageEvent(postId: widget.id ?? 0));
    super.initState();
    afterBuildCreated(() {
      setStatusBarColor(context.cardColor);
    });
  }

  @override
  void dispose() {
    // setStatusBarColor(appStore.isDarkMode ? appBackgroundColorDark : SVAppLayoutBackground);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cardColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('People who likes', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon:  Icon(Icons.arrow_back_ios_new_rounded,
                color:svGetBodyColor()),
            onPressed:(){Navigator.pop(context);}
        ),
        actions: const [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: BlocConsumer<LikesBloc, LikesState>(
          bloc: likesBloc,
          // listenWhen: (previous, current) => current is DrugsState,
          // buildWhen: (previous, current) => current is! DrugsState,
          listener: (BuildContext context, LikesState state) {
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

            if (state is DataInitial) {
              return  Center(child: CircularProgressIndicator(color: svGetBodyColor(),));
            } else if (state is PaginationLoadedState) {
              // print(state.drugsModel.length);
              return likesBloc.postLikesList.isEmpty? const Center(child: Text('No Likes'),):Padding(
                padding: const EdgeInsets.only(bottom: 60.0),
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: likesBloc.postLikesList.length,
                    itemBuilder: (context, index) {
                      return  Padding(
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
                                      SVProfileFragment(userId:likesBloc.postLikesList[index].id).launch(context);
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
                                            offset: const Offset(
                                                0, 3),
                                          ),
                                        ],
                                      ),
                                      child: likesBloc.postLikesList
                                          [
                                      index]
                                          .profilePic ==
                                          ''
                                          ? Image.asset(
                                          'images/socialv/faces/face_5.png',
                                          height: 56,
                                          width: 56,
                                          fit: BoxFit
                                              .cover)
                                          .cornerRadiusWithClipRRect(
                                          8)
                                          .cornerRadiusWithClipRRect(
                                          8)
                                          : CachedNetworkImage(
                                          imageUrl:
                                          likesBloc.postLikesList[index].profilePic.validate(),
                                          height: 56,
                                          width: 56,
                                          fit: BoxFit
                                              .cover)
                                          .cornerRadiusWithClipRRect(
                                          30),
                                    ),
                                  ),
                                  10.width,
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize:
                                        MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                              width: 150,
                                              child: Text(
                                                  likesBloc.postLikesList[index].name.validate(),
                                                  overflow:
                                                  TextOverflow
                                                      .clip,
                                                  style:GoogleFonts.poppins(color:svGetBodyColor(),fontWeight:FontWeight.w600,fontSize:16))),
                                          6.width,
                                          // bloc.contactsList[index].isCurrentUser.validate()
                                          //     ? Image.asset('images/socialv/icons/ic_TickSquare.png', height: 14, width: 14, fit: BoxFit.cover)
                                          //     : const Offstage(),
                                        ],
                                      ),
                                    ],
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
                      );
                    }),
              );
            } else {
              return const Center(child: Text(""));
            }
          }),

    );
  }
}
