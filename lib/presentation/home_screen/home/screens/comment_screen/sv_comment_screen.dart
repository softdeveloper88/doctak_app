import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_content_type.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_sheet_widgets.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/improved_reply_comment_list_widget.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/virtualized_comment_list.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/enhanced_comment_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SVCommentScreen extends StatefulWidget {
  final int? id;
  final String? contentId;
  final CommentContentType contentType;
  final HomeBloc? homeBloc;
  final bool isBottomSheet;
  final ValueChanged<int>? onCommentCountChanged;

  const SVCommentScreen({
    this.id,
    this.contentId,
    this.contentType = CommentContentType.post,
    this.homeBloc,
    this.isBottomSheet = false,
    this.onCommentCountChanged,
    super.key,
  }) : assert(id != null || contentId != null);

  String get resolvedContentId => contentId ?? id?.toString() ?? '';

  @override
  State<SVCommentScreen> createState() => _SVCommentScreenState();
}

class _SVCommentScreenState extends State<SVCommentScreen> {
  CommentBloc get commentBloc => _commentBloc;
  late final CommentBloc _commentBloc;
  final ScrollController _scrollController = ScrollController();
  int? selectedCommentId;
  int? focusReplyForCommentId;
  int _lastCommentCount = 0;

  @override
  void initState() {
    super.initState();
    _commentBloc = CommentBloc(
      contentType: widget.contentType,
      contentId: widget.resolvedContentId,
    );
    _commentBloc.add(
      LoadPageEvent(
        postId: int.tryParse(widget.resolvedContentId),
        page: 1,
      ),
    );
    preloadSpecialties();
  }

  void _scrollToLatestComment() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _commentBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  int get _inputParentId => int.tryParse(widget.resolvedContentId) ?? 0;

  void _notifyCommentCount() {
    widget.onCommentCountChanged?.call(_commentBloc.postList.length);
  }

  void _closeBottomSheet() {
    final count = _commentBloc.postList.length;
    Navigator.of(context).pop(count);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBottomSheet) {
      return _buildBottomSheetBody(context);
    }
    return _buildFullScreenBody(context);
  }

  Widget _buildBottomSheetBody(BuildContext context) {
    final theme = OneUITheme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closeBottomSheet();
      },
      child: ColoredBox(
        color: theme.cardBackground,
        child: Column(
          children: [
            const CommentSheetDragHandle(),
            BlocBuilder<CommentBloc, CommentState>(
              bloc: _commentBloc,
              builder: (context, state) {
                if (state is PaginationLoadingState &&
                    _commentBloc.postList.isEmpty) {
                  return const CommentSheetHeaderShimmer();
                }
                return CommentSheetHeader(
                  count: _commentBloc.postList.length,
                  onClose: _closeBottomSheet,
                );
              },
            ),
            Expanded(child: _buildCommentList()),
            Material(
              color: theme.cardBackground,
              elevation: 0,
              child: ImprovedReplyInputField(
                commentBloc: _commentBloc,
                commentId: 0,
                postId: _inputParentId,
                compact: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenBody(BuildContext context) {
    final theme = OneUITheme.of(context);
    final systemUiOverlayStyle =
        (theme.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: DoctakAppBar(
          title: translation(context).lbl_comments,
          titleIcon: Icons.chat_bubble_outline_rounded,
          onBackPressed: () => Navigator.of(context).maybePop(),
        ),
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: _buildCommentList(),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.cardBackground,
                border: Border(
                  top: BorderSide(
                    color: theme.divider.withValues(alpha: 0.6),
                    width: 0.5,
                  ),
                ),
              ),
              child: ImprovedReplyInputField(
                commentBloc: _commentBloc,
                commentId: 0,
                postId: _inputParentId,
                compact: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentList() {
    return BlocConsumer<CommentBloc, CommentState>(
      bloc: _commentBloc,
      listener: (BuildContext context, CommentState state) {
        if (state is PaginationLoadedState) {
          final count = _commentBloc.postList.length;
          _notifyCommentCount();
          if (count > _lastCommentCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _scrollToLatestComment();
            });
          }
          _lastCommentCount = count;
        }
      },
      builder: (context, state) {
        if (state is PaginationLoadingState && _commentBloc.postList.isEmpty) {
          return const EnhancedCommentShimmer();
        }
        if (state is DataError && _commentBloc.postList.isEmpty) {
          return RetryWidget(
            errorMessage: translation(context).msg_something_went_wrong_retry,
            onRetry: () {
              _commentBloc.add(
                LoadPageEvent(
                  postId: int.tryParse(widget.resolvedContentId),
                  page: 1,
                ),
              );
            },
          );
        }
        if (_commentBloc.postList.isNotEmpty || state is PaginationLoadedState) {
          return VirtualizedCommentList(
            commentBloc: _commentBloc,
            scrollController: _scrollController,
            selectedCommentId: selectedCommentId,
            focusReplyForCommentId: focusReplyForCommentId,
            isBottomSheet: widget.isBottomSheet,
            onReplySelected: (commentId, {bool expandOnly = false}) {
              setState(() {
                if (expandOnly) {
                  selectedCommentId = commentId;
                  focusReplyForCommentId = commentId;
                } else {
                  selectedCommentId =
                      (selectedCommentId == commentId) ? null : commentId;
                  if (selectedCommentId != commentId) {
                    focusReplyForCommentId = null;
                  }
                }
              });
            },
            onReplyFocusHandled: () {
              if (focusReplyForCommentId != null) {
                setState(() => focusReplyForCommentId = null);
              }
            },
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              translation(context).msg_no_comments_yet,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: CommentSheetTokens.metaText,
                fontSize: CommentSheetTokens.bodySize,
              ),
            ),
          ),
        );
      },
    );
  }
}
