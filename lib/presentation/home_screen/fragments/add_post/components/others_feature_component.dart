import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../main.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: appStore.isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
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
          // Tag Friends Section
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag Friends Button
                InkWell(
                  onTap: () {
                    svShowShareBottomSheet(context, widget.searchPeopleBloc);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          color: Colors.blue[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          translation(context).lbl_tag_friends,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tagged Friends List
                BlocBuilder<AddPostBloc, AddPostState>(
                  bloc: widget.searchPeopleBloc,
                  builder: (context, state) {
                    if (state is PaginationLoadedState &&
                        widget.searchPeopleBloc.selectedSearchPeopleData.isNotEmpty) {
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: widget
                                .searchPeopleBloc.selectedSearchPeopleData
                                .map((element) {
                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${element.firstName?.substring(0, 1).toUpperCase()}',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${element.firstName} ${element.lastName}',
                                      style: TextStyle(
                                        color: Colors.blue[900],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
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
