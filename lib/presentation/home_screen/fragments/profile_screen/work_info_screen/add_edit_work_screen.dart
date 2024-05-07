import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/SVCommon.dart';
import '../component/profile_date_widget.dart';

class AddEditWorkScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  AddEditWorkScreen({required this.profileBloc, super.key});

  @override
  State<AddEditWorkScreen> createState() =>
      _AddEditWorkScreenState();
}

bool isEditModeMap = false;

class _AddEditWorkScreenState extends State<AddEditWorkScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        title: Text('Add Work', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios)),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                // widget.profileBloc.interestList!.add(InterestModel());
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.add_circle_outline_sharp,
                color: Colors.black,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkInfoFields() {
    return Column(
      children:[
        Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 10),
                ProfileWidget(
                  isEditModeMap: true,
                  icon: Icons.work,
                  index: 2,
                  label: 'Company Name',
                  // value: entry.name ?? '',
                  // onSave: (value) => entry.name = value,
                ),
                ProfileWidget(
                  isEditModeMap: true,
                  icon: Icons.type_specimen,
                  index: 2,
                  label: 'Position',
                  // value: entry.position ?? "",
                  // onSave: (value) => entry.position = value,
                ),
                ProfileWidget(
                  isEditModeMap: true,
                  icon: Icons.location_on,
                  index: 2,
                  label: 'Address',
                  // value: entry.address ?? "",
                  // onSave: (value) => entry.address = value,
                ),
                ProfileWidget(
                  isEditModeMap: true,
                  icon: Icons.description,
                  index: 2,
                  label: 'Degree',
                  // value: entry.degree ?? "",
                  // onSave: (value) => entry.degree = value,
                ),
                ProfileWidget(
                  isEditModeMap: true,
                  icon: Icons.book,
                  index: 2,
                  label: 'Courses',
                  // value: entry.courses ?? "",
                  // onSave: (value) => entry.courses = value,
                ),
                ProfileWidget(
                  isEditModeMap: true,
                  icon: Icons.book,
                  index: 2,
                  label: 'Work Type',
                  // value: entry.workType ?? "",
                  // onSave: (value) => entry.workType = value,
                ),
                ProfileWidget(
                    isEditModeMap: true,
                    icon: Icons.description,
                    index: 2,
                    label: 'Description',
                    // value: entry.description ?? "",
                    // onSave: (value) => entry.description = value,
                    maxLines: 3),
                ProfileDateWidget(
                  isEditModeMap: true,
                  index: 2,
                  label: 'Start Date',
                  // value: entry.startDate ?? '',
                  // onSave: (value) => entry.startDate = value,
                ),
                ProfileDateWidget(
                  isEditModeMap: true,
                  index: 2,
                  label: 'End Date',
                  // value: entry.endDate ?? '',
                  // onSave: (value) => entry.endDate = value,
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
