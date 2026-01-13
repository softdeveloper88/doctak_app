import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../bloc/add_post_event.dart';

class SVPostTextComponent extends StatefulWidget {
  final Function? onColorChange;
  final Color? colorValue;
  final AddPostBloc searchPeopleBloc;
  final TextEditingController? textController;

  const SVPostTextComponent({
    this.onColorChange,
    this.colorValue,
    required this.searchPeopleBloc,
    this.textController,
    Key? key,
  }) : super(key: key);

  @override
  State<SVPostTextComponent> createState() => _SVPostTextComponentState();
}

class _SVPostTextComponentState extends State<SVPostTextComponent> {
  late TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    textEditingController = widget.textController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.textController == null) {
      textEditingController.dispose();
    }
    super.dispose();
  }

  Color _getTextColor(Color? backgroundColor, OneUITheme theme) {
    if (backgroundColor == null ||
        backgroundColor == Colors.transparent ||
        backgroundColor == theme.inputBackground) {
      return theme.textPrimary;
    }
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  Color _getHintTextColor(Color? backgroundColor, OneUITheme theme) {
    if (backgroundColor == null ||
        backgroundColor == Colors.transparent ||
        backgroundColor == theme.inputBackground) {
      return theme.textTertiary;
    }
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black38 : Colors.white60;
  }

  final FocusNode editorFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    final bool hasCustomBackground = widget.colorValue != null &&
        widget.colorValue != Colors.transparent &&
        widget.colorValue != theme.scaffoldBackground;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text Input Area
            Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height > 800 ? 180 : 140,
              ),
              decoration: BoxDecoration(
                color: hasCustomBackground
                    ? widget.colorValue
                    : theme.inputBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: TextFormField(
                controller: textEditingController,
                focusNode: editorFocusNode,
                minLines: MediaQuery.of(context).size.height > 800 ? 7 : 5,
                maxLines: MediaQuery.of(context).size.height > 800 ? 14 : 10,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  color: _getTextColor(
                    hasCustomBackground ? widget.colorValue : null,
                    theme,
                  ),
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                onChanged: (value) {
                  widget.searchPeopleBloc.add(TextFieldEvent(value));
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: translation(context).lbl_whats_on_your_mind,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    color: _getHintTextColor(
                      hasCustomBackground ? widget.colorValue : null,
                      theme,
                    ),
                    fontWeight: FontWeight.w400,
                  ),
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                  contentPadding: const EdgeInsets.all(18),
                ),
              ),
            ),
            // Bottom Toolbar - One UI 8.5 Style
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
              ),
              child: Row(
                children: [
                  // Color Preview Circle
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: widget.colorValue ?? theme.inputBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.border,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Background Color Button - One UI 8.5 Chip
                  Material(
                    color: theme.primary.withOpacity(theme.isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      onTap: () => widget.onColorChange?.call(),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: theme.primary.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red,
                                    Colors.orange,
                                    Colors.yellow,
                                    Colors.green,
                                    Colors.blue,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Background',
                              style: TextStyle(
                                color: theme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
