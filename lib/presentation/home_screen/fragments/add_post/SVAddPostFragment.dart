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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
      resizeToAvoidBottomInset: false,
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        surfaceTintColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        backgroundColor: context.cardColor,
        title: Text(translation(context).lbl_new_post, style: boldTextStyle(size: 18)),
        elevation: 0,
        centerTitle: true,
        actions: [
          BlocListener<AddPostBloc, AddPostState>(
            bloc: searchPeopleBloc,
            listener: (BuildContext context, AddPostState state) {
              if ( state is ResponseLoadedState) {

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
                // Reset the flag here to ensure it's done only after processing is complete

              }
            },
            child: AppButton(
              shapeBorder: RoundedRectangleBorder(borderRadius: radius(4)),
              text: translation(context).lbl_post,
              textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
              onTap: () {
                // Reset flag before making a request
                searchPeopleBloc.add(AddPostDataEvent());
              },
              elevation: 0,
              color: SVAppColorPrimary,
              width: 70,
              padding: const EdgeInsets.all(0),
            ).paddingAll(12),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl:
                  "${AppData.imageUrl}${AppData.profile_pic.validate()}",
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                ).cornerRadiusWithClipRRect(100),
                12.width,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(AppData.name ?? '', style: boldTextStyle()),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Image.asset(
                              'images/socialv/icons/ic_TickSquare.png',
                              height: 14,
                              width: 14,
                              fit: BoxFit.cover),
                        ),
                      ],
                    ),
                    Text(capitalizeWords(AppData.specialty),
                        style: secondaryTextStyle(
                            color: svGetBodyColor(), size: 13)),
                  ],
                ),
                4.width,
              ],
            ).paddingSymmetric(horizontal: 16),
            Divider(
              color: Colors.grey[300],
              endIndent: 16,
              indent: 16,
            ),
            SVPostTextComponent(
              onColorChange: () => changeColor,
              colorValue: currentColor,
              searchPeopleBloc: searchPeopleBloc,
            ),
            OtherFeatureComponent(
                onColorChange: () => changeColor,
                colorValue: currentColor,
                searchPeopleBloc: searchPeopleBloc),
            Divider(
              color: Colors.grey[300],
              endIndent: 16,
              indent: 16,
            ),
            SVPostOptionsComponent(searchPeopleBloc)
          ],
        ),
      ),
    );
  }
}
