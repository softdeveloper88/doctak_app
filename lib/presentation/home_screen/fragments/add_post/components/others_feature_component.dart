import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../bloc/add_post_bloc.dart';

class Feeling {
  final String name;
  final String emoji;

  Feeling({required this.name, required this.emoji});
}

class OtherFeatureComponent extends StatefulWidget {
  Function? onColorChange;
  Color? colorValue;
  AddPostBloc searchPeopleBloc;

  OtherFeatureComponent(
      {this.onColorChange,
      this.colorValue,
      required this.searchPeopleBloc,
      Key? key})
      : super(key: key);

  @override
  State<OtherFeatureComponent> createState() => _OtherFeatureComponentState();
}

class _OtherFeatureComponentState extends State<OtherFeatureComponent> {
  final List<Feeling> feelings = [
    Feeling(name: 'Happy', emoji: '😊'),
    Feeling(name: 'Sad', emoji: '😢'),
    Feeling(name: 'Excited', emoji: '😄'),
    Feeling(name: 'Angry', emoji: '😡'),
  ];
  Feeling? selectedFeeling;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      // margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: svGetScaffoldColor(),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(SVAppCommonRadius),
              topRight: Radius.circular(SVAppCommonRadius))),
      child: Column(
        children: [
          // SizedBox(
          //   height: 40,
          //   child: ListView.builder(
          //     scrollDirection: Axis.horizontal,
          //     itemCount: feelings.length,
          //     itemBuilder: (context, index) {
          //       Feeling feeling = feelings[index];
          //       return GestureDetector(
          //         onTap: () {
          //           setState(() {
          //           widget.searchPeopleBloc.feeling = feeling.emoji;
          //           selectedFeeling = feeling;
          //           });
          //         },
          //         child: Container(
          //           decoration: BoxDecoration(
          //               color: selectedFeeling != feeling
          //                   ? Colors.lightBlueAccent.withOpacity(0.3)
          //                   : Colors.lightBlue,
          //               borderRadius: radius(10)),
          //           padding: const EdgeInsets.all(6),
          //           margin: const EdgeInsets.all(3),
          //           child: Row(
          //             children: [
          //               Text(feeling.emoji),
          //               Text(feeling.name),
          //             ],
          //           ),
          //         ),
          //       );
          //     },
          //   ),
          // ),
          // const Divider(
          //   height: 5,
          //   color: Colors.grey,
          // ),
          Row(
            children: [
              InkWell(
                onTap: () {
                  svShowShareBottomSheet(context, widget.searchPeopleBloc);
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: scaffoldLightColor, borderRadius: radius(10)),
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.tag_outlined,
                        color: cardBackgroundBlackDark,
                      ),
                      Text(
                        'Tag Friends:',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: cardBackgroundBlackDark,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<AddPostBloc, AddPostState>(
                  bloc: widget.searchPeopleBloc,
                  builder: (context, state) {
                    if (state is PaginationLoadedState) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ...widget
                                  .searchPeopleBloc.selectedSearchPeopleData
                                  .map((element) {
                                return Container(
                                  padding: const EdgeInsets.all(4),
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      color: Colors.lightBlueAccent
                                          .withOpacity(0.4),
                                      borderRadius: radius(10)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                          '${element.firstName} ${element.lastName}',
                                          style: boldTextStyle()),
                                      // IconButton(
                                      //   icon: const Icon(
                                      //     Icons.highlight_remove_outlined,
                                      //     color: Colors.black,
                                      //   ),
                                      //   onPressed: () {
                                      //     // widget.searchPeopleBloc.selectedSearchPeopleData.add(SelectFriendEvent(
                                      //     //     userData: element,
                                      //     //     isAdd: false));
                                      //     // e.doSend = !e.doSend.validate();
                                      //     // setState(() {});
                                      //   },
                                      //   padding: EdgeInsets.all(0),
                                      // ),
                                    ],
                                  ),
                                );
                              })
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ),
            ],
          ),
          // const Divider(
          //   height: 5,
          //   color: Colors.grey,
          // ),
          // Row(
          //   children: [
          //     Container(
          //       decoration: BoxDecoration(
          //           color: Colors.lightBlueAccent.withOpacity(0.4),
          //           borderRadius: radius(10)),
          //       padding: const EdgeInsets.all(4),
          //       child: const Row(
          //         children: [
          //           Icon(
          //             Icons.location_on,
          //             color: Colors.blue,
          //           ),
          //           Text(
          //             'Location:',
          //             style: TextStyle(
          //                 color: Colors.blue, fontWeight: FontWeight.bold),
          //           ),
          //         ],
          //       ),
          //     ),
          //     BlocBuilder<AddPostBloc, AddPostState>(
          //       bloc: widget.searchPeopleBloc,
          //       builder: (context, state) {
          //         print("states Location ${state}");
          //         if (state is PaginationLoadedState) {
          //           return Padding(
          //             padding: const EdgeInsets.all(8.0),
          //             child: Text(widget.searchPeopleBloc.locationName ?? "",style:  boldTextStyle(),),
          //           );
          //         } else {
          //           return Container();
          //         }
          //       },
          //     ),
          //   ],
          // ),
          // SizedBox(
          //   height: 40,
          //   child: ListView.builder(
          //     scrollDirection: Axis.horizontal,
          //     itemCount: feelings.length,
          //     itemBuilder: (context, index) {
          //       Feeling feeling = feelings[index];
          //       return GestureDetector(
          //         onTap: () {
          //           setState(() {
          //             widget.searchPeopleBloc.feeling = feeling.emoji;
          //             selectedFeeling = feeling;
          //           });
          //         },
          //         child: Container(
          //           decoration: BoxDecoration(
          //               color: selectedFeeling != feeling
          //                   ? Colors.lightBlueAccent.withOpacity(0.4)
          //                   : Colors.lightBlue,
          //               borderRadius: radius(10)),
          //           padding: const EdgeInsets.all(6),
          //           margin: const EdgeInsets.all(3),
          //           child: Row(
          //             children: [
          //               Text(feeling.emoji),
          //               Text(feeling.name),
          //             ],
          //           ),
          //         ),
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}
