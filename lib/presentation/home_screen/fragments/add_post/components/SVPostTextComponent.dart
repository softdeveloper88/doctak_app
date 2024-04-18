import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
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
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colorValue, borderRadius: radius(SVAppCommonRadius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,


        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            autofocus: false,
            maxLines: 5,
            onChanged: (value){
              searchPeopleBloc.add(TextFieldEvent(value));
              },
            cursorColor: Colors.white,
            decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Whats On Your Mind',
                hintStyle: secondaryTextStyle(size: 14, color: Colors.white)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
                onPressed: onColorChange!(),
                icon: const Icon(
                  Icons.color_lens,
                  color: Colors.black,
                  size: 40,
                )),
          )
        ],
      ),
    );
  }
}
