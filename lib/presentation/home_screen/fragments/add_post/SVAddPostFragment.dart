import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/utils/app/AppData.dart';
import '../../../../main.dart';
import '../../utils/SVColors.dart';
import '../../utils/SVCommon.dart';
import 'bloc/add_post_bloc.dart';
import 'components/SVPostOptionsComponent.dart';
import 'components/SVPostTextComponent.dart';
import 'components/others_feature_component.dart';

class SVAddPostFragment extends StatefulWidget {
  SVAddPostFragment({required this.refresh, Key? key}) : super(key: key);
  Function refresh;

  @override
  State<SVAddPostFragment> createState() => _SVAddPostFragmentState();
}

class _SVAddPostFragmentState extends State<SVAddPostFragment> {
  String image = '';

  List<String> colorListHex = [
    '#FFFFFF', // white
    '#FF0000', // Red
    '#0000FF', // Blue
    '#00FF00', // Green
    '#FFFF00', // Yellow
    '#FFA500', // Orange
    '#800080', // Purple
    '#FFC0CB', // Pink
    '#008080', // Teal
    '#4B0082', // Indigo
    '#A52A2A', // Brown
  ];
  Random random = Random();
  String currentSetColor = '';
  Color currentColor = Colors.red;

  Color _hexToColor(String hexColorCode) {
    String colorCode = hexColorCode.replaceAll("#", "");
    int intValue = int.parse(colorCode, radix: 16);
    return Color(intValue).withAlpha(0xFF);
  }

  void changeColor() {
    setState(() {
      currentColor =
          _hexToColor(colorListHex[random.nextInt(colorListHex.length)]);
      currentSetColor = colorListHex[random.nextInt(colorListHex.length)];
      searchPeopleBloc.backgroundColor = currentSetColor;
    });
  }

  AddPostBloc searchPeopleBloc = AddPostBloc();
  final QuillController _controller = QuillController.basic();

  @override
  void initState() {
    currentColor = SVDividerColor;
    super.initState();
    afterBuildCreated(() {
      setStatusBarColor(context.cardColor);
    });
  }

  @override
  void dispose() {
    setStatusBarColor(
        appStore.isDarkMode ? appBackgroundColorDark : SVAppLayoutBackground);
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.blue[600],
              size: 16,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        surfaceTintColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        backgroundColor: svGetScaffoldColor(),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.blue[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              translation(context).lbl_new_post,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          BlocListener<AddPostBloc, AddPostState>(
            bloc: searchPeopleBloc,
            listener: (BuildContext context, AddPostState state) {
              if (state is ResponseLoadedState) {
                print("State: ${state.toString()}");
                Map<String, dynamic> jsonMap = json.decode(state.message);
                if (jsonMap['success'] == true) {
                  searchPeopleBloc.selectedSearchPeopleData.clear();
                  searchPeopleBloc.imagefiles.clear();
                  searchPeopleBloc.title = '';
                  searchPeopleBloc.feeling = '';
                  searchPeopleBloc.backgroundColor = '';
                  showToast(jsonMap['message']);
                  print('Success: ${jsonMap['message']}');
                  widget.refresh();
                  Navigator.of(context).pop('');
                } else {
                  showToast(jsonMap['message']);
                  print('Error: ${jsonMap['message']}');
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed: () {
                  searchPeopleBloc.add(AddPostDataEvent());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  translation(context).lbl_post,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Compact User Profile Section
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      children: [
                        // Profile Picture
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: CachedNetworkImage(
                              imageUrl:
                                  "${AppData.imageUrl}${AppData.profile_pic.validate()}",
                              height: 42,
                              width: 42,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.blue[50],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.blue[400],
                                    strokeWidth: 1.5,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.blue[50],
                                child: Center(
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.blue[400],
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      AppData.name ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.all(1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.medical_services_outlined,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      capitalizeWords(AppData.specialty),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontFamily: 'Poppins',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Post Content Section
                  SVPostTextComponent(
                    onColorChange: () => changeColor,
                    colorValue: currentColor,
                    searchPeopleBloc: searchPeopleBloc,
                  ),
                  // Additional Features
                  OtherFeatureComponent(
                      onColorChange: () => changeColor,
                      colorValue: currentColor,
                      searchPeopleBloc: searchPeopleBloc),
                  // Post Options - Moved to bottom
                  SVPostOptionsComponent(searchPeopleBloc),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
