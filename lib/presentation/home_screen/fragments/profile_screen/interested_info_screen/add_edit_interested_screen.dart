import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
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
        surfaceTintColor: svGetScaffoldColor(),
        backgroundColor: svGetScaffoldColor(),
        title: Text('Add Interest', style: boldTextStyle(size: 20)),
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
              _buildInterestedInfoFields(),
              10.height,
            ],
          ),
        ),
      ),
    );
  }
  var focusNode1=FocusNode();
  var focusNode2=FocusNode();

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
              label: 'Interest Type',
              // value: entry.interestType ?? '',
              // onSave: (value) => entry.interestType = value,
            ),
            TextFieldEditWidget(
              focusNode: focusNode2,
              isEditModeMap: true,
              icon: Icons.description,
              index: 2,
              label: 'Interest Details',
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
                    text: 'Remove',
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
                    text: 'Add',
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
