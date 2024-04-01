import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/models/SVSearchModel.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../core/app_export.dart';
import '../../add_post/bloc/add_post_event.dart';
import '../../add_post/bloc/add_post_state.dart';

class TagFriendsListBottomSheet extends StatefulWidget {
  AddPostBloc searchPeopleBloc;
   TagFriendsListBottomSheet(this.searchPeopleBloc, {Key? key}) : super(key: key);

  @override
  State<TagFriendsListBottomSheet> createState() =>
      _TagFriendsListBottomSheetState();
}

class _TagFriendsListBottomSheetState
    extends State<TagFriendsListBottomSheet> {
  List<SVSearchModel> list = getSharePostList();
  // AddPostBloc widget.searchPeopleBloc =AddPostBloc();

  @override
  void initState() {
    widget.searchPeopleBloc.add(LoadPageEvent(
      page: 1,
      name: '',
    ));
    super.initState();
    afterBuildCreated(() {
      setStatusBarColor(svGetScaffoldColor());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        40.height,
         Align(alignment: Alignment.centerRight,child: InkWell(
            onTap: (){
              Navigator.of(context).pop();
            },
            child: const SizedBox(height: 40,width: 40,child: Icon(Icons.cancel,size: 30,),))),
        Container(
          padding: const EdgeInsets.only(left: 8.0),
          decoration: BoxDecoration(
              color: svGetScaffoldColor(),
              borderRadius: radius(SVAppCommonRadius)),
          child: AppTextField(
            textFieldType: TextFieldType.NAME,
            onChanged: (name) {
              widget.searchPeopleBloc.add(
                LoadPageEvent(
                  page: 1,
                  name: name,
                ),
              );
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search Here',
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
        16.height,
        BlocConsumer<AddPostBloc, AddPostState>(
          bloc: widget.searchPeopleBloc,
          // listenWhen: (previous, current) => current is PaginationLoadedState,
          // buildWhen: (previous, current) => current is! PaginationLoadedState,
          listener: (BuildContext context, AddPostState state) {
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
            print("stateqqq $state");
            if (state is PaginationLoadedState) {
              final bloc = widget.searchPeopleBloc;
              return SizedBox(
                height: 80,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  // physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withOpacity(0.4),
                          borderRadius: radius(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('${bloc.selectedSearchPeopleData[index].firstName} ${bloc.selectedSearchPeopleData[index].lastName}',
                              style: boldTextStyle()),
                          IconButton(
                            icon: const Icon(
                              Icons.highlight_remove_outlined,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              bloc.add(SelectFriendEvent(
                                  userData: bloc.selectedSearchPeopleData[index],
                                  isAdd: false));
                              // e.doSend = !e.doSend.validate();
                              // setState(() {});
                            },
                            padding: const EdgeInsets.all(0),
                          ),
                        ],
                      ).paddingSymmetric(vertical: 8),
                    );
                    // SVProfileFragment().launch(context);
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const Divider(height: 20);
                  },
                  itemCount: bloc.selectedSearchPeopleData.length,
                ),
              );
            } else {
              return Container();
            }
          },
        ),
        // Row(
        //   children: [
        //     Image.asset('images/socialv/faces/face_5.png',
        //             height: 48, width: 48, fit: BoxFit.cover)
        //         .cornerRadiusWithClipRRect(SVAppCommonRadius),
        //     10.width,
        //     Text('Add post to your story',
        //         style: secondaryTextStyle(color: svGetBodyColor())),
        //   ],
        // ),
        const Divider(height: 40),
        BlocConsumer<AddPostBloc, AddPostState>(
          bloc: widget.searchPeopleBloc,
          // listenWhen: (previous, current) => current is AddPostState,
          // buildWhen: (previous, current) => current is! AddPostState,
          listener: (BuildContext context, AddPostState state) {
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
            print("state $state");
            if (state is PaginationLoadingState) {
              return const Expanded(child: Center(child: CircularProgressIndicator()));
            } else if (state is PaginationLoadedState) {
              // print(state.drugsModel.length);
              // return _buildPostList(context);
              final bloc = widget.searchPeopleBloc;
              return Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  // physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    if (bloc.pageNumber <= bloc.numberOfPage) {
                      if (index == bloc.searchPeopleData.length - bloc.nextPageTrigger) {
                        bloc.add(CheckIfNeedMoreDataEvent(index: index));
                      }
                    }
                    return bloc.numberOfPage != bloc.pageNumber - 1 &&
                            index >= bloc.searchPeopleData.length - 1
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : InkWell(
                            onTap: () {
                              bloc.add(SelectFriendEvent(
                                  userData: bloc.searchPeopleData[index],
                                  isAdd: true));
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    bloc.searchPeopleData[index].profilePic == ''
                                        ? Image.asset(
                                                'images/socialv/faces/face_5.png',
                                                height: 56,
                                                width: 56,
                                                fit: BoxFit.cover)
                                            .cornerRadiusWithClipRRect(8)
                                        : Image.network(
                                                '${AppData.imageUrl}${bloc.searchPeopleData[index].profilePic.validate()}',
                                                height: 56,
                                                width: 56,
                                                fit: BoxFit.cover)
                                            .cornerRadiusWithClipRRect(8),
                                    10.width,
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                            '${bloc.searchPeopleData[index].firstName} ${bloc.searchPeopleData[index].lastName}',
                                            style: boldTextStyle()),
                                        6.width,
                                        // e.isOfficialAccount.validate()
                                        //     ? Image.asset('images/socialv/icons/ic_TickSquare.png', height: 14, width: 14, fit: BoxFit.cover)
                                        //     : Offstage(),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ).paddingSymmetric(vertical: 8),
                          );
                    // SVProfileFragment().launch(context);
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const Divider(height: 20);
                  },
                  itemCount: bloc.searchPeopleData.length,
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
        // Column(
        //   mainAxisSize: MainAxisSize.min,
        //   children: list.map((e) {
        //     return Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         Row(
        //           mainAxisSize: MainAxisSize.min,
        //           children: [
        //             Image.asset(e.profileImage.validate(), height: 56, width: 56, fit: BoxFit.cover),
        //             10.width,
        //             Row(
        //               children: [
        //                 Text(e.name.validate(), style: boldTextStyle()),
        //                 6.width,
        //                 e.isOfficialAccount.validate()
        //                     ? Image.asset('images/socialv/icons/ic_TickSquare.png', height: 14, width: 14, fit: BoxFit.cover)
        //                     : Offstage(),
        //               ],
        //               mainAxisSize: MainAxisSize.min,
        //             ),
        //           ],
        //         ),
        //         AppButton(
        //           shapeBorder: RoundedRectangleBorder(borderRadius: radius(4)),
        //           text: 'Send',
        //           textStyle: secondaryTextStyle(color: e.doSend.validate() ? Colors.white : SVAppColorPrimary, size: 10),
        //           onTap: () {
        //             e.doSend = !e.doSend.validate();
        //             setState(() {});
        //           },
        //           elevation: 0,
        //           height: 30,
        //           width: 50,
        //           color: e.doSend.validate() ? SVAppColorPrimary : svGetScaffoldColor(),
        //           padding: EdgeInsets.all(0),
        //         ),
        //       ],
        //     ).paddingSymmetric(vertical: 8);
        //   }).toList(),
        // )
      ],
    ).paddingAll(16);
  }
}
