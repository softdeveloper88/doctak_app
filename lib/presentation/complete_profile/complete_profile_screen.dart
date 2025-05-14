import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/common_navigator.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/utils/app_comman_data.dart';
import '../home_screen/SVDashboardScreen.dart';
import '../home_screen/fragments/profile_screen/bloc/profile_event.dart';
import '../home_screen/fragments/profile_screen/bloc/profile_state.dart';
import '../home_screen/utils/SVCommon.dart';
import '../sign_up_screen/bloc/sign_up_bloc.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DropdownBloc dropdownBloc = DropdownBloc();
  ProfileBloc profileBloc = ProfileBloc();
  bool _isChecked = false;

  @override
  void initState() {
    dropdownBloc.add(LoadDropdownValues());
    profileBloc.add(UpdateFirstDropdownValue(''));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      resizeToAvoidBottomInset: false,
      body: SizedBox(
        width: 100.w,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // App Bar Content Moved Here
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios),
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translation(context).msg_unlock_personalized_features,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
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
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                translation(context).lbl_country,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              CustomDropdownButtonFormField(
                                items: state.firstDropdownValues,
                                value: state.firstDropdownValues.first,
                                width: double.infinity,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                itemBuilder: (item) => Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.countryName ?? '',
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    Text(
                                      item.flag ?? '',
                                    ),
                                  ],
                                ),
                                onChanged: (newValue) {
                                  profileBloc.country =
                                      newValue?.countryName ?? '';
                                  profileBloc.add(UpdateSecondDropdownValues(
                                      newValue?.countryName ?? ''));
                                },
                              ),
                              const SizedBox(height: 10),
                              Text(
                                translation(context).lbl_state,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              CustomDropdownButtonFormField(
                                itemBuilder: (item) => Text(
                                  item ?? '',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                items: state.secondDropdownValues,
                                value: state.selectedSecondDropdownValue,
                                width: double.infinity,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                onChanged: (String? newValue) {
                                  profileBloc.stateName = newValue!;
                                  profileBloc.add(
                                      UpdateSpecialtyDropdownValue(newValue));
                                },
                              ),
                              const SizedBox(height: 10),
                              if (AppData.userType == 'doctor') Text(
                                translation(context).lbl_specialty,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (AppData.userType == 'doctor')
                                CustomDropdownButtonFormField(
                                  itemBuilder: (item) => Text(
                                    item ?? '',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  items: state.specialtyDropdownValue,
                                  value: state.selectedSpecialtyDropdownValue,
                                  width: double.infinity,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 0,
                                  ),
                                  onChanged: (String? newValue) {
                                    profileBloc.specialtyName = newValue!;
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
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                Text(
                                  translation(context).msg_wait_fields_loading,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.blue,
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
                print(state.response);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                      content: Text(translation(context).msg_account_update_success)),);
                  launchScreen(context,
                      const SVDashboardScreen(),
                      isNewTask: true,
                      pageRouteAnimation: PageRouteAnimation
                          .Slide);

            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(
                  content: Text(translation(context).msg_something_went_wrong)),);
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
    );
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
    if (profileBloc.country == '' || profileBloc.country == null) {
      toast(translation(context).msg_please_select_country,
          bgColor: Colors.red, textColor: Colors.white);
      return;
    } else if (profileBloc.stateName == '' || profileBloc.stateName == null) {
      toast(translation(context).msg_please_select_state,
          bgColor: Colors.red, textColor: Colors.white);
      return;
    } else if ((profileBloc.specialtyName == null ||
        profileBloc.specialtyName == '') &&  AppData.userType == 'doctor') {
      toast(translation(context).msg_please_select_specialty,
          bgColor: Colors.red, textColor: Colors.white);
      return;
    } else {
      dropdownBloc.add(
        CompleteButtonPressed(
          country: profileBloc.country ?? '',
          state: profileBloc.stateName ?? "",
          specialty: profileBloc.specialtyName ?? "",
        ),
      );
    }
  }
}
