import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_date_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/text_view_widget.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

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
        title: Text('Professional Experience', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child:  Icon(Icons.arrow_back_ios,color: svGetBodyColor())),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: [
          if (widget.profileBloc.isMe)  Padding(
            padding: const EdgeInsets.all(8.0),
            child: MaterialButton(
              textColor: Colors.black,
              onPressed: () {
                setState(() {
                  isEditModeMap = !isEditModeMap;
                });
              },
              elevation: 6,
              color: Colors.white,
              minWidth: 20,
              shape: RoundedRectangleBorder(
                borderRadius: radius(200),
                side: const BorderSide(color: Colors.blue),
              ),
              animationDuration: const Duration(milliseconds: 300),
              focusColor: SVAppColorPrimary,
              hoverColor: SVAppColorPrimary,
              splashColor: SVAppColorPrimary,
              // padding: const EdgeInsets.all(4),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    AddEditWorkScreen(profileBloc:widget.profileBloc).launch(context);
                    isEditModeMap = !isEditModeMap;
                  });
                },
                child:  const Icon(
                  Icons.add_circle_outline_sharp,
                  color: Colors.blue,
                  size: 25,
                  // color: Colors.black,
                  // imagePath: 'assets/icon/ic_vector.svg',
                  // height: 25.adaptSize,
                  // width: 25.adaptSize,
                  // margin: EdgeInsets.only(top: 4.v, right: 4.v),
                ),
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
            // universityList =widget.profileBloc.workEducationList!
            //     .where((work) => work.workType == 'university')
            //     .toList();
            // highSchool =widget.profileBloc.workEducationList!
            //     .where((work) => work.workType == 'high_school')
            //     .toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                   if(workList.isNotEmpty) _buildWorkInfoFields(workList,'work'),
                    if(universityList.isNotEmpty) _buildWorkInfoFields(universityList,'university'),
                    if(highSchool.isNotEmpty)_buildWorkInfoFields(highSchool,'high_school'),
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
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          capitalizeWords(type),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: list.map(
                (entry) => Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      if(type=='work') TextViewWidget(
                          icon: Icons.work,
                          label: 'Speciality/Area of practice',
                          value: entry.name ?? '',
                        ),
                        Divider(color: Colors.grey,),
                        if(type=='work')  TextViewWidget(
                          icon: Icons.type_specimen,
                          label: 'Position/Role',
                          value: entry.position ?? "",
                        ),
                        Divider(color: Colors.grey,),
                        TextViewWidget(
                          icon: Icons.local_hospital,
                          label: 'Hospital/Clinic Name',
                          value: entry.address ?? "",
                        ),
                        Divider(color: Colors.grey,),
                        if(type!='work') TextViewWidget(
                          icon: Icons.description,
                          label: 'Degree',
                          value: entry.degree ?? "",
                        ),
                        if(type!='work')  TextViewWidget(
                          icon: Icons.book,
                          label: 'Courses',
                        ),

                        // TextViewWidget(
                        //   icon: Icons.book,
                        //   label: 'Work Type',
                        //   value: entry.workType ?? "",
                        // ),
                        TextViewWidget(
                            icon: Icons.location_city ,
                            label: 'Location',
                            value: entry.description ?? "",),
                        Divider(color: Colors.grey,),

                        TextViewWidget(
                          label: 'Start Date',
                          value: entry.startDate ?? '',
                        ),
                        Divider(color: Colors.grey,),

                        TextViewWidget(
                          label: 'End Date',
                          value: entry.endDate ?? '',
                        ),
                        const SizedBox(height: 10),
                        // Row(
                        //   // mainAxisAlignment: MainAxisAlignment.spaceAround,
                        //   children: [
                        //     Expanded(
                        //       child: svAppButton(
                        //         color: Colors.grey,
                        //         context: context,
                        //         // style: svAppButton(text: text, onTap: onTap, context: context),
                        //         onTap: () async {
                        //
                        //            widget.profileBloc.add(DeleteWorkEducationEvent(entry.id.toString()));
                        //         },
                        //         text: 'Remove',
                        //       ),
                        //     ),
                        //     const SizedBox(width: 10,),
                        //     Expanded(
                        //       child: svAppButton(
                        //         context: context,
                        //         // style: svAppButton(text: text, onTap: onTap, context: context),
                        //         onTap: () async {
                        //           AddEditWorkScreen(profileBloc: widget.profileBloc,updateWork:entry).launch(context);
                        //         },
                        //         text: 'Update',
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                                onPressed: (){
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return CustomAlertDialog(
                                            title: 'Are you sure want to delete Info ?',
                                            callback: () {
                                              widget.profileBloc.add(DeleteWorkEducationEvent(entry.id.toString()));

                                              Navigator.of(context).pop();
                                            });
                                      });

                                },
                                icon:const Icon(CupertinoIcons.delete,color:Colors.red)),
                            IconButton(
                                onPressed: (){
                                            AddEditWorkScreen(profileBloc: widget.profileBloc,updateWork:entry).launch(context);

                                },
                                icon:const Icon(CupertinoIcons.pencil_circle,color:Colors.blue)),
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
