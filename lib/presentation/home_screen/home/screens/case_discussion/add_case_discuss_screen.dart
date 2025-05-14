import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import 'bloc/case_discussion_bloc.dart';
import 'component/file_upload_widget.dart';

class AddCaseDiscussScreen extends StatefulWidget {
  @override
  _AddCaseDiscussScreenState createState() => _AddCaseDiscussScreenState();
}

class _AddCaseDiscussScreenState extends State<AddCaseDiscussScreen> {
  final _formKey = GlobalKey<FormState>();
  String? title;
  String? description;
  String? keyword;
  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  XFile? _image;
  CaseDiscussionBloc caseDiscussionBloc = CaseDiscussionBloc();

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Process the data here

        _formKey.currentState!.save();

      String imagePath = _image?.path ?? '';

      // Print the collected data
      print('Title: $title');
      print('Description: $description');
      print('Keyword: $keyword');
      print('Image Path: ${caseDiscussionBloc.imagefiles}');
       if(title!.isNotEmpty ||description!.isNotEmpty ||keyword!.isNotEmpty ) {
         caseDiscussionBloc.add(AddCaseDataEvent(title: title ?? '',
             description: description ?? '',
             keyword: keyword ?? ''));

       }
      // You can further process the data or send it to a backend service
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).lbl_add_case),
      ),
      body: BlocListener<CaseDiscussionBloc, CaseDiscussionState>(
    bloc: caseDiscussionBloc,
    listener: (BuildContext context, CaseDiscussionState state) {
    if (state is PaginationLoadedState) {
      caseDiscussionBloc.add(
        CaseDiscussionLoadPageEvent(page: 1, countryId: '', searchTerm: ''),
      );
      Navigator.pop(context);
    // var data = jsonDecode(state.message);
    }},
    child:Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFieldEditWidget(
                focusNode: focusNode1,
                isEditModeMap: true,
                icon: Icons.description,
                index: 2,
                maxLines: 3,
                label: translation(context).lbl_case_title,
                value: title,
                onSave: (value) => {
                  setState(() {
                    title = value;
                  })
                },
              ),
              const SizedBox(height: 4),
              TextFieldEditWidget(
                isEditModeMap: true,
                icon: Icons.description,
                index: 2,
                focusNode: focusNode2,
                maxLines: 5,
                label: translation(context).lbl_case_description,
                value: description,
                onSave: (value) => {
                  setState(() {

                    description = value;
                  })
                },
              ),
              const SizedBox(height: 4),
              TextFieldEditWidget(
                isEditModeMap: true,
                icon: Icons.description,
                index: 2,
                focusNode: focusNode3,
                maxLines: 3,
                label: translation(context).lbl_case_keyword,
                value: keyword,
                onSave: (value) => {
                  setState(() {
                    keyword = value;
                  })
                },
              ),
              const SizedBox(height: 4),
              FileUploadWidget(caseDiscussionBloc),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _submitForm, child: Text(translation(context).lbl_submit),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
