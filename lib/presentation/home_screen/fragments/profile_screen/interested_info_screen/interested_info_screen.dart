import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/widgets/custom_image_view.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/SVColors.dart';
import '../../../utils/SVCommon.dart';

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
    isEditModeMap = false;
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
            child: Icon(Icons.arrow_back_ios, color: svGetBodyColor(),size: 17,)),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: [
          if (widget.profileBloc.isMe)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MaterialButton(
                textColor: Colors.black,
                onPressed: () {
                  setState(() {
                    isEditModeMap = !isEditModeMap;
                  });
                },
                elevation: 0,
                color: Colors.white,
                minWidth: 40,
                // shape: RoundedRectangleBorder(
                //   borderRadius: radius(100),
                //   side: const BorderSide(color: Colors.blue),
                // ),
                animationDuration: const Duration(milliseconds: 300),
                focusColor: SVAppColorPrimary,
                hoverColor: SVAppColorPrimary,
                splashColor: SVAppColorPrimary,
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomImageView(
                      onTap: () {
                        setState(() {
                          isEditModeMap = !isEditModeMap;
                        });
                      },
                      color: Colors.black,
                      imagePath: 'assets/icon/ic_vector.svg',
                      height: 15,
                      width: 15,
                      // margin: const EdgeInsets.only(bottom: 4),
                    ),
                    // Text(
                    //   "Edit",
                    //   style:  TextStyle(fontFamily: 'Poppins',
                    //     fontSize: 10,
                    //     fontWeight: FontWeight.w400,
                    //     color: Colors.blue,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),

          // GestureDetector(
          //   onTap: () {
          //     setState(() {
          //       isEditModeMap = true;
          //       // AddEditInterestedScreen(profileBloc: widget.profileBloc)
          //       //     .launch(context);
          //       // widget.profileBloc.interestList!.add(InterestModel());
          //     });
          //   },
          //   child: const Padding(
          //     padding: EdgeInsets.all(8.0),
          //     child: Icon(
          //       Icons.add_circle_outline_sharp,
          //       color: Colors.blue,
          //       size: 30,
          //       // color: Colors.black,
          //       // imagePath: 'assets/icon/ic_vector.svg',
          //       // height: 25.adaptSize,
          //       // width: 25.adaptSize,
          //       // margin: EdgeInsets.only(top: 4.v, right: 4.v),
          //     ),
          //   ),
          // ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildInterestedInfoFields(),
              10.height,
              if (isEditModeMap)
                svAppButton(
                  context: context,
                  // style: svAppButton(text: text, onTap: onTap, context: context),
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                    }

                    widget.profileBloc.add(UpdateAddHobbiesInterestEvent(
                        '',
                        widget.profileBloc.interestList!.isEmpty
                            ? ''
                            : widget.profileBloc.interestList?[0]
                                    .interestDetails ??
                                "",
                        widget.profileBloc.interestList!.length >= 2
                            ? widget.profileBloc.interestList![1]
                                    .interestDetails ??
                                ""
                            : '',
                        widget.profileBloc.interestList!.length >= 3
                            ? widget.profileBloc.interestList![3]
                                    .interestDetails ??
                                ""
                            : '',
                        '',
                        '',
                        ''
                        // widget.profileBloc.interestList!.length>=4?widget.profileBloc.interestList![3].interestDetails??"":'',
                        // widget.profileBloc.interestList!.length>=5?widget.profileBloc.interestList![4].interestDetails??"":'',
                        // widget.profileBloc.interestList!.length>=6?widget.profileBloc.interestList![5].interestDetails??"":'',
                        ));

                    Navigator.pop(context);
                  },
                  text: 'Update',
                ),
            ],
          ),
        ),
      ),
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Widget _buildInterestedInfoFields() {
    return widget.profileBloc.interestList!.isEmpty
        ? const SizedBox(
            height: 500, child: Center(child: Text('No Interest Add')))
        : Form(
            key: _formKey,
            child: Column(children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capitalizeWords(
                            'Areas of Interest (Specific fields of medicine, research interests)'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFieldEditWidget(
                        hints:
                            'Areas of Interest (Specific fields of medicine, research interests)',
                        isEditModeMap: isEditModeMap,
                        icon: Icons.description,
                        index: 2,
                        label: 'Interest Details',
                        value: widget
                                .profileBloc.interestList?[0].interestDetails ??
                            "",
                        onSave: (value) => widget.profileBloc.interestList?[0]
                            .interestDetails = value,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capitalizeWords(
                            'Participation in Conferences and Workshops'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFieldEditWidget(
                        isEditModeMap: isEditModeMap,
                        icon: Icons.description,
                        index: 2,
                        hints: 'Publications (Research papers, articles)',
                        label: 'Interest Details',
                        value: widget
                                .profileBloc.interestList?[1].interestDetails ??
                            "",
                        onSave: (value) => widget.profileBloc.interestList?[1]
                            .interestDetails = value,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Research Projects',
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
                        hints: 'Clinical Trials...',
                        label: 'Interest Details',
                        value: widget
                                .profileBloc.interestList?[3].interestDetails ??
                            "",
                        onSave: (value) => widget.profileBloc.interestList?[3]
                            .interestDetails = value,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              //       Card(
              //         child: Padding(
              //           padding: const EdgeInsets.all(16.0),
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Text(
              // capitalizeWords(widget.profileBloc.interestList?[3].interestType!.replaceAll('_', ' ') ?? ''),
              //                 style: const TextStyle(
              //                   fontSize: 16,
              //                   fontWeight: FontWeight.bold,
              //                 ),
              //               ),
              //               const SizedBox(height: 10),
              //               TextFieldEditWidget(
              //                 isEditModeMap: isEditModeMap,
              //                 icon: Icons.description,
              //                 index: 2,
              //                 label: 'Interest Details',
              //                 value: widget
              //                     .profileBloc.interestList?[3].interestDetails ??
              //                     "",
              //                 onSave: (value) =>
              //                 widget.profileBloc.interestList?[3]
              //                     .interestDetails = value,
              //               ),
              //               const SizedBox(height: 10),
              //             ],
              //           ),
              //         ),
              //       ),
              //       Card(
              //         child: Padding(
              //           padding: const EdgeInsets.all(16.0),
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Text(
              // capitalizeWords( widget.profileBloc.interestList?[4].interestType!.replaceAll('_', ' ') ?? ''),
              //                 style: const TextStyle(
              //                   fontSize: 16,
              //                   fontWeight: FontWeight.bold,
              //                 ),
              //               ),
              //               const SizedBox(height: 10),
              //               TextFieldEditWidget(
              //                 isEditModeMap: isEditModeMap,
              //                 icon: Icons.description,
              //                 index: 2,
              //                 label: 'Interest Details',
              //                 value: widget
              //                     .profileBloc.interestList?[4].interestDetails ??
              //                     "",
              //                 onSave: (value) =>
              //                 widget.profileBloc.interestList?[4]
              //                     .interestDetails = value,
              //               ),
              //               const SizedBox(height: 10),
              //             ],
              //           ),
              //         ),
              //       ),
              //       Card(
              //         child: Padding(
              //           padding: const EdgeInsets.all(16.0),
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Text(
              //                 capitalizeWords(widget.profileBloc.interestList?[5].interestType!.replaceAll('_', ' ') ?? ''),
              //                 style: const TextStyle(
              //                   fontSize: 16,
              //                   fontWeight: FontWeight.bold,
              //                 ),
              //               ),
              //               const SizedBox(height: 10),
              //               TextFieldEditWidget(
              //                 isEditModeMap: isEditModeMap,
              //                 icon: Icons.description,
              //                 index: 2,
              //                 label: 'Interest Details',
              //                 value: widget
              //                     .profileBloc.interestList?[5].interestDetails ??
              //                     "",
              //                 onSave: (value) =>
              //                 widget.profileBloc.interestList?[5]
              //                     .interestDetails = value,
              //               ),
              //               const SizedBox(height: 10),
              //             ],
              //           ),
              //         ),
              //       ),
            ]));
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
