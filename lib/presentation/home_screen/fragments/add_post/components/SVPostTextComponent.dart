import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nb_utils/nb_utils.dart';

import '../bloc/add_post_event.dart';


class SVPostTextComponent extends StatelessWidget {
  Function? onColorChange;
  Color? colorValue;
  AddPostBloc searchPeopleBloc;
  SVPostTextComponent(
      {this.onColorChange, this.colorValue,required this.searchPeopleBloc, Key? key,  })
      : super(key: key);

  TextEditingController textEditingController=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16,right: 16),
      // margin: const EdgeInsets.only(left: 16,right: 8),
      decoration: BoxDecoration(
          color: svGetScaffoldColor(), borderRadius: const BorderRadius.only(topLeft: Radius.circular(SVAppCommonRadius),topRight: Radius.circular(SVAppCommonRadius))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          TextField(
            style:  TextStyle(color: svGetBodyColor()),
            autofocus: false,
            maxLines: 5,
            onChanged: (value){
              searchPeopleBloc.add(TextFieldEvent(value));
              },
            cursorColor: svGetBodyColor(),
            decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Whats On Your Mind',
                hintStyle: secondaryTextStyle(size: 14, color: svGetBodyColor())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                   height: 30,width: 30,decoration: BoxDecoration(
                  color: colorValue,
                  border: Border.all(color: svGetBodyColor(),width: 1),
                  borderRadius: BorderRadius.circular(100)
                ),),
              ),Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                    onPressed: onColorChange!(),
                    icon:  Icon(
                      Icons.color_lens,
                      color: svGetBodyColor(),
                      size: 40,
                    )),
              ),
            ],
          )
        ],
      ),
    );
  }
}
