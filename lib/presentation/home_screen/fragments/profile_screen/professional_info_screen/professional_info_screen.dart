import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../core/app_export.dart';
import '../../../utils/SVCommon.dart';

class ProfessionalInfoScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  ProfessionalInfoScreen({required this.profileBloc, super.key});

  @override
  State<ProfessionalInfoScreen> createState() => _ProfessionalInfoScreenState();
}

bool isEditModeMap = false;
final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

class _ProfessionalInfoScreenState extends State<ProfessionalInfoScreen> {
   @override
  void initState() {
     isEditModeMap = false;
     super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        title: Text('Professional Information', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios)),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: [
          if (widget.profileBloc.isMe)  CustomImageView(
            onTap: () {
              setState(() {
                isEditModeMap = !isEditModeMap;
              });
            },
            color: Colors.black,
            imagePath: 'assets/icon/ic_vector.svg',
            height: 25.adaptSize,
            width: 25.adaptSize,
            margin: EdgeInsets.only(top: 4.v, right: 4.v),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                ProfileWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.location_on,
                  index: 1,
                  label: 'Address',
                  value: widget.profileBloc.userProfile?.profile?.address ?? '',
                  onSave: (value) => widget.profileBloc.userProfile?.profile?.address = value,),
                // const Divider(),
                if (!isEditModeMap)
                  const Divider(
                    color: Colors.grey,
                  ),
                ProfileWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.account_circle,
                  index: 1,
                  label: 'About Me',
                  value: widget.profileBloc.userProfile?.profile?.aboutMe ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile!.profile?.aboutMe = value,
                  maxLines: 3,
                ),
                if (!isEditModeMap)
                  const Divider(
                    color: Colors.grey,
                  ),
                ProfileWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.location_on,
                  index: 1,
                  label: 'Birth Place',
                  value: widget.profileBloc.userProfile?.profile?.birthplace ?? '',
                  onSave: (value) => widget.profileBloc.userProfile!.profile?.birthplace = value,
                  maxLines: 3,
                ),
                if (!isEditModeMap)   const Divider(
                    color: Colors.grey,
                  ),
                ProfileWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.sports,
                  index: 1,
                  label: 'Hobbies',
                  value: widget.profileBloc.userProfile?.profile?.hobbies ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile!.profile?.hobbies = value,
                  maxLines: 3,
                ),
                if (!isEditModeMap) const Divider(
                    color: Colors.grey,
                  ),
                ProfileWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.live_help,
                  index: 1,
                  label: 'Lives In',
                  value: widget.profileBloc.userProfile?.profile?.livesIn ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile!.profile?.livesIn = value,
                  maxLines: 3,
                ),
                10.height,
                if (isEditModeMap)
                  svAppButton(
                    context: context,
                    // style: svAppButton(text: text, onTap: onTap, context: context),
                    onTap: () async {
                      setState(() {
                        isEditModeMap = false;
                      });
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                      }
                      widget.profileBloc.add(UpdateProfileEvent(
                        updateProfileSection: 2,
                        userProfile: widget.profileBloc.userProfile,
                        interestModel: widget.profileBloc.interestList,
                        workEducationModel:
                            widget.profileBloc.workEducationList,
                        userProfilePrivacyModel: UserProfilePrivacyModel(),
                      ));
                    },
                    text: 'Update',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
