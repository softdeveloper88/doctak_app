import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_date_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

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
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        surfaceTintColor: svGetScaffoldColor(),
        backgroundColor: svGetScaffoldColor(),
        title: Text('Privacy Information', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child:  Icon(Icons.arrow_back_ios,color: svGetBodyColor())),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: [
          if (widget.profileBloc.isMe)  Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CustomImageView(
                onTap: () {
                  setState(() {
                    isEditModeMap =!isEditModeMap;
                  });
                },
                color: Colors.blue,
                imagePath: 'assets/icon/ic_vector.svg',
                height: 20,
                width: 20,
                margin: const EdgeInsets.only(top: 4, right: 16),
              ),
              Text("Edit",style: GoogleFonts.poppins(fontSize: 8.sp,fontWeight: FontWeight.w400,color: Colors.blue),)
            ],
          ).paddingTop(10),
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
                  setState(() {
                    isEditModeMap=false;
                  });
                  widget.profileBloc.add(UpdateProfileEvent(
                    updateProfileSection: 1,
                    userProfile: widget.profileBloc.userProfile,
                    interestModel: widget.profileBloc.interestList,
                    workEducationModel: widget.profileBloc.workEducationList,
                    userProfilePrivacyModel: UserProfilePrivacyModel(),
                  ));
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
        var selectValue=item.visibility=='lock'?'Only me': item.visibility=='group'?'Friend':'Public';

        return _buildDropdownField(
          index: 4,
          label: '${item.recordType} privacy',
          value:
          item.visibility == null || item.visibility == 'crickete update d'
              ? 'Only me'
              :selectValue ,
          onSave: (value) {

            value=='Only me'?'lock': value=='Friend'?'group':'Public';
            item.visibility = value;
          },
          options: ['Only me', 'Friend', 'Public'],
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
                  style: GoogleFonts.poppins(fontSize:16,fontWeight:FontWeight.w500,color: svGetBodyColor()),
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
        : Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 16,bottom: 16),
              child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
              Text(
                capitalizeWords(label),
                style: GoogleFonts.poppins(color: svGetBodyColor(),fontSize: 10.sp,fontWeight: FontWeight.w500),
                  ),
              Text(
                capitalizeWords(value),
                style:GoogleFonts.poppins(color: svGetBodyColor(),fontSize: 10.sp,fontWeight: FontWeight.w500),
              ),
                    ],
                  ),
            ),
            Divider(color: Colors.grey[300],indent: 10,endIndent: 10,),

          ],
        );
  }
}

