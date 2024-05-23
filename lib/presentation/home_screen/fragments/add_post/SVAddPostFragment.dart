import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  const SVAddPostFragment({Key? key}) : super(key: key);

  @override
  State<SVAddPostFragment> createState() => _SVAddPostFragmentState();
}

class _SVAddPostFragmentState extends State<SVAddPostFragment> {
  String image = '';

  List<String> colorListHex = [
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
      print("object");
      currentColor =
          _hexToColor(colorListHex[random.nextInt(colorListHex.length)]);
      currentSetColor = colorListHex[random.nextInt(colorListHex.length)];
      searchPeopleBloc.backgroundColor = currentSetColor;
    });
  }

  AddPostBloc searchPeopleBloc = AddPostBloc();

  @override
  void initState() {
    currentColor = SVDividerColor;
    searchPeopleBloc = BlocProvider.of<AddPostBloc>(context);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: context.iconColor),
        backgroundColor: Colors.white,
        title: Text('New Post', style: boldTextStyle(size: 18)),
        elevation: 0,
        centerTitle: true,
        actions: [
          BlocListener<AddPostBloc, AddPostState>(
            bloc: searchPeopleBloc,
            listener: (BuildContext context, AddPostState state) {
              if (state is ResponseLoadedState) {
                var data = jsonDecode(state.message);
                if (data['success'] == true) {
                  searchPeopleBloc.selectedSearchPeopleData.clear();
                  searchPeopleBloc.imagefiles.clear();
                  searchPeopleBloc.title = '';
                  searchPeopleBloc.feeling = '';
                  searchPeopleBloc.backgroundColor = '';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(data['message'])),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(data['message'][0])),
                  );
                }
              } else {
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('Something went wrong')),
                // );
                print('add${(state)}');
              }
            },
            child: AppButton(
              shapeBorder: RoundedRectangleBorder(borderRadius: radius(4)),
              text: 'Post',
              textStyle: secondaryTextStyle(color: Colors.white, size: 10),
              onTap: () {
                searchPeopleBloc.add(AddPostDataEvent());
              },
              elevation: 0,
              color: SVAppColorPrimary,
              width: 50,
              padding: const EdgeInsets.all(0),
            ).paddingAll(16),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: context.height(),
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
                      Text(AppData.userType,
                          style: secondaryTextStyle(
                              color: svGetBodyColor(), size: 12)),
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
      ),
      // bottomNavigationBar: Column(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [SVPostOptionsComponent(searchPeopleBloc)]),
    );
  }
}
