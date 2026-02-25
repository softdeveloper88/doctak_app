import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/one_ui_profile_components.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfessionalInfoScreen extends StatefulWidget {
  final ProfileBloc profileBloc;

  const ProfessionalInfoScreen({required this.profileBloc, super.key});

  @override
  State<ProfessionalInfoScreen> createState() => _ProfessionalInfoScreenState();
}

class _ProfessionalInfoScreenState extends State<ProfessionalInfoScreen> with SingleTickerProviderStateMixin {
  bool _isEditMode = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  FocusNode focusNode4 = FocusNode();
  FocusNode focusNode5 = FocusNode();

  @override
  void initState() {
    super.initState();
    _isEditMode = false;
    widget.profileBloc.add(UpdateSpecialtyDropdownValue(''));

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
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
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: 'About Me',
        titleIcon: Icons.info_outline_rounded,
        actions: [
          if (widget.profileBloc.isMe)
            OneUIEditActionButton(
              isEditMode: _isEditMode,
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        bloc: widget.profileBloc,
        listener: (context, state) {
          if (_isSaving && (state is PaginationLoadedState || state is FullProfileLoadedState)) {
            setState(() {
              _isSaving = false;
            });
          }
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
                child: Column(
                  children: [
                    // Information banner
                    if (!_isEditMode)
                      OneUIInfoBanner(
                        message: 'Update your about me information, address, and personal details.',
                        icon: Icons.info_outline,
                        accentColor: theme.primary,
                      ),

                    // About Me section
                    OneUIProfileSection(
                      title: 'About Me',
                      icon: Icons.description_outlined,
                      iconColor: Colors.blue[700],
                      child: TextFieldEditWidget(
                        isEditModeMap: _isEditMode,
                        icon: Icons.person_outline,
                        index: 1,
                        textInputAction: TextInputAction.newline,
                        textInputType: TextInputType.multiline,
                        focusNode: focusNode1,
                        hints: 'Tell others about yourself...',
                        label: 'About Me',
                        value: widget.profileBloc.userProfile?.profile?.aboutMe ?? '',
                        onSave: (value) => widget.profileBloc.userProfile?.profile?.aboutMe = value,
                        maxLines: 4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Specialty section (doctors only)
                    if (AppData.userType == "doctor")
                      OneUIProfileSection(
                        title: 'Specialty',
                        icon: Icons.medical_services_outlined,
                        iconColor: Colors.purple[700],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isEditMode)
                              BlocBuilder<ProfileBloc, ProfileState>(
                                bloc: widget.profileBloc,
                                builder: (context, state) {
                                  List<String> specialties = [];
                                  String selectedSpecialty = '';
                                  bool isLoaded = false;

                                  if (state is PaginationLoadedState) {
                                    specialties = state.specialtyDropdownValue;
                                    selectedSpecialty = state.selectedSpecialtyDropdownValue;
                                    isLoaded = true;
                                  } else if (state is FullProfileLoadedState) {
                                    specialties = state.specialtyDropdownValue;
                                    selectedSpecialty = state.selectedSpecialtyDropdownValue;
                                    isLoaded = true;
                                  }

                                  if (isLoaded) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: theme.border),
                                      ),
                                      child: CustomDropdownButtonFormField(
                                        itemBuilder: (item) => Text(item, style: TextStyle(color: theme.textPrimary)),
                                        items: specialties,
                                        value: selectedSpecialty,
                                        width: double.infinity,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        onChanged: (String? newValue) {
                                          widget.profileBloc.specialtyName = newValue!;
                                          widget.profileBloc.userProfile?.user?.specialty = newValue;
                                          widget.profileBloc.add(UpdateSpecialtyDropdownValue(newValue));
                                        },
                                      ),
                                    );
                                  } else {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                },
                              ),

                            if (!_isEditMode)
                              TextFieldEditWidget(
                                index: 0,
                                label: 'Specialty',
                                value: widget.profileBloc.userProfile?.user?.specialty ?? '',
                                onSave: (value) => widget.profileBloc.userProfile?.user?.specialty = value,
                              ),
                          ],
                        ),
                      ),

                    if (AppData.userType == "doctor") const SizedBox(height: 8),

                    // Address & Location section
                    OneUIProfileSection(
                      title: 'Location & Contact',
                      icon: Icons.location_on_outlined,
                      iconColor: Colors.orange[700],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Address
                          TextFieldEditWidget(
                            isEditModeMap: _isEditMode,
                            icon: Icons.home_outlined,
                            index: 1,
                            textInputAction: TextInputAction.next,
                            textInputType: TextInputType.text,
                            focusNode: focusNode2,
                            hints: 'Your address',
                            label: 'Address',
                            value: widget.profileBloc.userProfile?.profile?.address ?? '',
                            onSave: (value) => widget.profileBloc.userProfile?.profile?.address = value,
                          ),

                          if (!_isEditMode) Divider(color: theme.border, thickness: 1, indent: 10, endIndent: 10),

                          // Lives In
                          TextFieldEditWidget(
                            isEditModeMap: _isEditMode,
                            icon: Icons.apartment_outlined,
                            index: 1,
                            textInputAction: TextInputAction.next,
                            textInputType: TextInputType.text,
                            focusNode: focusNode3,
                            hints: 'City or place where you live',
                            label: 'Lives In',
                            value: widget.profileBloc.userProfile?.profile?.livesIn ?? '',
                            onSave: (value) => widget.profileBloc.userProfile?.profile?.livesIn = value,
                          ),

                          if (!_isEditMode) Divider(color: theme.border, thickness: 1, indent: 10, endIndent: 10),

                          // Birthplace
                          TextFieldEditWidget(
                            isEditModeMap: _isEditMode,
                            icon: Icons.place_outlined,
                            index: 1,
                            textInputAction: TextInputAction.next,
                            textInputType: TextInputType.text,
                            focusNode: focusNode4,
                            hints: 'Where you were born',
                            label: 'Birthplace',
                            value: widget.profileBloc.userProfile?.profile?.birthplace ?? '',
                            onSave: (value) => widget.profileBloc.userProfile?.profile?.birthplace = value,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Languages section
                    OneUIProfileSection(
                      title: 'Languages',
                      icon: Icons.language_rounded,
                      iconColor: Colors.green[700],
                      child: TextFieldEditWidget(
                        isEditModeMap: _isEditMode,
                        icon: Icons.translate_rounded,
                        index: 1,
                        textInputAction: TextInputAction.done,
                        textInputType: TextInputType.text,
                        focusNode: focusNode5,
                        hints: 'e.g. English, Arabic, Urdu',
                        label: 'Languages',
                        value: widget.profileBloc.userProfile?.profile?.languages ?? '',
                        onSave: (value) => widget.profileBloc.userProfile?.profile?.languages = value,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Update button
                    if (_isEditMode)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: _isSaving
                            ? const Center(child: CircularProgressIndicator())
                            : OneUIProfilePrimaryButton(
                                label: 'Update',
                                icon: Icons.check_circle,
                                color: theme.primary,
                                onPressed: _saveChanges,
                              ),
                      ),
                  ],
                ),
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

    setState(() {
      _isSaving = true;
      _isEditMode = false;
    });

    widget.profileBloc.add(
      UpdateProfileEvent(
        updateProfileSection: 2,
        userProfile: widget.profileBloc.userProfile,
        interestModel: widget.profileBloc.interestList,
        workEducationModel: widget.profileBloc.workEducationList,
        userProfilePrivacyModel: UserProfilePrivacyModel(),
      ),
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(translation(context).msg_profile_updated),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
