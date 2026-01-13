import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/utils/app/AppData.dart';
import '../../../../main.dart';
import '../../utils/SVColors.dart';
import 'bloc/add_post_bloc.dart';
import 'components/SVPostOptionsComponent.dart';
import 'components/SVPostTextComponent.dart';
import 'components/others_feature_component.dart';

class SVAddPostFragment extends StatefulWidget {
  SVAddPostFragment({required this.refresh, this.addPostBloc, Key? key})
    : super(key: key);
  final Function refresh;
  final AddPostBloc? addPostBloc;

  @override
  State<SVAddPostFragment> createState() => _SVAddPostFragmentState();
}

class _SVAddPostFragmentState extends State<SVAddPostFragment>
    with WidgetsBindingObserver {
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

  late final AddPostBloc searchPeopleBloc;
  late final bool _createdBloc;
  final TextEditingController _postTextController = TextEditingController();

  @override
  void initState() {
    currentColor = SVDividerColor;
    super.initState();
    // Use provided bloc if available to preserve state across navigation
    _createdBloc = widget.addPostBloc == null;
    searchPeopleBloc = widget.addPostBloc ?? AddPostBloc();
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
    _postTextController.dispose();
    // Close the bloc if this widget created it
    if (_createdBloc) {
      searchPeopleBloc.close();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('SVAddPost: App lifecycle changed to: $state');
    if (state == AppLifecycleState.resumed) {
      print('SVAddPost: App resumed from background');
      // Force a UI refresh when returning from gallery
      // Try restoring persisted files explicitly (in case they were cleared from memory)
      try {
        searchPeopleBloc.restorePersistedFiles();
      } catch (e) {
        print('SVAddPost: restorePersistedFiles failed: $e');
      }
      if (mounted) {
        setState(() {
          // This will trigger a rebuild with updated images
          print(
            'SVAddPost: Force refresh - BLoC has ${searchPeopleBloc.imagefiles.length} files',
          );
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
    final theme = OneUITheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Please add some content or select media to create a post',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: theme.warning,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_new_post,
        titleIcon: CupertinoIcons.add_circled,
        toolbarHeight: 56,
        actions: [
          BlocListener<AddPostBloc, AddPostState>(
            bloc: searchPeopleBloc,
            listener: (BuildContext context, AddPostState state) {
              if (state is ResponseLoadedState) {
                print("State: ${state.toString()}");
                print("Response message: ${state.message}");
                try {
                  Map<String, dynamic> jsonMap = json.decode(state.message);

                  // Helper function to extract message from response
                  String extractMessage(
                    dynamic messageData,
                    String defaultMsg,
                  ) {
                    if (messageData == null) return defaultMsg;
                    if (messageData is String) return messageData;
                    if (messageData is List && messageData.isNotEmpty) {
                      return messageData.first.toString();
                    }
                    return defaultMsg;
                  }

                  if (jsonMap['success'] == true) {
                    final message = extractMessage(
                      jsonMap['message'],
                      'Post created successfully!',
                    );
                    showToast(message);
                    print('Success: $message');

                    // Clear data and switch to home tab
                    // Clear BLoC data
                    searchPeopleBloc.selectedSearchPeopleData.clear();
                    searchPeopleBloc.imagefiles.clear();
                    searchPeopleBloc.title = '';
                    searchPeopleBloc.feeling = '';
                    searchPeopleBloc.backgroundColor = '';

                    // Clear text field and reset color
                    _postTextController.clear();
                    if (mounted) {
                      setState(() {
                        currentColor = SVDividerColor;
                        currentSetColor = '';
                      });
                    }

                    // Switch to home tab and refresh feed (no Navigator.pop needed - this is a tab fragment)
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) {
                        widget.refresh();
                      }
                    });
                  } else {
                    final errorMsg = extractMessage(
                      jsonMap['message'],
                      'Failed to create post',
                    );
                    showToast(errorMsg);
                    print('Error: $errorMsg');
                  }
                } catch (e) {
                  print('Error parsing response: $e');
                  showToast('Post created successfully!');

                  // Clear form and switch to home tab
                  _postTextController.clear();
                  if (mounted) {
                    setState(() {
                      currentColor = SVDividerColor;
                      currentSetColor = '';
                    });
                  }

                  // Fallback: assume success, switch to home tab and refresh
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (mounted) {
                      widget.refresh();
                    }
                  });
                }
              } else if (state is DataError) {
                print("Error State: ${state.errorMessage}");
                showToast(state.errorMessage);
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
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  translation(context).lbl_post,
                  style: theme.buttonText,
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.avatarBorder,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primary.withOpacity(
                                  theme.isDark ? 0.2 : 0.1,
                                ),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: CachedNetworkImage(
                              imageUrl:
                                  "${AppData.imageUrl}${AppData.profile_pic.validate()}",
                              height: 48,
                              width: 48,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: theme.avatarBackground,
                                child: Center(
                                  child: CupertinoActivityIndicator(
                                    color: theme.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.avatarBackground,
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.person_fill,
                                    color: theme.avatarText,
                                    size: 22,
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
                                AppData.name,
                                style: theme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                capitalizeWords(AppData.specialty),
                                style: theme.bodySecondary,
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
                    textController: _postTextController,
                    onColorChange: changeColor,
                    colorValue: currentColor,
                    searchPeopleBloc: searchPeopleBloc,
                  ),
                  // Tag Friends Section - Full Width
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: OtherFeatureComponent(
                      onColorChange: changeColor,
                      colorValue: currentColor,
                      searchPeopleBloc: searchPeopleBloc,
                    ),
                  ),
                  // Media Options Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: SVPostOptionsComponent(searchPeopleBloc),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
