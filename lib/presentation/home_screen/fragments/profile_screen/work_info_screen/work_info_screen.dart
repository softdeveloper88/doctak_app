import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_date_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/text_view_widget.dart';
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
  List<WorkEducationModel> workList = [];
  List<WorkEducationModel> universityList = [];
  List<WorkEducationModel> highSchool = [];

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
      body: BlocConsumer<ProfileBloc,ProfileState>(
        bloc: widget.profileBloc,
        builder: (BuildContext context, ProfileState state) {
          if (state is PaginationLoadedState){
            workList =widget.profileBloc.workEducationList!
                .where((work) => work.workType == 'work')
                .toList();
            universityList =widget.profileBloc.workEducationList!
                .where((work) => work.workType == 'university')
                .toList();
            highSchool =widget.profileBloc.workEducationList!
                .where((work) => work.workType == 'high_school')
                .toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildWorkInfoFields(workList,'work'),
                    _buildWorkInfoFields(universityList,'university'),
                    _buildWorkInfoFields(highSchool,'high_school'),
                    10.height,
                    // if (isEditModeMap)
                    //   svAppButton(
                    //     context: context,
                    //     // style: svAppButton(text: text, onTap: onTap, context: context),
                    //     onTap: () async {},
                    //     text: 'Update',
                    //   ),
                  ],
                ),
              ),
            );
        }else{
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
    },
        listener: (BuildContext context, ProfileState state) {

      },
      ),
    );
  }
  Widget _buildWorkInfoFields(List<WorkEducationModel> list,String type) {
    return list.isEmpty?
     SizedBox(
        height: 500,
        child: Center(child:Text('No $type Add'))):
    Column(
      children: [
        Text(
          type,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: list.map(
                (entry) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      if(type=='work')  TextViewWidget(
                          icon: Icons.work,
                          label: 'Company Name',
                          value: entry.name ?? '',
                        ),
                        if(type=='work')  TextViewWidget(
                          icon: Icons.type_specimen,

                          label: 'Position',
                          value: entry.position ?? "",
                        ),
                        TextViewWidget(
                          icon: Icons.location_on,
                          label: 'Address',
                          value: entry.address ?? "",
                        ),
                        if(type!='work') TextViewWidget(
                          icon: Icons.description,
                          label: 'Degree',
                          value: entry.degree ?? "",
                        ),
                        if(type!='work')  TextViewWidget(
                          icon: Icons.book,
                          label: 'Courses',
                        ),
                        TextViewWidget(
                          icon: Icons.book,
                          label: 'Work Type',
                          value: entry.workType ?? "",
                        ),
                        TextViewWidget(
                            icon: Icons.description,
                            label: 'Description',
                            value: entry.description ?? "",),
                        TextViewWidget(
                          label: 'Start Date',
                          value: entry.startDate ?? '',
                        ),
                        TextViewWidget(
                          label: 'End Date',
                          value: entry.endDate ?? '',
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
                                onTap: () async {

                                   widget.profileBloc.add(DeleteWorkEducationEvent(entry.id.toString()));
                                },
                                text: 'Remove',
                              ),
                            ),
                            const SizedBox(width: 10,),
                            Expanded(
                              child: svAppButton(
                                context: context,
                                // style: svAppButton(text: text, onTap: onTap, context: context),
                                onTap: () async {
                                  AddEditWorkScreen(profileBloc: widget.profileBloc,updateWork:entry).launch(context);
                                },
                                text: 'Update',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ).toList(),
        )
      ]
    );
  }
}
