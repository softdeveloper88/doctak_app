import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/SVCommon.dart';
import '../component/profile_date_widget.dart';
import '../component/profile_widget.dart';

class AddEditWorkScreen extends StatefulWidget {
  ProfileBloc profileBloc;
  WorkEducationModel? updateWork;
  AddEditWorkScreen({required this.profileBloc, this.updateWork,super.key, });

  @override
  State<AddEditWorkScreen> createState() =>
      _AddEditWorkScreenState();
}
GlobalKey<FormState> _formKey = GlobalKey<FormState>();

bool isEditModeMap = false;
WorkEducationModel? updateWork=WorkEducationModel();

class _AddEditWorkScreenState extends State<AddEditWorkScreen> {

  @override
  void initState() {

    if(widget.updateWork !=null){
      updateWork= widget.updateWork;
      updateWork?.workType=widget.updateWork?.workType??"work";

    }
    else{
      updateWork=WorkEducationModel();
      updateWork?.workType='work';
      widget.profileBloc.add(UpdateSpecialtyDropdownValue(''));

    }
    super.initState();
  }
  String privacy='global';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: svGetScaffoldColor(),

      appBar: AppBar(
        surfaceTintColor: svGetScaffoldColor(),

        backgroundColor: svGetScaffoldColor(),
        title: Text('Add Work', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child:  Icon(Icons.arrow_back_ios,color: svGetBodyColor())),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: const [
          // GestureDetector(
          //   onTap: () {
          //     setState(() {
          //       // profileBloc.interestList!.add(InterestModel());
          //     });
          //   },
            // child: const Padding(
            //   padding: EdgeInsets.all(8.0),
            //   child: Icon(
            //     Icons.add_circle_outline_sharp,
            //     color: Colors.black,
            //     size: 30,
            //     // color: Colors.black,
            //     // imagePath: 'assets/icon/ic_vector.svg',
            //     // height: 25.adaptSize,
            //     // width: 25.adaptSize,
            //     // margin: EdgeInsets.only(top: 4.v, right: 4.v),
            //   ),
            // ),
          // ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWorkInfoFields(),
              10.height,
            ],
          ),
        ),
      ),
    );
  }
  List<String> listWorkType = ['work', 'university','high_school'];
  List<String> privacyList = ['global', 'private','only me'];
  List<String> positionList = ['Resident Physician',
    'Attending Physician',
    'Fellow',
    'Consultant',
    'Surgeon',
    'General Practitioner',
    'Medical Officer',
    'Researcher',
    'Educator/Teacher/Professor'];

  var focusNode1=FocusNode();
  var focusNode2=FocusNode();
  var focusNode3=FocusNode();
  var focusNode4=FocusNode();
  var focusNode5=FocusNode();

  Widget _buildWorkInfoFields() {
    return Column(
      children:[
        Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const SizedBox(height: 10),
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 8.0),
                  //   child: Text(
                  //     'Work Type',
                  //     style: GoogleFonts.poppins(
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  // ),
                  // CustomDropdownButtonFormField(
                  //   items: listWorkType,
                  //   value: listWorkType.first,
                  //   width: double.infinity,
                  //   contentPadding: const EdgeInsets.symmetric(
                  //     horizontal: 10,
                  //     vertical: 0,
                  //   ),
                  //   onChanged: (String? newValue) {
                  //     setState(() {
                  //       updateWork?.workType  = newValue;
                  //     });
                  //   },
                  // ),

                  if(updateWork?.workType=='work')
                    BlocBuilder<ProfileBloc, ProfileState>(
                        bloc: widget.profileBloc,
                        builder: (context, state) {
                          if (state is PaginationLoadedState) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (AppData.userType == "doctor")
                                  const SizedBox(height: 10),
                                if (AppData.userType == "doctor")
                                  Text(
                                    'Speciality/Area of practice',
                                    style: GoogleFonts.poppins(fontSize:16,fontWeight:FontWeight.w500,),
                                  ),
                                if (AppData.userType == "doctor") CustomDropdownButtonFormField(
                                  items: state.specialtyDropdownValue,
                                  value: state.selectedSpecialtyDropdownValue,
                                  width: double.infinity,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 0,
                                  ),
                                  onChanged: (String? newValue) {
                                    print(newValue);
                                    print("Specialty $newValue");
                                    updateWork?.name = newValue;
                                    // widget.profileBloc.specialtyName = newValue!;
                                    // widget.profileBloc.userProfile?.user?.specialty=newValue;
                                    widget.profileBloc.add(
                                        UpdateSpecialtyDropdownValue(
                                            newValue??''));
                                  },
                                ),
                                if (AppData.userType != "doctor")
                                  const SizedBox(height: 10),
                                // if (AppData.userType!="doctor")
                                //   const SizedBox(height: 10),
                                // if (AppData.userType != "doctor" &&
                                //     state.selectedUniversityDropdownValue ==
                                //         'Add new University')
                              ],
                            );
                          } else {
                            return Text('No widget $state');
                          }
                        }),
                  //   TextFieldEditWidget(
                  //   isEditModeMap: true,
                  //   icon: Icons.work,
                  //   index: 2,
                  //   focusNode: focusNode1,
                  //   label: 'Speciality/Area of practice',
                  //   value: updateWork?.name ?? '',
                  //   onSave: (value) => updateWork?.name = value,
                  // ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Position/Role',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  CustomDropdownButtonFormField(
                    items: positionList,
                    value: positionList.first,
                    width: double.infinity,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        updateWork?.position  = newValue;
                      });
                    },
                  ),
                 // if(updateWork?.workType=='work') TextFieldEditWidget(
                 //    isEditModeMap: true,
                 //    icon: Icons.type_specimen,
                 //    index: 2,
                 //    label: 'Position/Role',
                 //    value: updateWork?.position ?? "",
                 //    onSave: (value) => updateWork?.position = value,
                 //  ),
                  TextFieldEditWidget(
                    focusNode: focusNode2,
                    isEditModeMap: true,
                    icon: Icons.location_on,
                    index: 2,
                    hints: 'Enter Hospital/clinic name',
                    label: 'Hospital/Clinic Name',
                    value: updateWork?.address ?? "",
                    onSave: (value) => updateWork?.address = value,
                  ),
                  if(updateWork?.workType!='work') TextFieldEditWidget(
                    focusNode: focusNode3,
                    isEditModeMap: true,
                    icon: Icons.description,
                    index: 2,
                    label: 'Degree',
                    value: updateWork?.degree ?? "",
                    onSave: (value) => updateWork?.degree = value,
                  ),
                  if(updateWork?.workType!='work') TextFieldEditWidget(
                    isEditModeMap: true,
                    focusNode: focusNode4,
                    icon: Icons.book,
                    index: 2,
                    label: 'Courses',
                    value: updateWork?.courses ?? "",
                    onSave: (value) => updateWork?.courses = value,
                  ),
                  TextFieldEditWidget(
                      isEditModeMap: true,
                      icon: Icons.description,
                      focusNode: focusNode5,
                      index: 2,
                      hints: 'Enter location (e.g., KSA, UAE)',
                      label: 'Location',
                      value: updateWork?.description ?? "",
                      onSave: (value) => updateWork?.description = value,
                      maxLines: 3),
                  ProfileDateWidget(
                    isEditModeMap: true,
                    index: 2,
                    label: 'Start Date',
                    value: updateWork?.startDate ?? '',
                    onSave: (value) => updateWork?.startDate = value,
                  ),
                  ProfileDateWidget(
                    isEditModeMap: true,
                    index: 2,
                    label: 'End Date',
                    value: updateWork?.endDate ?? '',
                    onSave: (value) => updateWork?.endDate = value,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Privacy',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  CustomDropdownButtonFormField(
                    items: privacyList,
                    value: privacyList.first,
                    width: double.infinity,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                         privacy = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Expanded(
                      //   child: svAppButton(
                      //     color: Colors.grey,
                      //     context: context,
                      //     // style: svAppButton(text: text, onTap: onTap, context: context),
                      //     onTap: () async {
                      //
                      //     },
                      //     text: 'Remove',
                      //   ),
                      // ),
                      // const SizedBox(width: 10,),
                      Expanded(
                        child: svAppButton(

                          context: context,
                          // style: svAppButton(text: text, onTap: onTap, context: context),
                          onTap: () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                            }
                            var currentStatus=0;
                            if(updateWork?.endDate=='' && updateWork?.endDate==null){
                              currentStatus=1;
                            }else{
                              currentStatus=0;
                            }
                            if(widget.updateWork !=null) {
                              print(updateWork?.id);
                              widget.profileBloc.add(
                                  UpdateAddWorkEductionEvent(
                                      widget.updateWork?.id.toString()??'0',
                                      updateWork?.name ?? "",
                                      updateWork?.position ?? "",
                                      updateWork?.address ?? "",
                                      updateWork?.degree ?? "",
                                      updateWork?.courses ?? "",
                                      updateWork?.workType ?? "",
                                      updateWork?.startDate ?? "",
                                      updateWork?.endDate ?? "",
                                      currentStatus.toString(),
                                      updateWork?.description ?? "",
                                      privacy
                                      )

                              );
                            }else{
                              widget.profileBloc.add(
                                  UpdateAddWorkEductionEvent(
                                      '',
                                      updateWork?.name ?? "",
                                      updateWork?.position ?? "",
                                      updateWork?.address ?? "",
                                      updateWork?.degree ?? "",
                                      updateWork?.courses ?? "",
                                      updateWork?.workType ?? "",
                                      updateWork?.startDate ?? "",
                                      updateWork?.endDate ?? "",
                                      updateWork?.currentStatus ?? "",
                                      updateWork?.description ?? "",
                                      privacy)

                              );
                            }
                           Navigator.pop(context);
                          },
                          text: 'Add',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

    ]
    );
  }


  Widget _buildElevatedButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
