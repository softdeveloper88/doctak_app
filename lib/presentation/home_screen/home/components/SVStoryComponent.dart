import 'dart:io';

import 'package:doctak_app/presentation/home_screen/models/SVStoryModel.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';


class SVStoryComponent extends StatefulWidget {
  @override
  State<SVStoryComponent> createState() => _SVStoryComponentState();
}

class _SVStoryComponentState extends State<SVStoryComponent> {
  List<SVStoryModel> storyList = getStories();
  File? image;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: SVAppColorPrimary,
                  borderRadius: radius(SVAppCommonRadius),
                ),
                child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () async {
                      image = await svGetImageSource();
                    }),
              ),
              10.height,
              Text('Your Story', style: secondaryTextStyle(size: 12, color: context.iconColor, weight: FontWeight.w500)),
            ],
          ),
          HorizontalList(
            spacing: 16,
            itemCount: storyList.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: SVAppColorPrimary, width: 2),
                      borderRadius: radius(14),
                    ),
                    child: Image.asset(
                      storyList[index].profileImage.validate(),
                      height: 58,
                      width: 58,
                      fit: BoxFit.cover,
                    ).cornerRadiusWithClipRRect(SVAppCommonRadius),
                  ).onTap(() {
                    // SVStoryScreen(story: storyList[index]).launch(context);
                  }),
                  10.height,
                  Text(storyList[index].name.validate(), style: secondaryTextStyle(size: 12, color: context.iconColor, weight: FontWeight.w500)),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}
