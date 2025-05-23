import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../../../../core/app_export.dart';
import '../../../utils/SVColors.dart';
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
    isEditModeMap = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var selectValue =
        widget.profileBloc.userProfile!.privacySetting?[1].visibility == 'lock'
            ? translation(context).lbl_only_me
            : widget.profileBloc.userProfile!.privacySetting?[1].visibility ==
                    'group'
                ? translation(context).lbl_friends
                : translation(context).lbl_public;
    var selectValue2 =
        widget.profileBloc.userProfile!.privacySetting?[10].visibility == 'lock'
            ? translation(context).lbl_only_me
            : widget.profileBloc.userProfile!.privacySetting?[10].visibility ==
                    'group'
                ? translation(context).lbl_friends
                : translation(context).lbl_public;
    print(widget.profileBloc.userProfile!.privacySetting?[1].recordType);
    print(widget.profileBloc.userProfile!.privacySetting?[1].visibility);
    print(widget.profileBloc.userProfile!.privacySetting?[10].recordType);
    print(widget.profileBloc.userProfile!.privacySetting?[10].visibility);
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        surfaceTintColor: svGetScaffoldColor(),
        backgroundColor: svGetScaffoldColor(),
        title: Text(translation(context).lbl_privacy_information, style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Icon(Icons.arrow_back_ios, color: svGetBodyColor(),size: 17,)),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: [
          if (widget.profileBloc.isMe)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MaterialButton(
                textColor: Colors.black,
                onPressed: () {
                  setState(() {
                    isEditModeMap = !isEditModeMap;
                  });
                },
                elevation: 0,
                color: Colors.white,

                minWidth: 40,
                // shape: RoundedRectangleBorder(
                //   borderRadius: radius(100),
                //   side: const BorderSide(color: Colors.blue),
                // ),
                animationDuration: const Duration(milliseconds: 300),
                focusColor: SVAppColorPrimary,
                hoverColor: SVAppColorPrimary,
                splashColor: SVAppColorPrimary,
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomImageView(
                      onTap: () {
                        setState(() {
                          isEditModeMap = !isEditModeMap;
                        });
                      },
                      color: Colors.black,
                      imagePath: 'assets/icon/ic_vector.svg',
                      height: 15,
                      width: 15,
                      // margin: const EdgeInsets.only(bottom: 4),
                    ),
                    // const Text(
                    //   "Edit",
                    //   style:  TextStyle(fontFamily: 'Poppins',
                    //     fontSize: 10,
                    //     fontWeight: FontWeight.w400,
                    //     color: Colors.blue,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // _buildDropdownField(
              //   index: 2,
              //   label: 'Personal Information privacy',
              //   value:widget.profileBloc.userProfile!.privacySetting?[1].visibility == null || widget.profileBloc.userProfile!.privacySetting?[1].visibility == 'crickete update d'
              //       ? 'Only me'
              //       :selectValue ,
              //   onSave: (value) {
              //     var updateValue=  value=='Only me'?'lock': value=='Friend'?'group':'Public';
              //     widget.profileBloc.userProfile!.privacySetting?[1].visibility = updateValue;
              //
              //     },
              //   options: ['Only me', 'Friend', 'Public'],
              // ),
              // _buildDropdownField(
              //   index: 2,
              //   label: 'About me privacy',
              //   value:widget.profileBloc.userProfile!.privacySetting?[10].visibility == null || widget.profileBloc.userProfile!.privacySetting?[10].visibility == 'crickete update d'
              //       ? 'Only me'
              //       :selectValue2 ,
              //   onSave: (value) {
              //     var updateValue =  value=='Only me'?'lock': value=='Friend'?'group':'Public';
              //     widget.profileBloc.userProfile!.privacySetting?[10].visibility = updateValue;
              //   },
              //   options: ['Only me', 'Friend', 'Public'],
              // ),
              _buildPrivacyInfoFields(),
              10.height,
              if (isEditModeMap)
                svAppButton(
                  context: context,
                  // style: svAppButton(text: text, onTap: onTap, context: context),
                  onTap: () async {
                    setState(() {
                      isEditModeMap = false;
                    });
                    widget.profileBloc.add(UpdateProfileEvent(
                      updateProfileSection: 3,
                      userProfile: widget.profileBloc.userProfile,
                      interestModel: widget.profileBloc.interestList,
                      workEducationModel: widget.profileBloc.workEducationList,
                      userProfilePrivacyModel: UserProfilePrivacyModel(),
                    ));
                  },
                  text: translation(context).lbl_update,
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
        print(item.recordType);
        // if(item.visibility!='crickete update d') {
        var selectValue = item.visibility == 'lock'
            ? translation(context).lbl_only_me
            : item.visibility == 'group'
                ? translation(context).lbl_friends
                : translation(context).lbl_public;

        return _buildDropdownField(
          index: 4,
          label: item.recordType == 'dob'
              ? translation(context).lbl_date_of_birth
              : '${item.recordType?.replaceAll('_', ' ')} ',
          value:
              item.visibility == null || item.visibility == 'crickete update d'
                  ? translation(context).lbl_only_me
                  : selectValue,
          onSave: (value) {
            var updateValue = value == translation(context).lbl_only_me
                ? 'lock'
                : value == translation(context).lbl_friends
                    ? 'group'
                    : 'Public';
            item.visibility = updateValue;
          },
          options: [translation(context).lbl_only_me, translation(context).lbl_friends, translation(context).lbl_public],
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
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    capitalizeWords(label.replaceAll('_', ' ') ?? ''),
                    style:  TextStyle(fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: svGetBodyColor()),
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
                  itemBuilder: (item) => Text(
                    item,
                    style: const TextStyle(color: Colors.black),
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
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 8.0, right: 8.0, top: 16, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      capitalizeWords(label),
                      style:  TextStyle(fontFamily: 'Poppins',
                          color: svGetBodyColor(),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      capitalizeWords(value),
                      style:  TextStyle(fontFamily: 'Poppins',
                          color: svGetBodyColor(),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Divider(
                color: Colors.grey[300],
                indent: 10,
                endIndent: 10,
              ),
            ],
          );
  }
}
