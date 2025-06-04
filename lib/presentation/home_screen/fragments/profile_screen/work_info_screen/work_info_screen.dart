import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/text_view_widget.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../core/utils/app/AppData.dart';
import '../../../utils/SVColors.dart';
import '../../../utils/SVCommon.dart';
import 'add_edit_work_screen.dart';

class WorkInfoScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  WorkInfoScreen({required this.profileBloc, super.key});

  @override
  State<WorkInfoScreen> createState() => _WorkInfoScreenState();
}

bool isEditModeMap = false;

class _WorkInfoScreenState extends State<WorkInfoScreen> with SingleTickerProviderStateMixin {
  List<WorkEducationModel> workList = [];
  List<WorkEducationModel> universityList = [];
  List<WorkEducationModel> highSchool = [];

  // Animation controller for smoother transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    isEditModeMap = false;

    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
              Icons.business_center_rounded,
              color: Colors.blue[600],
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              translation(context).lbl_professional_experience,
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
                  Icons.add,
                  color: Colors.blue[600],
                  size: 14,
                ),
              ),
              onPressed: () {
                setState(() {
                  _animationController.reset();
                  AddEditWorkScreen(profileBloc: widget.profileBloc)
                      .launch(context);
                  _animationController.forward();
                });
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        bloc: widget.profileBloc,
        builder: (BuildContext context, ProfileState state) {
          if (state is PaginationLoadedState) {
            workList = widget.profileBloc.workEducationList!
                .where((work) => work.workType == 'work')
                .toList();

            return FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Info header
                      if(widget.profileBloc.workEducationList!.isEmpty)
                        _buildEmptyStateCard(),

                      if (workList.isNotEmpty)
                        _buildWorkInfoFields(workList, 'work'),

                      if (universityList.isNotEmpty)
                        _buildWorkInfoFields(universityList, 'university'),

                      if (highSchool.isNotEmpty)
                        _buildWorkInfoFields(highSchool, 'high_school'),

                      10.height,
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
        listener: (BuildContext context, ProfileState state) {},
      ),
    );
  }

  // Empty state widget with illustration
  Widget _buildEmptyStateCard() {
    return Container(
      height: 500,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/img_cover.png', // Replace with an appropriate empty state image
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 20),
          Text(
            translation(context).lbl_no_experience_found,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            translation(context).msg_add_experience,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          if (widget.profileBloc.isMe)
            ElevatedButton.icon(
              onPressed: () {
                AddEditWorkScreen(profileBloc: widget.profileBloc)
                    .launch(context);
              },
              icon: const Icon(Icons.add),
              label: Text(translation(context).lbl_add_experience),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkInfoFields(List<WorkEducationModel> list, String type) {
    return list.isEmpty
        ? SizedBox(height: 500, child: Center(child: Text(translation(context).lbl_no_experience_found)))
        : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            margin: const EdgeInsets.only(bottom: 16, top: 8),
            child: Row(
              children: [
                Icon(
                  type == 'work'
                      ? Icons.business_center_rounded
                      : type == 'university'
                      ? Icons.school_rounded
                      : Icons.menu_book_rounded,
                  color: type == 'work'
                      ? Colors.blue[700]
                      : type == 'university'
                      ? Colors.green[700]
                      : Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  capitalizeWords(type),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: type == 'work'
                        ? Colors.blue[700]
                        : type == 'university'
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),

          // Experience cards
          Column(
            children: list
                .map(
                  (entry) => Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card header with info and actions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: type == 'work'
                            ? Colors.blue.withOpacity(0.05)
                            : type == 'university'
                            ? Colors.green.withOpacity(0.05)
                            : Colors.orange.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Title and position
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.name ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (entry.position != null && entry.position!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      entry.position ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Action buttons
                      if(widget.profileBloc.isMe)    Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  AddEditWorkScreen(
                                    profileBloc: widget.profileBloc,
                                    updateWork: entry,
                                  ).launch(context);
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.pencil,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return CustomAlertDialog(
                                        title: translation(context).msg_confirm_delete_info,
                                        callback: () {
                                          widget.profileBloc.add(
                                            DeleteWorkEducationEvent(entry.id.toString()),
                                          );
                                          Navigator.of(context).pop();
                                        },
                                      );
                                    },
                                  );
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.trash,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Card body with details
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Specialty area
                          if (type == 'work' && entry.name != null && entry.name!.isNotEmpty)
                            _buildDetailItem(
                              label: translation(context).lbl_specialty_area,
                              value: entry.name ?? '',
                              icon: Icons.medical_services_outlined,
                              iconColor: Colors.blue,
                            ),

                          // Position/Role
                          if (type == 'work')
                            _buildDetailItem(
                              label: translation(context).lbl_position_role,
                              value: entry.position ?? "",
                              icon: Icons.work_outline_rounded,
                              iconColor: Colors.orange,
                            ),

                          // Hospital/Clinic
                          _buildDetailItem(
                            label: translation(context).lbl_hospital_clinic_name,
                            value: entry.address ?? "",
                            icon: Icons.local_hospital_outlined,
                            iconColor: Colors.red,
                          ),

                          // Degree for educational entries
                          if (type != 'work' && entry.degree != null && entry.degree!.isNotEmpty)
                            _buildDetailItem(
                              label: translation(context).lbl_degree,
                              value: entry.degree ?? "",
                              icon: Icons.school_outlined,
                              iconColor: Colors.purple,
                            ),

                          // Courses for educational entries
                          if (type != 'work' && entry.courses != null && entry.courses!.isNotEmpty)
                            _buildDetailItem(
                              label: translation(context).lbl_courses,
                              value: entry.courses ?? "",
                              icon: Icons.menu_book_outlined,
                              iconColor: Colors.green,
                            ),

                          // Location
                          if (entry.description != null && entry.description!.isNotEmpty)
                            _buildDetailItem(
                              label: translation(context).lbl_location,
                              value: entry.description ?? "",
                              icon: Icons.location_on_outlined,
                              iconColor: Colors.blue,
                            ),

                          // Date section
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      translation(context).lbl_duration,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // Start date
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            translation(context).lbl_start_date,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            entry.startDate ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // End date
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            translation(context).lbl_end_date,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            entry.endDate?.isEmpty ?? true
                                                ? translation(context).lbl_present
                                                : entry.endDate ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
                .toList(),
          )
        ]
    );
  }

  // Helper for detail item with icon
  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}