import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../../localization/app_localization.dart';
import '../../../utils/SVCommon.dart';

class AddEditInterestedScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  AddEditInterestedScreen({required this.profileBloc, super.key});

  @override
  State<AddEditInterestedScreen> createState() =>
      _AddEditInterestedScreenState();
}

bool isEditModeMap = false;

class _AddEditInterestedScreenState extends State<AddEditInterestedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        elevation: 0,
        toolbarHeight: 70,
        surfaceTintColor: svGetScaffoldColor(),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.blue[600],
              size: 16,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          }
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_rounded,
              color: Colors.blue[600],
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              translation(context).lbl_interest_details,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_circle_outline,
                color: Colors.blue[600],
                size: 14,
              ),
            ),
            onPressed: () {
              setState(() {
                // widget.profileBloc.interestList!.add(InterestModel());
              });
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildInterestedInfoFields(),
              10.height,
            ],
          ),
        ),
      ),
    );
  }

  var focusNode1 = FocusNode();
  var focusNode2 = FocusNode();

  Widget _buildInterestedInfoFields() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            TextFieldEditWidget(
              focusNode: focusNode1,
              isEditModeMap: true,
              icon: Icons.description,
              index: 2,
              label: translation(context).lbl_areas_of_interest,
              // value: entry.interestType ?? '',
              // onSave: (value) => entry.interestType = value,
            ),
            TextFieldEditWidget(
              focusNode: focusNode2,
              isEditModeMap: true,
              icon: Icons.description,
              index: 2,
              label: translation(context).lbl_interest_details,
              // value: entry.interestDetails ?? "",
              // onSave: (value) => entry.interestDetails = value,
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
                    text: translation(context).lbl_delete,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: svAppButton(
                    context: context,
                    // style: svAppButton(text: text, onTap: onTap, context: context),
                    onTap: () async {},
                    text: translation(context).lbl_add,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
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
