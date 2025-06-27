import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/SVCommon.dart';
import '../component/profile_date_widget.dart';
import '../component/profile_widget.dart';

class AddEditWorkScreen extends StatefulWidget {
  ProfileBloc profileBloc;
  WorkEducationModel? updateWork;
  AddEditWorkScreen({
    required this.profileBloc,
    this.updateWork,
    super.key,
  });

  @override
  State<AddEditWorkScreen> createState() => _AddEditWorkScreenState();
}

GlobalKey<FormState> _formKey = GlobalKey<FormState>();

bool isEditModeMap = false;
WorkEducationModel? updateWork = WorkEducationModel();

class _AddEditWorkScreenState extends State<AddEditWorkScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> listWorkType = ['work', 'university', 'high_school'];
  List<String> privacyList = ['global', 'private', 'only me'];
  List<String> positionList = [
    'Resident Physician',
    'Attending Physician',
    'Fellow',
    'Consultant',
    'Surgeon',
    'General Practitioner',
    'Medical Officer',
    'Researcher',
    'Educator/Teacher/Professor'
  ];

  var focusNode1 = FocusNode();
  var focusNode2 = FocusNode();
  var focusNode3 = FocusNode();
  var focusNode4 = FocusNode();
  var focusNode5 = FocusNode();
  String privacy = 'global';

  @override
  void initState() {
    if (widget.updateWork != null) {
      updateWork = widget.updateWork;
      updateWork?.workType = widget.updateWork?.workType ?? "work";
      privacy = widget.updateWork?.privacy ?? 'global';
    } else {
      updateWork = WorkEducationModel();
      updateWork?.workType = 'work';
      widget.profileBloc.add(UpdateSpecialtyDropdownValue(''));
    }

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
    focusNode5.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: DoctakAppBar(
        title: widget.updateWork != null
            ? translation(context).lbl_edit
            : translation(context).lbl_add_experience,
        titleIcon: widget.updateWork != null ? Icons.edit_outlined : Icons.work_outline,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildWorkInfoFields(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkInfoFields() {
    return Column(
      children: [
        // Form container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form heading
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.work_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.updateWork != null
                          ? translation(context).lbl_update_experience_details
                          : translation(context).lbl_add_experience_details,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Specialty section for doctors
                if (updateWork?.workType == 'work')
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
                                const SizedBox(height: 8),
                              if (AppData.userType == "doctor")
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: CustomDropdownButtonFormField(
                                    itemBuilder: (item) => Text(
                                      item,
                                      style:
                                          const TextStyle(color: Colors.black),
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
                                      updateWork?.name = newValue;
                                      widget.profileBloc.add(
                                          UpdateSpecialtyDropdownValue(
                                              newValue ?? ''));
                                    },
                                  ),
                                ),
                            ],
                          );
                        } else {
                          return Text(translation(context).lbl_unknown_state);
                        }
                      }),

                // Position/Role dropdown
                const SizedBox(height: 20),
                Text(
                  translation(context).lbl_position_role,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: CustomDropdownButtonFormField(
                    itemBuilder: (item) => Text(
                      item,
                      style: const TextStyle(color: Colors.black),
                    ),
                    items: positionList,
                    value: updateWork?.position ?? positionList.first,
                    width: double.infinity,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        updateWork?.position = newValue;
                      });
                    },
                  ),
                ),

                // Hospital/Clinic name field
                const SizedBox(height: 20),
                TextFieldEditWidget(
                  focusNode: focusNode2,
                  isEditModeMap: true,
                  icon: Icons.local_hospital,
                  index: 2,
                  hints: translation(context).hint_hospital_name,
                  label: translation(context).lbl_hospital_clinic_name,
                  value: updateWork?.address ?? "",
                  onSave: (value) => updateWork?.address = value,
                ),

                // Degree field (for educational entries)
                if (updateWork?.workType != 'work') const SizedBox(height: 20),
                if (updateWork?.workType != 'work')
                  TextFieldEditWidget(
                    focusNode: focusNode3,
                    isEditModeMap: true,
                    icon: Icons.school,
                    index: 2,
                    label: translation(context).lbl_degree,
                    value: updateWork?.degree ?? "",
                    onSave: (value) => updateWork?.degree = value,
                  ),

                // Courses field (for educational entries)
                if (updateWork?.workType != 'work') const SizedBox(height: 20),
                if (updateWork?.workType != 'work')
                  TextFieldEditWidget(
                    isEditModeMap: true,
                    focusNode: focusNode4,
                    icon: Icons.book,
                    index: 2,
                    label: translation(context).lbl_courses,
                    value: updateWork?.courses ?? "",
                    onSave: (value) => updateWork?.courses = value,
                  ),

                // Location field
                const SizedBox(height: 20),
                TextFieldEditWidget(
                  isEditModeMap: true,
                  icon: Icons.location_on,
                  focusNode: focusNode5,
                  index: 2,
                  hints: translation(context).hint_location,
                  label: translation(context).lbl_location,
                  value: updateWork?.description ?? "",
                  onSave: (value) => updateWork?.description = value,
                  maxLines: 2,
                ),

                // Date fields
                const SizedBox(height: 20),
                ProfileDateWidget(
                  isEditModeMap: true,
                  index: 2,
                  label: translation(context).lbl_start_date,
                  value: updateWork?.startDate ?? '',
                  onSave: (value) => updateWork?.startDate = value,
                ),

                const SizedBox(height: 20),
                ProfileDateWidget(
                  isEditModeMap: true,
                  index: 2,
                  label: translation(context).lbl_end_date,
                  value: updateWork?.endDate ?? '',
                  onSave: (value) => updateWork?.endDate = value,
                ),

                // Privacy dropdown
                const SizedBox(height: 20),
                Text(
                  translation(context).lbl_privacy,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: CustomDropdownButtonFormField(
                    itemBuilder: (item) => Row(
                      children: [
                        Icon(
                          item == 'only me'
                              ? Icons.lock_outline
                              : item == 'private'
                                  ? Icons.people_outline
                                  : Icons.public,
                          size: 16,
                          color: item == 'only me'
                              ? Colors.red
                              : item == 'private'
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item == 'only me'
                              ? translation(context).lbl_only_me
                              : item == 'private'
                                  ? translation(context).lbl_friends
                                  : translation(context).lbl_public,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                    items: privacyList,
                    value: privacy,
                    width: double.infinity,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        privacy = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        Container(
          margin: const EdgeInsets.only(top: 24),
          child: Row(
            children: [
              // Cancel button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    translation(context).lbl_cancel,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Save button
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveExperience,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.updateWork != null
                            ? translation(context).lbl_update
                            : translation(context).lbl_add,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveExperience() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }

    var currentStatus = 0;
    if (updateWork?.endDate == '' || updateWork?.endDate == null) {
      currentStatus = 1;
    } else {
      currentStatus = 0;
    }

    if (widget.updateWork != null) {
      print(updateWork?.id);
      widget.profileBloc.add(UpdateAddWorkEductionEvent(
          widget.updateWork?.id.toString() ?? '0',
          updateWork?.name ?? "",
          updateWork?.position ?? "",
          updateWork?.address ?? "",
          updateWork?.degree ?? "",
          updateWork?.courses ?? "",
          updateWork?.workType ?? "",
          updateWork?.startDate ?? "",
          updateWork?.endDate ?? "",
          currentStatus.toString(),
          updateWork?.description ?? "",
          privacy));
    } else {
      widget.profileBloc.add(UpdateAddWorkEductionEvent(
          '',
          updateWork?.name ?? "",
          updateWork?.position ?? "",
          updateWork?.address ?? "",
          updateWork?.degree ?? "",
          updateWork?.courses ?? "",
          updateWork?.workType ?? "",
          updateWork?.startDate ?? "",
          updateWork?.endDate ?? "",
          updateWork?.currentStatus ?? "",
          updateWork?.description ?? "",
          privacy));
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.updateWork != null
              ? translation(context).msg_experience_updated
              : translation(context).msg_experience_added,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    Navigator.pop(context);
  }
}
