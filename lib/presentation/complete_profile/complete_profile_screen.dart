import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/one_ui_form_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/utils/app_comman_data.dart';
import '../home_screen/fragments/profile_screen/bloc/profile_event.dart';
import '../home_screen/fragments/profile_screen/bloc/profile_state.dart';
import '../sign_up_screen/bloc/sign_up_bloc.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DropdownBloc dropdownBloc = DropdownBloc();
  ProfileBloc profileBloc = ProfileBloc();

  @override
  void initState() {
    dropdownBloc.add(LoadDropdownValues());
    profileBloc.add(UpdateFirstDropdownValue(''));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: SizedBox(
            width: 100.w,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: theme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Image.asset(
                          'assets/images/ic_complete_profile.png',
                          width: 300,
                          height: 100,
                        ),
                        Text(
                          translation(context).lbl_complete_your_profile,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          translation(context).msg_unlock_personalized_features,
                          overflow: TextOverflow.visible,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: BlocBuilder<ProfileBloc, ProfileState>(
                          bloc: profileBloc,
                          builder: (context, state) {
                            if (state is PaginationLoadedState) {
                              // Sync bloc fields from state when data loads
                              _syncBlocFieldsFromState(state);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  OneUIFormDropdown<Countries>(
                                    label: translation(context).lbl_country,
                                    items: state.firstDropdownValues,
                                    value: state.firstDropdownValues.isNotEmpty
                                        ? state.firstDropdownValues.firstWhere(
                                            (country) =>
                                                country.countryName ==
                                                state.selectedFirstDropdownValue,
                                            orElse: () =>
                                                state.firstDropdownValues.first,
                                          )
                                        : null,
                                    itemLabel: (item) =>
                                        item.countryName ?? '',
                                    itemTrailing: (item) =>
                                        Text(item.flag ?? ''),
                                    onChanged: (newValue) {
                                      profileBloc.country =
                                          newValue?.countryName ?? '';
                                      profileBloc.add(
                                        UpdateSecondDropdownValues(
                                          newValue?.countryName ?? '',
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  OneUIFormDropdown<String>(
                                    label: translation(context).lbl_state,
                                    items: state.secondDropdownValues,
                                    value: state.selectedSecondDropdownValue,
                                    itemLabel: (item) => item,
                                    hint: translation(context)
                                        .msg_please_select_state,
                                    onChanged: (String? newValue) {
                                      profileBloc.stateName = newValue!;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  if (AppData.userType == 'doctor')
                                    OneUIFormDropdown<String>(
                                      label:
                                          translation(context).lbl_specialty,
                                      items: state.specialtyDropdownValue,
                                      value: state
                                          .selectedSpecialtyDropdownValue,
                                      itemLabel: (item) => item,
                                      hint: translation(context)
                                          .msg_please_select_specialty,
                                      onChanged: (String? newValue) {
                                        profileBloc.specialtyName =
                                            newValue!;
                                      },
                                    ),
                                  const SizedBox(height: 10),
                                ],
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: CircularProgressIndicator(
                                        color: theme.primary,
                                      ),
                                    ),
                                    Text(
                                      translation(context)
                                          .msg_wait_fields_loading,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: theme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  BlocListener<DropdownBloc, DropdownState>(
                    listener: (context, state) {
                      if (state is DataCompleteLoaded) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              translation(context)
                                  .msg_account_update_success,
                            ),
                          ),
                        );
                        AppNavigator.toDashboard(context);
                      } else if (state is DropdownError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              translation(context)
                                  .msg_something_went_wrong,
                            ),
                          ),
                        );
                      }
                    },
                    bloc: dropdownBloc,
                    child: _buildCompleteProfile(context),
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Sync profileBloc fields from the current PaginationLoadedState
  /// so the Save button always sends the currently displayed values.
  void _syncBlocFieldsFromState(PaginationLoadedState state) {
    if (profileBloc.country == null || profileBloc.country!.isEmpty) {
      profileBloc.country = state.selectedFirstDropdownValue;
    }
    if (profileBloc.stateName == null || profileBloc.stateName!.isEmpty) {
      final sel = state.selectedSecondDropdownValue;
      if (sel.isNotEmpty &&
          sel != 'Select State' &&
          state.secondDropdownValues.contains(sel)) {
        profileBloc.stateName = sel;
      }
    }
    if (profileBloc.specialtyName == null ||
        profileBloc.specialtyName!.isEmpty) {
      final sel = state.selectedSpecialtyDropdownValue;
      if (sel.isNotEmpty &&
          sel != 'Select Specialty' &&
          state.specialtyDropdownValue.contains(sel)) {
        profileBloc.specialtyName = sel;
      }
    }
  }

  Widget _buildCompleteProfile(BuildContext context) {
    return svAppButton(
      context: context,
      text: translation(context).lbl_save,
      onTap: () async {
        onTapComplete(context);
      },
    );
  }

  void onTapComplete(BuildContext context) async {
    if (profileBloc.country == null || profileBloc.country!.isEmpty) {
      toast(
        translation(context).msg_please_select_country,
        bgColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    if (profileBloc.stateName == null ||
        profileBloc.stateName!.isEmpty ||
        profileBloc.stateName == 'Select State') {
      toast(
        translation(context).msg_please_select_state,
        bgColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    if (AppData.userType == 'doctor' &&
        (profileBloc.specialtyName == null ||
            profileBloc.specialtyName!.isEmpty ||
            profileBloc.specialtyName == 'Select Specialty')) {
      toast(
        translation(context).msg_please_select_specialty,
        bgColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    dropdownBloc.add(
      CompleteButtonPressed(
        country: profileBloc.country ?? '',
        state: profileBloc.stateName ?? '',
        specialty: profileBloc.specialtyName ?? '',
      ),
    );
  }
}
