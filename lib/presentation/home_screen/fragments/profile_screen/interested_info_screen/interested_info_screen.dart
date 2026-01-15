import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/one_ui_profile_components.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';

class InterestedInfoScreen extends StatefulWidget {
  final ProfileBloc profileBloc;

  const InterestedInfoScreen({required this.profileBloc, super.key});

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
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

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
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_interest_information,
        titleIcon: Icons.lightbulb_outline,
        actions: [
          if (widget.profileBloc.isMe)
            OneUIEditActionButton(
              isEditMode: isEditModeMap,
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
              ? _buildEmptyState(theme)
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Information header
                      if (!isEditModeMap) OneUIInfoBanner(message: translation(context).msg_interests_info_desc, icon: Icons.lightbulb_outline, accentColor: Colors.purple),

                      _buildInterestedInfoFields(theme),

                      const SizedBox(height: 24),

                      // Update button
                      if (isEditModeMap) OneUIProfilePrimaryButton(label: translation(context).lbl_update, icon: Icons.check_circle, color: theme.primary, onPressed: _saveChanges),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // Empty state with illustration and add button
  Widget _buildEmptyState(OneUITheme theme) {
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
          Text(translation(context).lbl_no_interest_added, style: theme.titleMedium),
          const SizedBox(height: 16),
          Text(translation(context).msg_add_interests, textAlign: TextAlign.center, style: theme.bodySecondary),
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
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: theme.radiusFull),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInterestedInfoFields(OneUITheme theme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Areas of interest card
          _buildInterestCard(title: translation(context).lbl_areas_of_interest, index: 0, icon: Icons.medical_information, color: theme.primary, theme: theme),

          const SizedBox(height: 16),

          // Conferences participation card
          _buildInterestCard(title: translation(context).lbl_conferences_participation, index: 1, icon: Icons.event_note, color: theme.warning, theme: theme),

          const SizedBox(height: 16),

          // Research projects card
          _buildInterestCard(title: translation(context).lbl_research_projects, index: 3, icon: Icons.science, color: theme.success, theme: theme),
        ],
      ),
    );
  }

  // Helper method to build interest cards
  Widget _buildInterestCard({required String title, required int index, required IconData icon, required Color color, required OneUITheme theme}) {
    if (widget.profileBloc.interestList!.length <= index) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: theme.cardDecoration,
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
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: theme.radiusM),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    capitalizeWords(title),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
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
            if (widget.profileBloc.interestList?[index].interestDetails != null && widget.profileBloc.interestList![index].interestDetails!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: theme.radiusM),
                child: Text(widget.profileBloc.interestList![index].interestDetails!, style: TextStyle(color: theme.textPrimary, height: 1.5)),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: theme.radiusM,
                  border: Border.all(color: theme.border),
                ),
                child: Center(
                  child: Text(translation(context).msg_no_details_added, style: theme.caption.copyWith(fontStyle: FontStyle.italic)),
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

    widget.profileBloc.add(
      UpdateAddHobbiesInterestEvent(
        '',
        widget.profileBloc.interestList!.isEmpty ? '' : widget.profileBloc.interestList?[0].interestDetails ?? "",
        widget.profileBloc.interestList!.length >= 2 ? widget.profileBloc.interestList![1].interestDetails ?? "" : '',
        widget.profileBloc.interestList!.length >= 3 ? widget.profileBloc.interestList![3].interestDetails ?? "" : '',
        '',
        '',
        '',
      ),
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(translation(context).msg_interests_updated),
        backgroundColor: OneUITheme.of(context).success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
