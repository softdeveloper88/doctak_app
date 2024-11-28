import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../core/app_export.dart';
import '../../add_post/bloc/add_post_event.dart';

class CheckPlaceBottomSheet extends StatefulWidget {
  AddPostBloc searchPeopleBloc;
  CheckPlaceBottomSheet(this.searchPeopleBloc, {Key? key}) : super(key: key);

  @override
  State<CheckPlaceBottomSheet> createState() => _CheckPlaceBottomSheetState();
}

class _CheckPlaceBottomSheetState extends State<CheckPlaceBottomSheet> {
  @override
  void initState() {
    widget.searchPeopleBloc
        .add(PlaceAddEvent(page: 1, name: '', latitude: '', longitude: ''));
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
        30.height,
        Align(
            alignment: Alignment.centerRight,
            child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: const SizedBox(
                  height: 40,
                  width: 40,
                  child: Icon(
                    Icons.cancel,
                    size: 30,
                  ),
                ))),

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
              hintText: 'Search',
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
        Divider(height: 40),
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
              return Expanded(
                  child: Center(
                      child: CircularProgressIndicator(
                color: svGetBodyColor(),
              )));
            } else if (state is PaginationLoadedState) {
              // print(state.drugsModel.length);
              // return _buildPostList(context);
              final bloc = widget.searchPeopleBloc;
              return Column(
                children: [
                  Text(bloc.locationName),
                  ListView.separated(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();

                          bloc.add(SelectedLocation(
                              name: bloc.placeList[index].name,
                              latitude: bloc.placeList[index].latitude,
                              longitude: bloc.placeList[index].longitude));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${bloc.placeList[index].name}',
                                        style: boldTextStyle()),
                                    Text('${bloc.placeList[index].description}',
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
                    itemCount: bloc.placeList.length,
                  ),
                ],
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
