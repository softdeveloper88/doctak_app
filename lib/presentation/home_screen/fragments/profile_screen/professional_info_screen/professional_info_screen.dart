import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../../core/app_export.dart';
import '../../../utils/SVColors.dart';
import '../../../utils/SVCommon.dart';
import '../bloc/profile_state.dart';

class ProfessionalInfoScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  ProfessionalInfoScreen({required this.profileBloc, super.key});

  @override
  State<ProfessionalInfoScreen> createState() => _ProfessionalInfoScreenState();
}

bool isEditModeMap = false;
final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

class _ProfessionalInfoScreenState extends State<ProfessionalInfoScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  FocusNode focusNode4 = FocusNode();

  @override
  void initState() {
    isEditModeMap = false;
    widget.profileBloc.add(UpdateSpecialtyDropdownValue(''));

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    focusNode1.dispose();
    focusNode2.dispose();
    focusNode3.dispose();
    focusNode4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        elevation: 0,
        toolbarHeight: 70,
        surfaceTintColor: svGetScaffoldColor(),
        centerTitle: true,
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
          onPressed: () {
            Navigator.pop(context);
          }
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              color: Colors.blue[600],
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              translation(context).lbl_professional_summary,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.profileBloc.isMe)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEditModeMap ? Icons.check : Icons.edit,
                  color: isEditModeMap ? Colors.green[600] : Colors.blue[600],
                  size: 14,
                ),
              ),
              onPressed: () {
                setState(() {
                  isEditModeMap = !isEditModeMap;
                  if (!isEditModeMap) {
                    _saveChanges();
                  }
                });
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Information card
                  if (!isEditModeMap)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              translation(context).msg_professional_info_desc,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Specialty section
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.medical_services_outlined,
                                  color: Colors.blue[700],
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                translation(context).lbl_specialty_info,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Specialty dropdown if in edit mode
                          if (isEditModeMap)
                            BlocBuilder<ProfileBloc, ProfileState>(
                                bloc: widget.profileBloc,
                                builder: (context, state) {
                                  if (state is PaginationLoadedState) {
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (AppData.userType == "doctor")
                                          const SizedBox(height: 10),
                                        if (AppData.userType == "doctor")
                                          Text(
                                            translation(context).lbl_specialty,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        if (AppData.userType == "doctor")
                                          Container(
                                            margin: const EdgeInsets.only(top: 8),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: CustomDropdownButtonFormField(
                                              itemBuilder: (item) => Text(
                                                item,
                                                style: const TextStyle(color: Colors.black),
                                              ),
                                              items: state.specialtyDropdownValue,
                                              value: state.selectedSpecialtyDropdownValue,
                                              width: double.infinity,
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 4,
                                              ),
                                              onChanged: (String? newValue) {
                                                print(newValue);
                                                print("Specialty $newValue");
                                                widget.profileBloc.specialtyName = newValue!;
                                                widget.profileBloc.userProfile?.user?.specialty = newValue;
                                                widget.profileBloc.add(UpdateSpecialtyDropdownValue(newValue));
                                              },
                                            ),
                                          ),
                                      ],
                                    );
                                  } else {
                                    return Text(translation(context).lbl_unknown_state);
                                  }
                                }
                            ),

                          // Title and specialization in view mode
                          if (!isEditModeMap)
                            TextFieldEditWidget(
                              index: 0,
                              label: translation(context).lbl_title_and_specialization,
                              value: widget.profileBloc.userProfile?.user?.specialty ?? '',
                              onSave: (value) => widget.profileBloc.userProfile?.user?.specialty = value,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Workplace and experience card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.business_center_outlined,
                                  color: Colors.orange[700],
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                translation(context).lbl_workplace_info,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Current workplace field
                          TextFieldEditWidget(
                            isEditModeMap: isEditModeMap,
                            icon: Icons.location_on,
                            index: 1,
                            textInputAction: TextInputAction.newline,
                            textInputType: TextInputType.multiline,
                            focusNode: focusNode1,
                            hints: translation(context).hint_workplace,
                            label: translation(context).lbl_current_workplace,
                            value: widget.profileBloc.userProfile?.profile?.address ?? '',
                            onSave: (value) => widget.profileBloc.userProfile?.profile?.address = value,
                          ),

                          if (!isEditModeMap)
                            Divider(
                              color: Colors.grey[200],
                              thickness: 1,
                              indent: 10,
                              endIndent: 10,
                            ),

                          // Years of experience field
                          TextFieldEditWidget(
                            isEditModeMap: isEditModeMap,
                            icon: Icons.account_circle,
                            index: 1,
                            textInputType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            hints: translation(context).hint_years_experience,
                            focusNode: focusNode2,
                            label: translation(context).lbl_years_experience,
                            value: widget.profileBloc.userProfile?.profile?.aboutMe ?? '',
                            onSave: (value) => widget.profileBloc.userProfile!.profile?.aboutMe = value,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Achievements and location card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.emoji_events_outlined,
                                  color: Colors.green[700],
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                translation(context).lbl_achievements_and_location,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Notable achievements field
                          TextFieldEditWidget(
                            isEditModeMap: isEditModeMap,
                            icon: Icons.star_border_rounded,
                            index: 1,
                            textInputAction: TextInputAction.newline,
                            hints: translation(context).hint_notable_achievements,
                            focusNode: focusNode3,
                            label: translation(context).lbl_notable_achievements,
                            value: widget.profileBloc.userProfile?.profile?.birthplace ?? '',
                            onSave: (value) => widget.profileBloc.userProfile!.profile?.birthplace = value,
                            textInputType: TextInputType.multiline,
                          ),

                          if (!isEditModeMap)
                            Divider(
                              color: Colors.grey[200],
                              thickness: 1,
                              indent: 10,
                              endIndent: 10,
                            ),

                          // Location field
                          TextFieldEditWidget(
                            isEditModeMap: isEditModeMap,
                            icon: Icons.location_on_outlined,
                            index: 1,
                            textInputAction: TextInputAction.newline,
                            textInputType: TextInputType.multiline,
                            focusNode: focusNode4,
                            hints: translation(context).hint_location,
                            label: translation(context).lbl_location,
                            value: widget.profileBloc.userProfile?.profile?.hobbies ?? '',
                            onSave: (value) => widget.profileBloc.userProfile!.profile?.hobbies = value,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Update button
                  if (isEditModeMap)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              translation(context).lbl_update,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }

    widget.profileBloc.add(UpdateProfileEvent(
      updateProfileSection: 2,
      userProfile: widget.profileBloc.userProfile,
      interestModel: widget.profileBloc.interestList,
      workEducationModel: widget.profileBloc.workEducationList,
      userProfilePrivacyModel: UserProfilePrivacyModel(),
    ));

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(translation(context).msg_profile_updated),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}