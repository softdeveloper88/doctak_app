import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_date_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/SVCommon.dart';
import 'add_edit_work_screen.dart';

class WorkInfoScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  WorkInfoScreen({required this.profileBloc, super.key});

  @override
  State<WorkInfoScreen> createState() => _WorkInfoScreenState();
}

bool isEditModeMap = false;

class _WorkInfoScreenState extends State<WorkInfoScreen> {
  @override
  void initState() {
    isEditModeMap=false;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        surfaceTintColor: svGetScaffoldColor(),
        title: Text('Work Information', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios)),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: [
          if (widget.profileBloc.isMe)   GestureDetector(
            onTap: () {
              setState(() {
                AddEditWorkScreen(profileBloc:widget.profileBloc).launch(context);
                isEditModeMap = !isEditModeMap;
              });
            },
            child:  Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.add_circle_outline_sharp,
                color: svGetBodyColor(),
                size: 30,
                // color: Colors.black,
                // imagePath: 'assets/icon/ic_vector.svg',
                // height: 25.adaptSize,
                // width: 25.adaptSize,
                // margin: EdgeInsets.only(top: 4.v, right: 4.v),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWorkInfoFields(),
              10.height,
              if (isEditModeMap)
                svAppButton(
                  context: context,
                  // style: svAppButton(text: text, onTap: onTap, context: context),
                  onTap: () async {},
                  text: 'Update',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkInfoFields() {
    return widget.profileBloc.workEducationList!.isEmpty?
    const SizedBox(
        height: 500,
        child: Center(child:Text('No Work Add'))): Column(
      children: widget.profileBloc.workEducationList!
          .map(
            (entry) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Work Experience ${1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFieldEditWidget(
                      isEditModeMap: isEditModeMap,
                      icon: Icons.work,
                      index: 2,
                      label: 'Company Name',
                      value: entry.name ?? '',
                      onSave: (value) => entry.name = value,
                    ),
                    TextFieldEditWidget(
                      isEditModeMap: isEditModeMap,
                      icon: Icons.type_specimen,
                      index: 2,
                      label: 'Position',
                      value: entry.position ?? "",
                      onSave: (value) => entry.position = value,
                    ),
                    TextFieldEditWidget(
                      isEditModeMap: isEditModeMap,
                      icon: Icons.location_on,
                      index: 2,
                      label: 'Address',
                      value: entry.address ?? "",
                      onSave: (value) => entry.address = value,
                    ),
                    TextFieldEditWidget(
                      isEditModeMap: isEditModeMap,
                      icon: Icons.description,
                      index: 2,
                      label: 'Degree',
                      value: entry.degree ?? "",
                      onSave: (value) => entry.degree = value,
                    ),
                    TextFieldEditWidget(
                      isEditModeMap: isEditModeMap,
                      icon: Icons.book,
                      index: 2,
                      label: 'Courses',
                      value: entry.courses ?? "",
                      onSave: (value) => entry.courses = value,
                    ),
                    TextFieldEditWidget(
                      isEditModeMap: isEditModeMap,
                      icon: Icons.book,
                      index: 2,
                      label: 'Work Type',
                      value: entry.workType ?? "",
                      onSave: (value) => entry.workType = value,
                    ),
                    TextFieldEditWidget(
                        isEditModeMap: isEditModeMap,
                        icon: Icons.description,
                        index: 2,
                        label: 'Description',
                        value: entry.description ?? "",
                        onSave: (value) => entry.description = value,
                        maxLines: 3),
                    ProfileDateWidget(
                      isEditModeMap: isEditModeMap,
                      index: 2,
                      label: 'Start Date',
                      value: entry.startDate ?? '',
                      onSave: (value) => entry.startDate = value,
                    ),
                    ProfileDateWidget(
                      isEditModeMap: isEditModeMap,
                      index: 2,
                      label: 'End Date',
                      value: entry.endDate ?? '',
                      onSave: (value) => entry.endDate = value,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: svAppButton(
                            color: Colors.grey,
                            context: context,
                            // style: svAppButton(text: text, onTap: onTap, context: context),
                            onTap: () async {},
                            text: 'Remove',
                          ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: svAppButton(

                            context: context,
                            // style: svAppButton(text: text, onTap: onTap, context: context),
                            onTap: () async {},
                            text: 'Add',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
