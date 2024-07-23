import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/group_screen/about_group_screen.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_bloc.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_event.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_state.dart';
import 'package:doctak_app/presentation/group_screen/event_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../main.dart';
import '../coming_soon_screen/coming_soon_screen.dart';
import '../home_screen/utils/SVCommon.dart';
import 'group_member_request_screen.dart';
import 'group_member_screen.dart';
import 'manage_notification_screen.dart';

class GroupViewScreen extends StatefulWidget {
  GroupViewScreen(this.id, {super.key});
  String? id;
  @override
  State<GroupViewScreen> createState() => _GroupViewScreenState();
}

class _GroupViewScreenState extends State<GroupViewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  GroupBloc groupBloc = GroupBloc();

  @override
  void initState() {
    print(widget.id ?? "");
    groupBloc.add(GroupDetailsEvent(widget.id ?? ''));
    groupBloc.add(GroupPostRequestEvent(widget.id ?? '', '1'));
    groupBloc.add(GroupMemberRequestEvent(widget.id ?? ''));
    groupBloc.add(GroupMembersEvent(widget.id ?? '', ''));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: svGetBgColor(),
        endDrawer: CustomDrawer(groupBloc),
        endDrawerEnableOpenDragGesture: true,
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          surfaceTintColor: svGetScaffoldColor(),
          title: const Text('Groups'),
          leading: IconButton(
            icon:
                Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/search.png',
                height: 20,
                width: 20,
                color: svGetBodyColor(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.notifications_sharp,
                color: svGetBodyColor(),
              ),
            ),
            GestureDetector(
              onTap: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/images/img_menu.png',
                  height: 25,
                  width: 25,
                  color: svGetBodyColor(),
                ),
              ),
            )
          ],
        ),
        body: BlocConsumer<GroupBloc, GroupState>(
            listener: (BuildContext context, GroupState state) {},
            bloc: groupBloc,
            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return Center(
                    child: CircularProgressIndicator(
                  color: svGetBodyColor(),
                ));
              } else if (state is PaginationLoadedState) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        color: context.cardColor,
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 22.h,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                            groupBloc.groupDetailsModel?.group
                                                    ?.banner ??
                                                ''),
                                        fit: BoxFit.cover,
                                      ),
                                      color: context.cardColor,
                                    ),
                                    width: 100.w,
                                    height: 35.w,
                                    // child:
                                    // Align(
                                    //     alignment: Alignment.bottomRight,
                                    //     child: Padding(
                                    //       padding: const EdgeInsets.all(16.0),
                                    //       child: GestureDetector(
                                    //         child: Container(
                                    //             height: 50,
                                    //             width: 50,
                                    //             decoration: BoxDecoration(
                                    //                 color: svGetBgColor(),
                                    //                 border: Border.all(color: Colors.grey),
                                    //                 borderRadius: BorderRadius.circular(100)),
                                    //             child: const Icon(Icons.camera_alt)),
                                    //       ),
                                    //     )),
                                  ),
                                  Positioned(
                                    top: 80,
                                    left: 20,
                                    // child: GestureDetector(
                                    // onTap: () async {
                                    //   const permission = Permission.storage;
                                    //   const permission1 = Permission.photos;
                                    //   var status = await permission.status;
                                    //   print(status);
                                    //   if (await permission1.isGranted) {
                                    //     _showFileOptions(true);
                                    //     // _selectFiles(context);
                                    //   } else if (await permission1.isDenied) {
                                    //     final result = await permission1.request();
                                    //     if (status.isGranted) {
                                    //       _showFileOptions(true);
                                    //       // _selectFiles(context);
                                    //       print("isGranted");
                                    //     } else if (result.isGranted) {
                                    //       _showFileOptions(
                                    //         true,
                                    //       );
                                    //       // _selectFiles(context);
                                    //       print("isGranted");
                                    //     } else if (result.isDenied) {
                                    //       final result = await permission.request();
                                    //       print("isDenied");
                                    //     } else if (result.isPermanentlyDenied) {
                                    //       print("isPermanentlyDenied");
                                    //       // _permissionDialog(context);
                                    //     }
                                    //   } else if (await permission.isPermanentlyDenied) {
                                    //     print("isPermanentlyDenied");
                                    //     // _permissionDialog(context);
                                    //   }
                                    // },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: CachedNetworkImageProvider(
                                                groupBloc.groupDetailsModel
                                                        ?.group?.logo ??
                                                    ''),
                                            fit: BoxFit.cover,
                                          ),
                                          color: svGetBgColor(),
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(100)),
                                      width: 25.w,
                                      height: 25.w,
                                      child: const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        // child: Icon(Icons.camera_alt),
                                      ),
                                    ),
                                    // ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text(
                                groupBloc.groupDetailsModel?.group?.name ?? "",
                                style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_filled,
                                    size: 24,
                                  ),
                                  Text(
                                    " ${groupBloc.groupDetailsModel?.group?.privacySetting ?? ''} Group . ${groupBloc.groupDetailsModel?.totalMembers ?? '0'} members",
                                    style: GoogleFonts.poppins(
                                        color: Colors.black45,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30.w,
                                      height: 40,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.blue),
                                      child: IconButton(
                                        icon: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            ),
                                            Text(
                                              " Invite",
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white),
                                            )
                                          ],
                                        ),
                                        color: Colors.grey,
                                        onPressed: () {},
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Container(
                                      width: 30.w,
                                      height: 40,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.grey[300]),
                                      child: IconButton(
                                        icon: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.group,
                                            ),
                                            Text(" Joined")
                                          ],
                                        ),
                                        color: Colors.grey,
                                        onPressed: () {},
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          color: Colors.grey[300]),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.share,
                                        ),
                                        color: Colors.grey,
                                        onPressed: () {},
                                      ),
                                    ),
                                  ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16.0, right: 16.0, top: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Container(
                                    height: 40,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[300]),
                                    child: TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        'Posts',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 40,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[300]),
                                    child: TextButton(
                                      onPressed: () {
                                        GroupMemberScreen(groupBloc)
                                            .launch(context);
                                      },
                                      child: Text(
                                        'Members',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black45),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 40,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[300]),
                                    child: TextButton(
                                      onPressed: () {
                                        const ComingSoonScreen()
                                            .launch(context);
                                      },
                                      child: Text(
                                        'Events',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black45),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 40,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[300]),
                                    child: TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        'Media',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black45),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        color: context.cardColor,
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          AppData.imageUrl +
                                              AppData.profile_pic,
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                      color: svGetBgColor(),
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(100)),
                                  width: 14.w,
                                  height: 14.w,
                                  child: const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    // child: Icon(Icons.camera_alt),
                                  ),
                                ),
                                Container(
                                  width: 70.w,
                                  height: 50,
                                  padding:
                                      const EdgeInsets.only(left: 8, right: 8),
                                  decoration: BoxDecoration(
                                    color: appStore.isDarkMode
                                        ? svGetScaffoldColor()
                                        : cardLightColor,
                                    // border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Center(
                                    child: TextField(
                                      // controller: textController,
                                      decoration:
                                          const InputDecoration.collapsed(
                                        hintText:
                                            'Write And Share Your Post...',
                                      ),
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      onChanged: (Text) {},
                                      onTapOutside: (text) {},
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              color: Colors.grey[300],
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(left: 8.0),
                                    height: 40,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[300]),
                                    child: IconButton(
                                      icon: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.image,
                                            color: Colors.black,
                                          ),
                                          Text(" Photo/Videos",
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black)),
                                        ],
                                      ),
                                      color: Colors.grey,
                                      onPressed: () {},
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 8.0),
                                    height: 40,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[300]),
                                    child: IconButton(
                                      icon: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.camera_alt,
                                            color: Colors.black,
                                          ),
                                          Text(" Camera",
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black)),
                                        ],
                                      ),
                                      color: Colors.grey,
                                      onPressed: () {},
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 8.0),
                                    height: 40,
                                    width: 30.w,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[300]),
                                    child: IconButton(
                                      icon: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.live_tv,
                                            color: Colors.black,
                                          ),
                                          Text(" Live",
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black)),
                                        ],
                                      ),
                                      color: Colors.grey,
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        color: context.cardColor,
                        height: 30.h,
                        width: 100.w,
                        // child: ListView.builder(
                        //   scrollDirection: Axis.vertical,
                        //   physics: const BouncingScrollPhysics(),
                        //   itemCount: groupBloc.groupPostModel?.posts?.length,
                        //   itemBuilder: (context, index) {
                        //
                        //     return Container(
                        //           padding:
                        //           const EdgeInsets.symmetric(vertical: 16),
                        //           margin: const EdgeInsets.symmetric(vertical: 8),
                        //           decoration: BoxDecoration(
                        //               borderRadius: radius(SVAppCommonRadius),
                        //               color: context.cardColor),
                        //           child: Column(
                        //             crossAxisAlignment: CrossAxisAlignment.start,
                        //             children: [
                        //               Row(
                        //                 mainAxisAlignment:
                        //                 MainAxisAlignment.spaceBetween,
                        //                 children: [
                        //                   InkWell(
                        //                     onTap: () {
                        //
                        //                     },
                        //                     child: Row(
                        //                       children: [
                        //                         CachedNetworkImage(
                        //                           imageUrl:
                        //                           "",
                        //                           height: 50,
                        //                           width: 50,
                        //                           fit: BoxFit.cover,
                        //                         ).cornerRadiusWithClipRRect(20),
                        //                         12.width,
                        //                         Column(
                        //                           crossAxisAlignment:
                        //                           CrossAxisAlignment.start,
                        //                           children: [
                        //                             Row(
                        //                               children: [
                        //                                 Text('',
                        //                                     style:
                        //                                     boldTextStyle()),
                        //                                 const SizedBox(
                        //                                   width: 4,
                        //                                 ),
                        //                                 Image.asset(
                        //                                     'images/socialv/icons/ic_TickSquare.png',
                        //                                     height: 14,
                        //                                     width: 14,
                        //                                     fit: BoxFit.cover),
                        //                               ],
                        //                             ),
                        //                             Row(
                        //                               children: [
                        //                                 Text(
                        //                                     timeAgo.format(DateTime
                        //                                         .parse(widget
                        //                                         .homeBloc
                        //                                         .postList[
                        //                                     index]
                        //                                         .createdAt!)),
                        //                                     style: secondaryTextStyle(
                        //                                         color:
                        //                                         svGetBodyColor(),
                        //                                         size: 12)),
                        //                                 const Padding(
                        //                                   padding:
                        //                                   EdgeInsets.only(
                        //                                       left: 8.0),
                        //                                   child: Icon(
                        //                                     Icons.access_time,
                        //                                     size: 20,
                        //                                     color: Colors.grey,
                        //                                   ),
                        //                                 )
                        //                               ],
                        //                             ),
                        //                           ],
                        //                         ),
                        //                         4.width,
                        //                       ],
                        //                     ).paddingSymmetric(horizontal: 16),
                        //                   ),
                        //                   Expanded(
                        //                     child: Row(
                        //                       mainAxisAlignment:
                        //                       MainAxisAlignment.end,
                        //                       children: [
                        //                         // if (widget.homeBloc
                        //                         //     .postList[index].userId ==
                        //                         //     AppData.logInUserId)
                        //                         //   PopupMenuButton(
                        //                         //     itemBuilder: (context) {
                        //                         //       return [
                        //                         //         PopupMenuItem(
                        //                         //           child: Builder(
                        //                         //               builder: (context) {
                        //                         //                 return Column(
                        //                         //                   children: [
                        //                         //                     "Delete"
                        //                         //                   ].map(
                        //                         //                           (String item) {
                        //                         //                         return PopupMenuItem(
                        //                         //                           value: item,
                        //                         //                           child:
                        //                         //                           Text(item),
                        //                         //                         );
                        //                         //                       }).toList(),
                        //                         //                 );
                        //                         //               }),
                        //                         //         ),
                        //                         //       ];
                        //                         //     },
                        //                         //     onSelected: (value) {
                        //                         //       if (value == 'Delete') {
                        //                         //         showDialog(
                        //                         //           context: context,
                        //                         //           builder: (BuildContext
                        //                         //           context) {
                        //                         //             return showAlertDialog(
                        //                         //                 context,
                        //                         //                 widget
                        //                         //                     .homeBloc
                        //                         //                     .postList[
                        //                         //                 index]
                        //                         //                     .id ??
                        //                         //                     0);
                        //                         //           },
                        //                         //         );
                        //                         //       }
                        //                         //     },
                        //                         //   )
                        //                         // IconButton(onPressed: () {},
                        //                         //     icon: const Icon(Icons.more_horiz)),
                        //                       ],
                        //                     ).paddingSymmetric(horizontal: 8),
                        //                   ),
                        //                 ],
                        //               ),
                        //               16.height,
                        //               widget.homeBloc.postList[index].title
                        //                   .validate()
                        //                   .isNotEmpty
                        //                   ? _buildPlaceholderWithoutFile(
                        //                   context,
                        //                   widget.homeBloc.postList[index]
                        //                       .title ??
                        //                       '',
                        //                   widget.homeBloc.postList[index]
                        //                       .backgroundColor ??
                        //                       '#ffff',
                        //                   widget
                        //                       .homeBloc.postList[index].image,
                        //                   widget
                        //                       .homeBloc.postList[index].media)
                        //               // ? svRobotoText(
                        //               // text: homeBloc.postList[index].title.validate(),
                        //               // textAlign: TextAlign.start).paddingSymmetric(
                        //               // horizontal: 16)
                        //                   : const Offstage(),
                        //               widget.homeBloc.postList[index].title
                        //                   .validate()
                        //                   .isNotEmpty
                        //                   ? 16.height
                        //                   : const Offstage(),
                        //               _buildMediaContent(context, index)
                        //                   .cornerRadiusWithClipRRect(0)
                        //                   .center(),
                        //               // Image.asset('',
                        //               //   // homeBloc.postList[index].image?.validate(),
                        //               //   height: 300,
                        //               //   width: context.width() - 32,
                        //               //   fit: BoxFit.cover,
                        //               // ).cornerRadiusWithClipRRect(SVAppCommonRadius).center(),
                        //               Padding(
                        //                 padding: const EdgeInsets.only(
                        //                     left: 8.0, right: 8.0, top: 8.0),
                        //                 child: Row(
                        //                   mainAxisAlignment:
                        //                   MainAxisAlignment.spaceBetween,
                        //                   children: [
                        //                     Text(
                        //                         '${widget.homeBloc.postList[index].likes?.length ?? 0.validate()} Likes',
                        //                         style: secondaryTextStyle(
                        //                             color: svGetBodyColor())),
                        //                     Text(
                        //                         '${widget.homeBloc.postList[index].comments?.length ?? 0.validate()} comments',
                        //                         style: secondaryTextStyle(
                        //                             color: svGetBodyColor())),
                        //                   ],
                        //                 ),
                        //               ),
                        //               const Divider(
                        //                 color: Colors.grey,
                        //                 thickness: 0.2,
                        //               ),
                        //               Row(
                        //                 mainAxisAlignment:
                        //                 MainAxisAlignment.spaceBetween,
                        //                 children: [
                        //                   InkWell(
                        //                       splashColor: Colors.transparent,
                        //                       highlightColor: Colors.transparent,
                        //                       onTap: () {
                        //                         widget.homeBloc.add(PostLikeEvent(
                        //                             postId: widget.homeBloc
                        //                                 .postList[index].id ??
                        //                                 0));
                        //                       },
                        //                       child: Column(
                        //                         children: [
                        //                           findIsLiked(widget.homeBloc
                        //                               .postList[index].likes)
                        //                               ? Image.asset(
                        //                               'images/socialv/icons/ic_HeartFilled.png',
                        //                               height: 20,
                        //                               width: 22,
                        //                               fit: BoxFit.fill)
                        //                               : Image.asset(
                        //                             'images/socialv/icons/ic_Heart.png',
                        //                             height: 22,
                        //                             width: 22,
                        //                             fit: BoxFit.cover,
                        //                             color:
                        //                             context.iconColor,
                        //                           ),
                        //                           Text('Like',
                        //                               style: secondaryTextStyle(
                        //                                   color:
                        //                                   svGetBodyColor())),
                        //                         ],
                        //                       )),
                        //                   InkWell(
                        //                     splashColor: Colors.transparent,
                        //                     highlightColor: Colors.transparent,
                        //                     onTap: () {
                        //                       SVCommentScreen(
                        //                           id: widget
                        //                               .homeBloc
                        //                               .postList[index]
                        //                               .id ??
                        //                               0)
                        //                           .launch(context);
                        //                     },
                        //                     child: Column(
                        //                       children: [
                        //                         Image.asset(
                        //                           'images/socialv/icons/ic_Chat.png',
                        //                           height: 22,
                        //                           width: 22,
                        //                           fit: BoxFit.cover,
                        //                           color: context.iconColor,
                        //                         ),
                        //                         Text('Comment',
                        //                             style: secondaryTextStyle(
                        //                                 color: svGetBodyColor())),
                        //                       ],
                        //                     ),
                        //                   ),
                        //                   // InkWell(
                        //                   //   splashColor: Colors.transparent,
                        //                   //   highlightColor: Colors.transparent,
                        //                   //   onTap: () {},
                        //                   //   child: Column(
                        //                   //     children: [
                        //                   //       Image.asset(
                        //                   //         'images/socialv/icons/ic_Send.png',
                        //                   //         height: 22,
                        //                   //         width: 22,
                        //                   //         fit: BoxFit.cover,
                        //                   //         color: context.iconColor,
                        //                   //       ),
                        //                   //       Text('Send',
                        //                   //           style: secondaryTextStyle(
                        //                   //               color: svGetBodyColor())),
                        //                   //     ],
                        //                   //   ),
                        //                   // ),
                        //                 ],
                        //               ).paddingSymmetric(horizontal: 16),
                        //               // const Divider(indent: 16, endIndent: 16, height: 20),
                        //               // Row(
                        //               //   mainAxisAlignment: MainAxisAlignment.center,
                        //               //   children: [
                        //               //     SizedBox(
                        //               //       width: 56,
                        //               //       child: Stack(
                        //               //         alignment: Alignment.centerLeft,
                        //               //         children: [
                        //               //           Positioned(
                        //               //             right: 0,
                        //               //             child: Container(
                        //               //               decoration: BoxDecoration(
                        //               //                   border: Border.all(
                        //               //                       color: Colors.white, width: 2),
                        //               //                   borderRadius: radius(100)),
                        //               //               child: Image.asset(
                        //               //                   'images/socialv/faces/face_1.png',
                        //               //                   height: 24,
                        //               //                   width: 24,
                        //               //                   fit: BoxFit.cover)
                        //               //                   .cornerRadiusWithClipRRect(100),
                        //               //             ),
                        //               //           ),
                        //               //           Positioned(
                        //               //             left: 14,
                        //               //             child: Container(
                        //               //               decoration: BoxDecoration(
                        //               //                   border: Border.all(
                        //               //                       color: Colors.white, width: 2),
                        //               //                   borderRadius: radius(100)),
                        //               //               child: Image.asset(
                        //               //                   'images/socialv/faces/face_2.png',
                        //               //                   height: 24,
                        //               //                   width: 24,
                        //               //                   fit: BoxFit.cover)
                        //               //                   .cornerRadiusWithClipRRect(100),
                        //               //             ),
                        //               //           ),
                        //               //           Positioned(
                        //               //             child: Container(
                        //               //               decoration: BoxDecoration(
                        //               //                   border: Border.all(
                        //               //                       color: Colors.white, width: 2),
                        //               //                   borderRadius: radius(100)),
                        //               //               child: Image.asset(
                        //               //                   'images/socialv/faces/face_3.png',
                        //               //                   height: 24,
                        //               //                   width: 24,
                        //               //                   fit: BoxFit.cover)
                        //               //                   .cornerRadiusWithClipRRect(100),
                        //               //             ),
                        //               //           ),
                        //               //         ],
                        //               //       ),
                        //               //     ),
                        //               //     10.width,
                        //               // //     RichText(
                        //               // //       text: TextSpan(
                        //               // //         text: 'Liked By ',
                        //               // //         style: secondaryTextStyle(
                        //               // //             color: svGetBodyColor(), size: 12),
                        //               // //         children: <TextSpan>[
                        //               // //           TextSpan(text: 'Ms.Mountain ',
                        //               // //               style: boldTextStyle(size: 12)),
                        //               // //           TextSpan(text: 'And ',
                        //               // //               style: secondaryTextStyle(
                        //               // //                   color: svGetBodyColor(), size: 12)),
                        //               // //           TextSpan(text: '${widget.homeBloc.postList[index].likes?.length??0} Others ',
                        //               // //               style: boldTextStyle(size: 12)),
                        //               // //         ],
                        //               // //       ),
                        //               // //     )
                        //               //   ],
                        //               // )
                        //             ],
                        //           ),
                        //         );
                        //   },
                        //   shrinkWrap: true,
                        //   // physics: const NeverScrollableScrollPhysics(),
                        // ),
                      )
                    ],
                  ),
                );
              } else {
                return Container();
              }
            }));
  }
}

class CustomDrawer extends StatelessWidget {
  CustomDrawer(this.groupBloc, {super.key});
  GroupBloc? groupBloc;
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF3398DB), // Blue background color
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 230,
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      placeholder: (context, url) => SizedBox(
                        height: 30,
                        width: 30,
                        child: LinearProgressIndicator(
                          color: Colors.grey.shade200,
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ),
                      imageUrl:
                          groupBloc?.groupDetailsModel?.group?.banner ?? "",
                      // Replace with the actual image URL
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      // bottom: 10,
                      left: 10,
                      right: 10,
                      top: 150,
                      child: Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: CachedNetworkImageProvider(
                              groupBloc?.groupDetailsModel?.group?.logo ??
                                  ""), // Replace with the actual image URL
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                groupBloc?.groupDetailsModel?.group?.name ?? "",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              Text(
                '${groupBloc?.groupDetailsModel?.group?.privacySetting ?? ''} Group . ${groupBloc?.groupDetailsModel?.totalMembers ?? ""} members',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const Divider(
                color: Colors.white,
                thickness: 1,
                indent: 0,
                endIndent: 50,
              ),
              DrawerItem(
                onTap: () {
                  AboutGroupScreen(groupBloc).launch(context);
                },
                icon: Icons.info,
                text: 'About Group',
              ),
              const Divider(
                color: Colors.white,
                thickness: 1,
                indent: 0,
                endIndent: 50,
              ),
              DrawerItem(
                onTap: () {
                  if (groupBloc?.groupDetailsModel?.isAdmin ?? false) {
                    ManageNotificationScreen(groupBloc).launch(context);
                  }
                },
                icon: Icons.notifications,
                text: 'Manage Notification',
              ),
              const Divider(
                color: Colors.white,
                thickness: 1,
                indent: 0,
                endIndent: 50,
              ),
              DrawerItem(
                onTap: () {},
                icon: Icons.post_add,
                text: 'View post request',
                trailing: '${groupBloc?.groupPostModel?.posts?.length ?? '0'}',
              ),
              const Divider(
                color: Colors.white,
                thickness: 1,
                indent: 0,
                endIndent: 50,
              ),
              DrawerItem(
                onTap: () {
                  if (groupBloc?.groupDetailsModel?.isAdmin ?? false) {
                    GroupMemberRequestScreen(groupBloc).launch(context);
                  }
                },
                icon: Icons.group,
                text: 'View member request',
                trailing:
                    '${groupBloc?.groupMemberRequestModel?.groupMembers?.length ?? '0'}',
              ),
              const Divider(
                color: Colors.white,
                thickness: 1,
                indent: 0,
                endIndent: 50,
              ),
              DrawerItem(
                icon: Icons.settings,
                text: 'Group Setting',
              ),
              const Divider(
                color: Colors.white,
                thickness: 1,
                indent: 0,
                endIndent: 50,
              ),
              DrawerItem(
                icon: Icons.exit_to_app,
                text: 'Leave Group',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? trailing;
  final Function? onTap;

  DrawerItem({
    required this.icon,
    required this.text,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
      ),
      title: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: trailing != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trailing!,
                style: const TextStyle(color: Colors.blue),
              ),
            )
          : null,
      onTap: () => onTap!(),
    );
  }
}
