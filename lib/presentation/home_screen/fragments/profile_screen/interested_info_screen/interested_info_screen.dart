import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_date_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../core/app_export.dart';
import '../../../../../data/models/profile_model/interest_model.dart';
import '../../../utils/SVCommon.dart';
import '../bloc/profile_state.dart';
import 'add_edit_interested_screen.dart';

class InterestedInfoScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  InterestedInfoScreen({required this.profileBloc, super.key});

  @override
  State<InterestedInfoScreen> createState() => _InterestedInfoScreenState();
}
bool isEditModeMap = false;

class _InterestedInfoScreenState extends State<InterestedInfoScreen> {
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
        title: Text('Interest Information', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios)),
        iconTheme: IconThemeData(color: context.iconColor),
        actions:  [
          if (widget.profileBloc.isMe)   GestureDetector(
            onTap: () {
              setState(() {
                AddEditInterestedScreen(profileBloc:widget.profileBloc).launch(context);
                // widget.profileBloc.interestList!.add(InterestModel());
              });
            },
            child: Padding(
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
              _buildInterestedInfoFields(),
              10.height,
              if(isEditModeMap)svAppButton(
                context: context,
                // style: svAppButton(text: text, onTap: onTap, context: context),
                onTap: () async {

                },
                text: 'Update',
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildInterestedInfoFields() {
    return widget.profileBloc.workEducationList!.isEmpty?
    const SizedBox(
        height: 500,
        child: Center(child:Text('No Interest Add'))): Column(
      children: widget.profileBloc.interestList!
          .map(
            (entry) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interest',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextFieldEditWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.description,
                  index: 2,
                  label: 'Interest Type',
                  value: entry.interestType ?? '',
                  onSave: (value) => entry.interestType = value,
                ),
                TextFieldEditWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.description,
                  index: 2,
                  label: 'Interest Details',
                  value: entry.interestDetails ?? "",
                  onSave: (value) => entry.interestDetails = value,
                ),
                const SizedBox(height: 10),
                _buildElevatedButton(
                  onPressed: () {
                    setState(() {
                      widget.profileBloc.interestList!.remove(entry);
                    });
                  },
                  label: 'Remove Interest Info',
                ),
              ],
            ),
          ),
        ),
      ).toList(),
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

