import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_date_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../core/app_export.dart';
import '../../../utils/SVCommon.dart';
import '../bloc/profile_state.dart';

class PrivacyInfoScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  PrivacyInfoScreen({required this.profileBloc, super.key});

  @override
  State<PrivacyInfoScreen> createState() => _PrivacyInfoScreenState();
}
bool isEditModeMap = false;

class _PrivacyInfoScreenState extends State<PrivacyInfoScreen> {
  @override
  void initState() {
    isEditModeMap=false;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        title: Text('Privacy Information', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios)),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: [
          if (widget.profileBloc.isMe) CustomImageView(
            onTap: () {
              setState(() {
                isEditModeMap =!isEditModeMap;
              });
            },
            color: Colors.black,
            imagePath: 'assets/icon/ic_vector.svg',
            height: 25,
            width: 25,
            margin: const EdgeInsets.only(top: 4, right: 4),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildPrivacyInfoFields(),
              10.height,
              if(isEditModeMap)svAppButton(
                context: context,
                // style: svAppButton(text: text, onTap: onTap, context: context),
                onTap: () async {

                },
                text: 'Update',
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPrivacyInfoFields() {
    return Column(
      children: widget.profileBloc.userProfile!.privacySetting!.map((item) {
        // if(item.visibility!='crickete update d') {
        return _buildDropdownField(
          index: 4,
          label: '${item.recordType} privacy',
          value:
          item.visibility == null || item.visibility == 'crickete update d'
              ? 'lock'
              : item.visibility ?? 'lock',
          onSave: (value) => item.visibility = value,
          options: ['lock', 'group', 'globe'],
        );
        // }else{
        //   return Container();
        // }
      }).toList(),
    );
  }

  Widget _buildDropdownField({
    required int index,
    required String label,
    required String value,
    void Function(String)? onSave,
    required List<String> options,
  }) {

    options = options.where((opt) => opt != 'crickete update d.').toList();

    return isEditModeMap
        ?  Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  capitalizeWords(label.replaceAll('_', ' ')??''),
                  style: GoogleFonts.poppins(fontSize:16,fontWeight:FontWeight.w500,),
                ),
              ),
              CustomDropdownButtonFormField(
                    items: options,
                    value: value,
                    width: double.infinity,
                    contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
                    ),
                    onChanged: (String? selectedValue) {
              if (selectedValue != value) {
                onSave?.call(selectedValue!);
              }
                    },
                  ),
            ],
          ),
        )
    // DropdownButtonFormField<String>(
    //   value: value,
    //   items: options.map((option) {
    //     return DropdownMenuItem<String>(
    //       value: option,
    //       child: Text(option),
    //     );
    //   }).toList(),
    //   onChanged: (selectedValue) {
    //     if (selectedValue != value) {
    //       onSave?.call(selectedValue!);
    //     }
    //   },
    //   decoration: InputDecoration(labelText: label),
    // )
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${capitalizeWords(label)}:',
          style:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          capitalizeWords(value),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}

