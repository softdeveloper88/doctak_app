import 'dart:io';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/widgets/custom_image_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_dropdown_button_from_field.dart';
import '../home_screen/fragments/profile_screen/component/profile_widget.dart';
import '../home_screen/utils/SVCommon.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  List<String> _tags = [];
  int step = 1;

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
          IconButton(onPressed: () {}, icon: const Icon(CupertinoIcons.search)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StepProgress(step: step),
            if (step == 1) Step1(_tags, onNextStep),
            if (step == 2) Step2(onNextStep, onBackStep),
            if (step == 3) Step3(onNextStep, onBackStep),
            if (step == 4) Step4(onNextStep, onBackStep),
          ],
        ),
      ),
    );
  }

  void onNextStep() {
    setState(() {
      if (step < 4) step += 1;
    });
  }

  void onBackStep() {
    setState(() {
      if (step < 4) step -= 1;
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

class Step1 extends StatelessWidget {
  final List<String> tags;
  final VoidCallback onNextStep;

  const Step1(this.tags, this.onNextStep, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      color: context.cardColor,
      child: Column(
        children: [
          TextFieldEditWidget(
            isEditModeMap: true,
            icon: Icons.description,
            index: 2,
            label: 'Name:',
            value: "",
            onSave: (value) => {},
          ),
          TextFieldEditWidget(
            isEditModeMap: true,
            icon: Icons.description,
            index: 2,
            label: 'Specialty Focus:',
            value: "",
            onSave: (value) => {},
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: tags
                  .map((tag) => Chip(
                        backgroundColor: Colors.blue.withOpacity(0.3),
                        label: Text(tag),
                        deleteIcon: const Icon(
                          Icons.cancel,
                          color: Colors.blue,
                        ),
                        onDeleted: () {
                          tags.remove(tag);
                        },
                      ))
                  .toList(),
            ),
          ),
          TextFieldEditWidget(
            isEditModeMap: true,
            icon: Icons.description,
            index: 2,
            label: 'Tags:',
            value: "",
            onSave: (value) => {
              tags.add(value),
            },
          ),
          TextFieldEditWidget(
            isEditModeMap: true,
            icon: Icons.description,
            index: 2,
            label: 'Location:',
            value: "",
            onSave: (value) => {},
          ),
          TextFieldEditWidget(
            isEditModeMap: true,
            icon: Icons.description,
            index: 2,
            label: 'Interest:',
            value: "",
            onSave: (value) => {},
          ),
          TextFieldEditWidget(
            isEditModeMap: true,
            icon: Icons.description,
            index: 2,
            label: 'Language:',
            value: "",
            onSave: (value) => {},
          ),
          TextFieldEditWidget(
            isEditModeMap: true,
            icon: Icons.description,
            index: 2,
            maxLines: 3,
            label: 'Description:',
            value: "",
            onSave: (value) => {},
          ),
          TextFieldEditWidget(
            textInputType: TextInputType.number,
            isEditModeMap: true,
            icon: Icons.description,
            index: 2,
            label: 'Member Limit*',
            value: "",
            onSave: (value) => {},
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: svAppButton(
              context: context,
              onTap: onNextStep,
              text: 'Next',
            ),
          ),
        ],
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

class Step2 extends StatelessWidget {
  final VoidCallback onBackStep;
  final VoidCallback onNextStep;

  const Step2(this.onNextStep, this.onBackStep, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implement Step 2 content here
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      color: context.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextFieldEditWidget(
            isEditModeMap: true,
            icon: Icons.description,
            index: 2,
            maxLines: 1,
            label: 'Add Admin:',
            value: "",
            onSave: (value) => {},
          ),
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
              print(newValue);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Post Status:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CustomDropdownButtonFormField(
            items: listPostStatus,
            value: listPostStatus.first,
            width: double.infinity,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
            onChanged: (String? newValue) {
              print(newValue);
            },
          ),
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
              print(newValue);
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
              print(newValue);
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
              print(newValue);
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
              print(newValue);
            },
          ),
          TextFieldEditWidget(
            isEditModeMap: true,
            icon: Icons.description,
            index: 2,
            maxLines: 1,
            label: 'Custom Rules:',
            value: "",
            onSave: (value) => {},
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
                  onTap: onBackStep,
                  text: 'Back',
                ),
              ),
              Container(
                width: 45.w,
                padding: const EdgeInsets.all(8.0),
                child: svAppButton(
                  context: context,
                  onTap: onNextStep,
                  text: 'Next',
                ),
              ),
              // Add your Step 2 form fields and widgets here
            ],
          ),
        ],
      ),
    );
  }
}

class Step3 extends StatefulWidget {
  final VoidCallback onNextStep;
  final VoidCallback onBackStep;

  const Step3(this.onNextStep, this.onBackStep, {Key? key}) : super(key: key);

  @override
  State<Step3> createState() => _Step3State();
}

class _Step3State extends State<Step3> {
 String? _selectedCoverFile;
 var _selectedProfileFile;
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
                    setState(() {
                      print('ddd${file.path}');
                      _selectedCoverFile = file.path;
                      // widget.profileBoc!.add(UpdateProfilePicEvent(
                      //     filePath: file.path, isProfilePicture: isProfilePic));
                    });
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
                    setState(() {
                      print('ddd${file.path}');
                      _selectedCoverFile = file.path;

                      // _selectedFile = file;
                      // widget.profileBoc!.add(UpdateProfilePicEvent(
                      //     filePath: file.path, isProfilePicture: isProfilePic));
                    });
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
                image: FileImage(File(_selectedCoverFile??'')),
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
                            _showFileOptions(true);
                            // _selectFiles(context);
                          } else if (await permission1.isDenied) {
                            final result = await permission1.request();
                            if (status.isGranted) {
                              _showFileOptions(true);
                              // _selectFiles(context);
                              print("isGranted");
                            } else if (result.isGranted) {
                              _showFileOptions(true,);
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
                    onTap: () {

                    },
                    child: Container(
                      decoration: BoxDecoration(
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
                onTap: widget.onNextStep,
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

  const Step4(this.onNextStep, this.onBackStep, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implement Step 4 content here
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      color: context.cardColor,
      child: Column(
        children: [
          // Add your Step 4 form fields and widgets here
        ],
      ),
    );
  }

}
