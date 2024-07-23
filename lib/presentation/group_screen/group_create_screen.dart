import 'dart:io';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_event.dart';
import 'package:doctak_app/presentation/group_screen/bloc/group_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_dropdown_button_from_field.dart';
import '../home_screen/fragments/profile_screen/component/profile_widget.dart';
import '../home_screen/utils/SVCommon.dart';
import 'bloc/group_bloc.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  int step = 1;
  GroupBloc groupBloc = GroupBloc();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      appBar: AppBar(
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('Create Group Wizard', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon:
                Image.asset('assets/images/search.png', height: 20, width: 20),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StepProgress(step: step),
            if (step == 1) Step1(onNextStep, groupBloc),
            if (step == 2) Step2(onNextStep, onBackStep, groupBloc),
            if (step == 3) Step3(onNextStep, onBackStep, groupBloc),
            if (step == 4) Step4(onNextStep, onBackStep, groupBloc),
          ],
        ),
      ),
    );
  }

  void onNextStep() {
    setState(() {
      if (step < 4) {
        step += 1;
      } else {
        Navigator.pop(context);
      }
    });
  }

  void onBackStep() {
    setState(() {
      if (step <= 4) step -= 1;
    });
  }
}

class StepProgress extends StatelessWidget {
  final int step;

  const StepProgress({Key? key, required this.step}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: context.cardColor,
      child: Column(
        children: [
          // Text(
          //   "Step $step: ${_stepTitles[step - 1]} 1 - 4",
          //   style: GoogleFonts.poppins(color: svGetBodyColor()),
          // ),
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Stack(
          //     children: [
          //
          //       // Row(
          //       //   mainAxisAlignment: MainAxisAlignment.center,
          //       //   children: _buildProgressImages(),
          //       // ),
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //         children: _buildProgressSteps(),
          //       ),
          //     ],
          //   ),
          // ),
          if (step == 1)
            Container(
              margin: const EdgeInsets.only(top: 10),
              color: context.cardColor,
              child: Column(
                children: [
                  Text(
                    "Step 1: Basic Information 1 - 4",
                    style: GoogleFonts.poppins(color: svGetBodyColor()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomImageView(
                            imagePath: 'assets/images/un_fill_line.png',
                            height: 60,
                            width: 90,
                          ),
                          CustomImageView(
                            imagePath: 'assets/images/un_fille_line_2.png',
                            height: 40,
                            width: 160,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/person.png',
                                ),
                              ),
                            ),
                            const Text("Basic Info")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/un_fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/privacy.png',
                                ),
                              ),
                            ),
                            const Text("Privacy")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/un_fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/camera.png',
                                ),
                              ),
                            ),
                            const Text("Image")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/un_fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/check.png',
                                ),
                              ),
                            ),
                            const Text("Finish")
                          ]),
                        ],
                      ),
                    ]),
                  )
                ],
              ),
            )
          else if (step == 2)
            Container(
              margin: const EdgeInsets.only(top: 10),
              color: context.cardColor,
              child: Column(
                children: [
                  Text(
                    "Step 2: Privacy Setting 1 - 4",
                    style: GoogleFonts.poppins(color: svGetBodyColor()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomImageView(
                            imagePath: 'assets/images/fill_line_1.png',
                            height: 60,
                            width: 90,
                          ),
                          CustomImageView(
                            imagePath: 'assets/images/un_fille_line_2.png',
                            height: 40,
                            width: 160,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/person.png',
                                ),
                              ),
                            ),
                            const Text("Basic Info")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/privacy.png',
                                  color: grey,
                                ),
                              ),
                            ),
                            const Text("Privacy")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/un_fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/camera.png',
                                ),
                              ),
                            ),
                            const Text("Image")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/un_fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/check.png',
                                ),
                              ),
                            ),
                            const Text("Finish")
                          ]),
                        ],
                      ),
                    ]),
                  )
                ],
              ),
            )
          else if (step == 3)
            Container(
              margin: const EdgeInsets.only(top: 10),
              color: context.cardColor,
              child: Column(
                children: [
                  Text(
                    "Step 3: Privacy Setting 1 - 4",
                    style: GoogleFonts.poppins(color: svGetBodyColor()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomImageView(
                            imagePath: 'assets/images/fill_line_1.png',
                            height: 60,
                            width: 90,
                          ),
                          CustomImageView(
                            imagePath: 'assets/images/fill_line_2.png',
                            height: 50,
                            width: 80,
                          ),
                          CustomImageView(
                            imagePath: 'assets/images/un_fill_line_3.png',
                            height: 50,
                            width: 100,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/person.png',
                                ),
                              ),
                            ),
                            const Text("Basic Info")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/privacy.png',
                                  color: grey,
                                ),
                              ),
                            ),
                            const Text("Privacy")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/camera.png',
                                  color: grey,
                                ),
                              ),
                            ),
                            const Text("Image")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/un_fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/check.png',
                                ),
                              ),
                            ),
                            const Text("Finish")
                          ]),
                        ],
                      ),
                    ]),
                  )
                ],
              ),
            )
          else if (step == 4)
            Container(
              margin: const EdgeInsets.only(top: 10),
              color: context.cardColor,
              child: Column(
                children: [
                  Text(
                    "Step 3: Privacy Setting 1 - 4",
                    style: GoogleFonts.poppins(color: svGetBodyColor()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomImageView(
                            imagePath: 'assets/images/fill_line_1.png',
                            height: 60,
                            width: 90,
                          ),
                          CustomImageView(
                            imagePath: 'assets/images/fill_line_2.png',
                            height: 50,
                            width: 80,
                          ),
                          CustomImageView(
                            imagePath: 'assets/images/fill_line_3.png',
                            height: 50,
                            width: 100,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/person.png',
                                ),
                              ),
                            ),
                            const Text("Basic Info")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/privacy.png',
                                  color: grey,
                                ),
                              ),
                            ),
                            const Text("Privacy")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/camera.png',
                                  color: grey,
                                ),
                              ),
                            ),
                            const Text("Image")
                          ]),
                          Column(children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/fill_step.png'),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.asset(
                                  'assets/images/check.png',
                                  color: grey,
                                ),
                              ),
                            ),
                            const Text("Finish")
                          ]),
                        ],
                      ),
                    ]),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildProgressImages() {
    return List.generate(3, (index) {
      return CustomImageView(
        imagePath: _getProgressImagePath(index),
        height: 60,
        width: 90,
      );
    });
  }

  String _getProgressImagePath(int index) {
    if (index < step - 1) {
      return 'assets/images/fill_line_1.png';
    } else if (index == step - 1) {
      return 'assets/images/un_fill_line.png';
    } else {
      return 'assets/images/un_fille_line_2.png';
    }
  }

  List<Widget> _buildProgressSteps() {
    return List.generate(4, (index) {
      return Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_getStepImagePath(index)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(_stepIcons[index]),
            ),
          ),
          Text(_stepTitles[index]),
        ],
      );
    });
  }

  String _getStepImagePath(int index) {
    if (index < step) {
      return 'assets/images/fill_step.png';
    } else {
      return 'assets/images/un_fill_step.png';
    }
  }

  static const List<String> _stepTitles = [
    "Basic Info",
    "Privacy",
    "Image",
    "Finish"
  ];

  static const List<String> _stepIcons = [
    'assets/images/person.png',
    'assets/images/privacy.png',
    'assets/images/camera.png',
    'assets/images/check.png'
  ];
}

class Step1 extends StatefulWidget {
  final VoidCallback onNextStep;
  final GroupBloc groupBloc;

  Step1(this.onNextStep, this.groupBloc, {Key? key}) : super(key: key);

  @override
  State<Step1> createState() => _Step1State();
}

class _Step1State extends State<Step1> {
  @override
  void initState() {
    widget.groupBloc.add(UpdateSpecialtyDropdownValue(""));
    super.initState();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      color: context.cardColor,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFieldEditWidget(
              textInputAction: TextInputAction.next,
              isEditModeMap: true,
              icon: Icons.description,
              index: 2,
              label: 'Group Name:',
              value: widget.groupBloc.name,
              // onFieldSubmitted: (value) => widget.groupBloc.name = value,
              onSave: (value) => widget.groupBloc.name = value,
            ),
            BlocBuilder<GroupBloc, GroupState>(
                bloc: widget.groupBloc,
                builder: (context, state) {
                  if (state is PaginationLoadedState) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: widget.groupBloc.selectSpecialtyList
                                  .map((tag) => Chip(
                                        backgroundColor:
                                            Colors.blue.withOpacity(0.3),
                                        label: Text(tag['value']),
                                        deleteIcon: const Icon(
                                          Icons.cancel,
                                          color: Colors.blue,
                                        ),
                                        onDeleted: () {
                                          setState(() {});
                                          widget.groupBloc.selectSpecialtyList
                                              .remove(tag);
                                        },
                                      ))
                                  .toList(),
                            ),
                          ),
                          Text(
                            'Speciality: ',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          CustomDropdownButtonFormField(
                            items: state.specialtyDropdownValue,
                            value: state.selectedSpecialtyDropdownValue,
                            width: double.infinity,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            onChanged: (String? newValue) {
                              print(newValue);
                              setState(() {});
                              widget.groupBloc.selectSpecialtyList
                                  .add({'id': '0', 'value': newValue});
                              // widget.profileBloc.specialtyName = newValue!;
                              // widget.profileBloc
                              //     .add(UpdateSpecialtyDropdownValue(newValue!));
                            },
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container();
                  }
                }),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: widget.groupBloc.tags
                    .map((tag) => Chip(
                          backgroundColor: Colors.blue.withOpacity(0.3),
                          label: Text(tag['value']),
                          deleteIcon: const Icon(
                            Icons.cancel,
                            color: Colors.blue,
                          ),
                          onDeleted: () {
                            setState(() {});
                            widget.groupBloc.tags.remove(tag);
                          },
                        ))
                    .toList(),
              ),
            ),
            TextFieldEditWidget(
              textInputAction: TextInputAction.done,
              isEditModeMap: true,
              icon: Icons.description,
              index: 2,
              label: 'Tags:',
              value: "",
              onFieldSubmitted: (value) => setState(() {
                widget.groupBloc.tags.add({'value': value});
              }),
              onSave: (value) => setState(() {
                widget.groupBloc.tags.add({'value': value});
              }),
            ),
            TextFieldEditWidget(
              isEditModeMap: true,
              icon: Icons.description,
              index: 2,
              label: 'Location:',
              value: "",
              onSave: (value) => widget.groupBloc.location = value,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: widget.groupBloc.interest
                    .map((tag) => Chip(
                          backgroundColor: Colors.blue.withOpacity(0.3),
                          label: Text(tag['value']),
                          deleteIcon: const Icon(
                            Icons.cancel,
                            color: Colors.blue,
                          ),
                          onDeleted: () {
                            setState(() {});
                            widget.groupBloc.interest.remove(tag);
                          },
                        ))
                    .toList(),
              ),
            ),
            TextFieldEditWidget(
              isEditModeMap: true,
              textInputAction: TextInputAction.done,
              icon: Icons.description,
              index: 2,
              label: 'Interest:',
              value: "",
              onFieldSubmitted: (value) => setState(() {
                widget.groupBloc.interest.add({'value': value});
              }),
              onSave: (value) => setState(() {
                widget.groupBloc.interest.add({'value': value});
              }),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: widget.groupBloc.language
                    .map((tag) => Chip(
                          backgroundColor: Colors.blue.withOpacity(0.3),
                          label: Text(tag['value']),
                          deleteIcon: const Icon(
                            Icons.cancel,
                            color: Colors.blue,
                          ),
                          onDeleted: () {
                            setState(() {});
                            widget.groupBloc.language.remove(tag);
                          },
                        ))
                    .toList(),
              ),
            ),
            TextFieldEditWidget(
              isEditModeMap: true,
              icon: Icons.description,
              index: 2,
              label: 'Language:',
              value: '',
              onFieldSubmitted: (value) => setState(() {
                widget.groupBloc.language.add({'value': value});
              }),
              onSave: (value) => setState(() {
                widget.groupBloc.language.add({'value': value});
              }),
            ),
            TextFieldEditWidget(
              isEditModeMap: true,
              icon: Icons.description,
              index: 2,
              maxLines: 3,
              label: 'Description:',
              value: widget.groupBloc.description,
              onSave: (value) => widget.groupBloc.description = value,
            ),
            TextFieldEditWidget(
                textInputType: TextInputType.number,
                isEditModeMap: true,
                icon: Icons.description,
                index: 2,
                label: 'Member Limit*',
                value: widget.groupBloc.memberLimit,
                onSave: (value) => widget.groupBloc.memberLimit = value),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: svAppButton(
                context: context,
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                  }
                  widget.onNextStep();
                },
                text: 'Next',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> listStatus = ['Active', 'Deactivate'];
List<String> listPostStatus = ['On Admin Approval', 'Already Approved'];
List<String> listWhoCanPostStatus = [
  'Open,Every one can post',
  'Members,Only members',
  'Admin'
];
List<String> listAllowSearch = ['Yes', 'No'];
List<String> listVisibility = ['Only me', 'Public', 'Followers'];
List<String> listJointRequest = [
  'Yes,User can Join directly',
  'No,Approval Required'
];

class Step2 extends StatefulWidget {
  final VoidCallback onBackStep;
  final VoidCallback onNextStep;
  final GroupBloc groupBloc;

  const Step2(this.onNextStep, this.onBackStep, this.groupBloc, {Key? key})
      : super(key: key);

  @override
  State<Step2> createState() => _Step2State();
}

class _Step2State extends State<Step2> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // Implement Step 2 content here
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      color: context.cardColor,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // TextFieldEditWidget(
            //   isEditModeMap: true,
            //   icon: Icons.description,
            //   index: 2,
            //   maxLines: 1,
            //   label: 'Add Admin:',
            //   value:  widget.groupBloc.addAdmin,
            //   onSave: (value)=> widget.groupBloc.addAdmin = value,
            // ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Status:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CustomDropdownButtonFormField(
              items: listStatus,
              value: listStatus.first,
              width: double.infinity,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  widget.groupBloc.status = newValue == 'Active' ? '1' : '0';
                });
              },
            ),
            // Padding(
            //   padding: const EdgeInsets.only(top: 8.0),
            //   child: Text(
            //     'Post Permission:',
            //     style: GoogleFonts.poppins(
            //       fontSize: 16,
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            // ),
            // CustomDropdownButtonFormField(
            //   items: listPostStatus,
            //   value: listPostStatus.first,
            //   width: double.infinity,
            //   contentPadding: const EdgeInsets.symmetric(
            //     horizontal: 10,
            //     vertical: 0,
            //   ),
            //   onChanged: (String? newValue) {
            //     setState(() {
            //       widget.groupBloc.postPermission = newValue=='On Admin Approval'?'1':'0';
            //
            //     });
            //   },
            // ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Who can post :',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CustomDropdownButtonFormField(
              items: listWhoCanPostStatus,
              value: listWhoCanPostStatus.first,
              width: double.infinity,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  // a. Open (Open, Every one can post), b. Members (Members, Only members) c. Admin (Admin)
                  if (newValue == 'Open, Every one can post') {
                    widget.groupBloc.postPermission = 'Open';
                  } else if (newValue == 'Members, Only members') {
                    widget.groupBloc.postPermission = 'Members';
                  } else {
                    widget.groupBloc.postPermission = 'Admin';
                  }
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Allow in Search :',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CustomDropdownButtonFormField(
              items: listAllowSearch,
              value: listAllowSearch.first,
              width: double.infinity,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  widget.groupBloc.allowInSearch =
                      newValue == 'Yes' ? '1' : '0';
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Visibility:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CustomDropdownButtonFormField(
              items: listVisibility,
              value: listVisibility.first,
              width: double.infinity,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  widget.groupBloc.visibility = newValue == 'Only me'
                      ? 'only_me'
                      : newValue == 'Public'
                          ? 'public'
                          : 'followers';
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Joined Request:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CustomDropdownButtonFormField(
              items: listJointRequest,
              value: listJointRequest.first,
              width: double.infinity,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  widget.groupBloc.joinRequest =
                      newValue == 'Yes,User can Join directly' ? '1' : '0';
                });
              },
            ),
            TextFieldEditWidget(
              isEditModeMap: true,
              icon: Icons.description,
              index: 2,
              maxLines: 1,
              label: 'Custom Rules:',
              value: widget.groupBloc.customRules,
              onSave: (value) => widget.groupBloc.customRules = value,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 45.w,
                  padding: const EdgeInsets.all(8.0),
                  child: svAppButton(
                    color: Colors.grey,
                    context: context,
                    onTap: widget.onBackStep,
                    text: 'Back',
                  ),
                ),
                Container(
                  width: 45.w,
                  padding: const EdgeInsets.all(8.0),
                  child: svAppButton(
                    context: context,
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                      }
                      widget.onNextStep();
                    },
                    text: 'Next',
                  ),
                ),
                // Add your Step 2 form fields and widgets here
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Step3 extends StatefulWidget {
  final VoidCallback onNextStep;
  final VoidCallback onBackStep;
  final GroupBloc groupBloc;

  const Step3(this.onNextStep, this.onBackStep, this.groupBloc, {Key? key})
      : super(key: key);

  @override
  State<Step3> createState() => _Step3State();
}

class _Step3State extends State<Step3> {
  String? _selectedCoverFile;
  String? _selectedProfileFile;

  void _showFileOptions(bool isProfilePic) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  File? file = await _pickFile(ImageSource.gallery);
                  if (file != null) {
                    print("isProfilePic $isProfilePic");
                    if (isProfilePic) {
                      setState(() {
                        print('profile${file.path}');
                        widget.groupBloc.profilePicture = file.path;
                        _selectedProfileFile = file.path;
                      });
                    } else {
                      setState(() {
                        widget.groupBloc.coverPicture = file.path;
                        print('cover${file.path}');
                        _selectedCoverFile = file.path;
                      });
                    }
                    // widget.profileBoc!.add(UpdateProfilePicEvent(
                    //     filePath: file.path, isProfilePicture: isProfilePic));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () async {
                  Navigator.pop(context);
                  File? file = await _pickFile(ImageSource.camera);
                  if (file != null) {
                    print("isProfilePic $isProfilePic");
                    if (isProfilePic) {
                      setState(() {
                        print('profile${file.path}');
                        widget.groupBloc.profilePicture = file.path;
                        _selectedProfileFile = file.path;
                      });
                    } else {
                      setState(() {
                        widget.groupBloc.coverPicture = file.path;
                        print('cover${file.path}');
                        _selectedCoverFile = file.path;
                      });
                    }
                  }
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.insert_drive_file),
              //   title: const Text('Select a document'),
              //   onTap: () async {
              //     Navigator.pop(context);
              //     File? file = await _pickFile(ImageSource.gallery);
              //     if (file != null) {
              //       setState(() {
              //         _selectedFile = file;
              //       });
              //     }
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }

  Future<File?> _pickFile(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('file sow$_selectedCoverFile');
    // Implement Step 3 content here
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      color: context.cardColor,
      child: Column(
        children: [
          SizedBox(
            height: 60.w,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(_selectedCoverFile ?? '')),
                        fit: BoxFit.cover,
                      ),
                      color: svGetBgColor(),
                      borderRadius: BorderRadius.circular(10)),
                  width: 90.w,
                  height: 35.w,
                  child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GestureDetector(
                          onTap: () async {
                            const permission = Permission.storage;
                            const permission1 = Permission.photos;
                            var status = await permission.status;
                            print(status);
                            if (await permission1.isGranted) {
                              _showFileOptions(false);
                              // _selectFiles(context);
                            } else if (await permission1.isDenied) {
                              final result = await permission1.request();
                              if (status.isGranted) {
                                _showFileOptions(false);
                                // _selectFiles(context);
                                print("isGranted");
                              } else if (result.isGranted) {
                                _showFileOptions(
                                  false,
                                );
                                // _selectFiles(context);
                                print("isGranted");
                              } else if (result.isDenied) {
                                final result = await permission.request();
                                print("isDenied");
                              } else if (result.isPermanentlyDenied) {
                                print("isPermanentlyDenied");
                                // _permissionDialog(context);
                              }
                            } else if (await permission.isPermanentlyDenied) {
                              print("isPermanentlyDenied");
                              // _permissionDialog(context);
                            }
                          },
                          child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                  color: svGetBgColor(),
                                  border: Border.all(color: grey),
                                  borderRadius: BorderRadius.circular(100)),
                              child: const Icon(Icons.camera_alt)),
                        ),
                      )),
                ),
                Positioned(
                  top: 80,
                  left: 20,
                  child: GestureDetector(
                    onTap: () async {
                      const permission = Permission.storage;
                      const permission1 = Permission.photos;
                      var status = await permission.status;
                      print(status);
                      if (await permission1.isGranted) {
                        _showFileOptions(true);
                        // _selectFiles(context);
                      } else if (await permission1.isDenied) {
                        final result = await permission1.request();
                        if (status.isGranted) {
                          _showFileOptions(true);
                          // _selectFiles(context);
                          print("isGranted");
                        } else if (result.isGranted) {
                          _showFileOptions(
                            true,
                          );
                          // _selectFiles(context);
                          print("isGranted");
                        } else if (result.isDenied) {
                          final result = await permission.request();
                          print("isDenied");
                        } else if (result.isPermanentlyDenied) {
                          print("isPermanentlyDenied");
                          // _permissionDialog(context);
                        }
                      } else if (await permission.isPermanentlyDenied) {
                        print("isPermanentlyDenied");
                        // _permissionDialog(context);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(File(_selectedProfileFile ?? '')),
                            fit: BoxFit.cover,
                          ),
                          color: svGetBgColor(),
                          border: Border.all(color: grey),
                          borderRadius: BorderRadius.circular(100)),
                      width: 25.w,
                      height: 25.w,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(Icons.camera_alt),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          CustomImageView(
            imagePath: 'assets/images/upload_image.png',
            width: 50.w,
          ),
          const Text('Upload Logo & Banner Photo'),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 45.w,
              padding: const EdgeInsets.all(8.0),
              child: svAppButton(
                color: Colors.grey,
                context: context,
                onTap: widget.onBackStep,
                text: 'Back',
              ),
            ),
            Container(
              width: 45.w,
              padding: const EdgeInsets.all(8.0),
              child: svAppButton(
                context: context,
                onTap: () {
                  widget.groupBloc.add(UpdateSpecialtyDropdownValue1(''));
                  widget.onNextStep();
                },
                text: 'Next',
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class Step4 extends StatelessWidget {
  final VoidCallback onNextStep;
  final VoidCallback onBackStep;
  final GroupBloc groupBloc;

  const Step4(this.onNextStep, this.onBackStep, this.groupBloc, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implement Step 4 content here
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      color: context.cardColor,
      child: BlocBuilder(
          bloc: groupBloc,
          builder: (context, state) {
            if (state is PaginationLoadedState) {
              return Column(
                children: [
                  Text(
                    'Successfully',
                    style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Image.asset(
                    'assets/images/success.png',
                    height: 30.w,
                    width: 30.w,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Group Created Successfully',
                      style: GoogleFonts.poppins(
                          color: svGetBodyColor(),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Container(
                    width: 90.w,
                    padding: const EdgeInsets.all(8.0),
                    child: svAppButton(
                      color: Colors.blue,
                      context: context,
                      onTap: onNextStep,
                      text: 'Finish',
                    ),
                  ),
                ],
              );
            } else if (state is DataError) {
              return Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Image.asset(
                    'assets/images/error.png',
                    height: 30.w,
                    color: Colors.grey,
                    width: 30.w,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Error !',
                    style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'An Error Occurred While Creating The Group. Please Go To The Basic Info And Provide The Correct Details',
                      style: GoogleFonts.poppins(
                          color: svGetBodyColor(),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Container(
                    width: 90.w,
                    padding: const EdgeInsets.all(8.0),
                    child: svAppButton(
                      color: Colors.grey,
                      context: context,
                      onTap: onBackStep,
                      text: 'Back',
                    ),
                  ),
                ],
              );
            } else {
              return Image.asset(
                'assets/images/success.png',
                color: grey,
              );
            }
          }),
    );
  }
}
