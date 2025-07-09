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

  OtherFeatureComponent({
    this.onColorChange,
    this.colorValue,
    required this.searchPeopleBloc,
    Key? key,
  }) : super(key: key);

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
      margin: const EdgeInsets.symmetric(vertical: 6),
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            // const Text(
            //   'Tag Friends',
            //   style: TextStyle(
            //     fontSize: 14,
            //     fontWeight: FontWeight.w600,
            //     fontFamily: 'Poppins',
            //     color: Colors.black87,
            //   ),
            // ),
            // const SizedBox(height: 12),
            // Tag Friends Button - Centered
            Center(
              child: InkWell(
                onTap: () {
                  svShowShareBottomSheet(context, widget.searchPeopleBloc);
                },
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        translation(context).lbl_tag_friends,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tagged Friends List - Centered
            BlocBuilder<AddPostBloc, AddPostState>(
              bloc: widget.searchPeopleBloc,
              builder: (context, state) {
                if (state is PaginationLoadedState &&
                    widget
                        .searchPeopleBloc
                        .selectedSearchPeopleData
                        .isNotEmpty) {
                  return Container(
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: widget
                              .searchPeopleBloc
                              .selectedSearchPeopleData
                              .map((element) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${element.firstName?.substring(0, 1).toUpperCase()}',
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${element.firstName} ${element.lastName}',
                                        style: TextStyle(
                                          color: Colors.blue[900],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList(),
                        ),
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
    );
  }
}
