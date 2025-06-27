import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/widgets/custom_image_view.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/SVColors.dart';
import '../../../utils/SVCommon.dart';

class InterestedInfoScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  InterestedInfoScreen({required this.profileBloc, super.key});

  @override
  State<InterestedInfoScreen> createState() => _InterestedInfoScreenState();
}

bool isEditModeMap = false;

class _InterestedInfoScreenState extends State<InterestedInfoScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    isEditModeMap = false;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: DoctakAppBar(
        title: translation(context).lbl_interest_information,
        titleIcon: Icons.lightbulb_outline,
        actions: [
          if (widget.profileBloc.isMe)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEditModeMap ? Icons.check : Icons.edit,
                  color: isEditModeMap ? Colors.green[600] : Colors.blue[600],
                  size: 16,
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
          padding: const EdgeInsets.all(16.0),
          child: widget.profileBloc.interestList!.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
            child: Column(
              children: [
                // Information header
                if (!isEditModeMap)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.purple[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            translation(context).msg_interests_info_desc,
                            style: TextStyle(
                              color: Colors.purple[700],
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                _buildInterestedInfoFields(),

                const SizedBox(height: 24),

                // Update button
                if (isEditModeMap)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
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
    );
  }

  // Empty state with illustration and add button
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/img_cover.png', // Replace with appropriate empty state image
            width: 180,
            height: 180,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 24),
          Text(
            translation(context).lbl_no_interest_added,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            translation(context).msg_add_interests,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          if (widget.profileBloc.isMe)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isEditModeMap = true;
                });
              },
              icon: const Icon(Icons.add),
              label: Text(translation(context).lbl_add_interests),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
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

  Widget _buildInterestedInfoFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Areas of interest card
          _buildInterestCard(
            title: translation(context).lbl_areas_of_interest,
            index: 0,
            icon: Icons.medical_information,
            color: Colors.blue,
          ),

          const SizedBox(height: 16),

          // Conferences participation card
          _buildInterestCard(
            title: translation(context).lbl_conferences_participation,
            index: 1,
            icon: Icons.event_note,
            color: Colors.orange,
          ),

          const SizedBox(height: 16),

          // Research projects card
          _buildInterestCard(
            title: translation(context).lbl_research_projects,
            index: 3,
            icon: Icons.science,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  // Helper method to build interest cards
  Widget _buildInterestCard({
    required String title,
    required int index,
    required IconData icon,
    required Color color,
  }) {
    if (widget.profileBloc.interestList!.length <= index) {
      return const SizedBox.shrink();
    }

    return Card(
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    capitalizeWords(title),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isEditModeMap)
            // Edit mode - text field
              TextFieldEditWidget(
                isEditModeMap: true,
                icon: icon,
                index: 2,
                hints: _getPlaceholderForIndex(index, context),
                label: translation(context).lbl_interest_details,
                value: widget.profileBloc.interestList?[index].interestDetails ?? "",
                onSave: (value) => widget.profileBloc.interestList?[index].interestDetails = value,
                maxLines: 3,
              )
            else
            // View mode - display text
              if (widget.profileBloc.interestList?[index].interestDetails != null &&
                  widget.profileBloc.interestList![index].interestDetails!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.profileBloc.interestList![index].interestDetails!,
                    style: TextStyle(
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      translation(context).msg_no_details_added,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // Helper to get appropriate placeholders for different interests
  String _getPlaceholderForIndex(int index, BuildContext context) {
    switch (index) {
      case 0:
        return translation(context).hint_areas_of_interest;
      case 1:
        return translation(context).hint_publications;
      case 3:
        return translation(context).hint_clinical_trials;
      default:
        return '';
    }
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }

    widget.profileBloc.add(UpdateAddHobbiesInterestEvent(
        '',
        widget.profileBloc.interestList!.isEmpty
            ? ''
            : widget.profileBloc.interestList?[0].interestDetails ?? "",
        widget.profileBloc.interestList!.length >= 2
            ? widget.profileBloc.interestList![1].interestDetails ?? ""
            : '',
        widget.profileBloc.interestList!.length >= 3
            ? widget.profileBloc.interestList![3].interestDetails ?? ""
            : '',
        '',
        '',
        ''
    ));

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(translation(context).msg_interests_updated),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}