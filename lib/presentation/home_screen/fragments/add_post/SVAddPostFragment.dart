import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/utils/app/AppData.dart';
import '../../../../main.dart';
import '../../utils/SVColors.dart';
import '../../utils/SVCommon.dart';
import 'bloc/add_post_bloc.dart';
import 'components/SVPostOptionsComponent.dart';
import 'components/SVPostTextComponent.dart';
import 'components/others_feature_component.dart';

class SVAddPostFragment extends StatefulWidget {
  SVAddPostFragment({required this.refresh, Key? key}) : super(key: key);
  Function refresh;

  @override
  State<SVAddPostFragment> createState() => _SVAddPostFragmentState();
}

class _SVAddPostFragmentState extends State<SVAddPostFragment> with WidgetsBindingObserver {
  String image = '';

  List<String> colorListHex = [
    '#FFFFFF', // white
    '#FF0000', // Red
    '#0000FF', // Blue
    '#00FF00', // Green
    '#FFFF00', // Yellow
    '#FFA500', // Orange
    '#800080', // Purple
    '#FFC0CB', // Pink
    '#008080', // Teal
    '#4B0082', // Indigo
    '#A52A2A', // Brown
  ];
  Random random = Random();
  String currentSetColor = '';
  Color currentColor = Colors.red;

  Color _hexToColor(String hexColorCode) {
    String colorCode = hexColorCode.replaceAll("#", "");
    int intValue = int.parse(colorCode, radix: 16);
    return Color(intValue).withAlpha(0xFF);
  }

  void changeColor() {
    setState(() {
      currentColor = _hexToColor(
        colorListHex[random.nextInt(colorListHex.length)],
      );
      currentSetColor = colorListHex[random.nextInt(colorListHex.length)];
      searchPeopleBloc.backgroundColor = currentSetColor;
    });
  }

  AddPostBloc searchPeopleBloc = AddPostBloc();
  final QuillController _controller = QuillController.basic();

  @override
  void initState() {
    currentColor = SVDividerColor;
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    afterBuildCreated(() {
      setStatusBarColor(context.cardColor);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    setStatusBarColor(
      appStore.isDarkMode ? appBackgroundColorDark : SVAppLayoutBackground,
    );
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('SVAddPost: App lifecycle changed to: $state');
    if (state == AppLifecycleState.resumed) {
      print('SVAddPost: App resumed from background');
      // Force a UI refresh when returning from gallery
      if (mounted) {
        setState(() {
          // This will trigger a rebuild with updated images
          print('SVAddPost: Force refresh - BLoC has ${searchPeopleBloc.imagefiles.length} files');
        });
      }
    }
  }

  bool _validatePost() {
    // Check if there's either text content or media files
    bool hasText = searchPeopleBloc.title.trim().isNotEmpty;
    bool hasMedia = searchPeopleBloc.imagefiles.isNotEmpty;

    return hasText || hasMedia;
  }

  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Please add some content or select media to create a post',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: Colors.orange[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: svGetScaffoldColor(),
      appBar: DoctakAppBar(
        title: translation(context).lbl_new_post,
        titleIcon: Icons.add_circle_outline_rounded,
        toolbarHeight: 56,
        actions: [
          BlocListener<AddPostBloc, AddPostState>(
            bloc: searchPeopleBloc,
            listener: (BuildContext context, AddPostState state) {
              if (state is ResponseLoadedState) {
                print("State: ${state.toString()}");
                Map<String, dynamic> jsonMap = json.decode(state.message);
                if (jsonMap['success'] == true) {
                  searchPeopleBloc.selectedSearchPeopleData.clear();
                  searchPeopleBloc.imagefiles.clear();
                  searchPeopleBloc.title = '';
                  searchPeopleBloc.feeling = '';
                  searchPeopleBloc.backgroundColor = '';
                  showToast(jsonMap['message']);
                  print('Success: ${jsonMap['message']}');
                  widget.refresh();
                  Navigator.of(context).pop('');
                } else {
                  showToast(jsonMap['message']);
                  print('Error: ${jsonMap['message']}');
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed: () {
                  // Validate post content before submitting
                  if (_validatePost()) {
                    searchPeopleBloc.add(AddPostDataEvent());
                  } else {
                    _showValidationError();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  translation(context).lbl_post,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // User Profile Section
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: CachedNetworkImage(
                              imageUrl:
                                  "${AppData.imageUrl}${AppData.profile_pic.validate()}",
                              height: 42,
                              width: 42,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.blue[50],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.blue[400],
                                    strokeWidth: 1.5,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.blue[50],
                                child: Center(
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.blue[400],
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppData.name ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                capitalizeWords(AppData.specialty),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Post Text Input Section
                  SVPostTextComponent(
                    onColorChange: changeColor,
                    colorValue: currentColor,
                    searchPeopleBloc: searchPeopleBloc,
                  ),
                  // Tag Friends Section
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                        child: OtherFeatureComponent(
                          onColorChange: changeColor,
                          colorValue: currentColor,
                          searchPeopleBloc: searchPeopleBloc,
                        ),
                      ),
                    ],
                  ),
                  // Media Options Section
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                    child: SVPostOptionsComponent(searchPeopleBloc),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
