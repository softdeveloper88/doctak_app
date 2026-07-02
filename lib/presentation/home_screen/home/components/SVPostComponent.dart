import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/post_feed_list_view.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:doctak_app/widgets/offline_retry_banner.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/post_shimmer_loader.dart';
import 'package:flutter/material.dart';

/// Search (and other legacy) post list — renders via shared [PostFeedListView]
/// so UI matches the home feed cards.
class SVPostComponent extends StatefulWidget {
  const SVPostComponent(this.homeBloc, {this.isNestedScroll = true, super.key});

  final HomeBloc homeBloc;

  /// If true, nested inside a parent scroll view. If false, owns its scroll.
  final bool isNestedScroll;

  @override
  State<SVPostComponent> createState() => _SVPostComponentState();
}

class _SVPostComponentState extends State<SVPostComponent> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (!widget.isNestedScroll) {
      _scrollController = ScrollController()..addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    _scrollController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    final ctrl = _scrollController;
    if (ctrl == null || !ctrl.hasClients) return;
    if (ctrl.position.maxScrollExtent - ctrl.offset > 200) return;
    if (widget.homeBloc.pageNumber <= widget.homeBloc.numberOfPage) {
      widget.homeBloc.add(
        PostCheckIfNeedMoreDataEvent(
          index: widget.homeBloc.postList.length - widget.homeBloc.nextPageTrigger,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (_) => CustomAlertDialog(
        title: translation(context).msg_confirm_delete_post,
        callback: () => widget.homeBloc.add(DeletePostEvent(postId: post.id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: widget.homeBloc,
      builder: (context, state) {
        final theme = OneUITheme.of(context);
        if (state is PostPaginationLoadingState) {
          return const PostShimmerLoader(itemCount: 5);
        }
        if (state is PostsEmptyState) {
          return Container(
            color: theme.scaffoldBackground,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primary.withValues(alpha: 0.15),
                          theme.secondary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.article_outlined,
                        size: 48, color: theme.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(translation(context).msg_no_posts,
                      style: theme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Try adjusting your search criteria',
                      style: theme.bodySecondary),
                ],
              ),
            ),
          );
        }
        if (state is PostPaginationLoadedState ||
            state is PostOfflineWithCacheState) {
          if (widget.homeBloc.postList.isEmpty) {
            return const PostShimmerLoader(itemCount: 5);
          }

          final isOffline = state is PostOfflineWithCacheState;
          final hasMore =
              widget.homeBloc.numberOfPage != widget.homeBloc.pageNumber - 1;

          return PostFeedListView(
            posts: widget.homeBloc.postList,
            homeBloc: widget.homeBloc,
            scrollMode: widget.isNestedScroll
                ? PostFeedScrollMode.nested
                : PostFeedScrollMode.standalone,
            scrollController: _scrollController,
            showPaginationFooter: !isOffline && hasMore,
            insertAds: !widget.isNestedScroll,
            header: isOffline
                ? OfflineRetryBanner(
                    message: state.errorMessage,
                    onRetry: () => widget.homeBloc.add(ManualRetryEvent()),
                    showAnimation: false,
                  )
                : null,
            onNearEnd: (index) {
              if (widget.homeBloc.pageNumber <= widget.homeBloc.numberOfPage &&
                  index ==
                      widget.homeBloc.postList.length -
                          widget.homeBloc.nextPageTrigger) {
                widget.homeBloc.add(PostCheckIfNeedMoreDataEvent(index: index));
              }
            },
            hooks: PostFeedCardHooks(
              onDelete: (post) => _confirmDelete(context, post),
              onDismiss: (post) {
                widget.homeBloc.postList.removeWhere((p) => p.id == post.id);
                setState(() {});
              },
              onUserBlocked: (post) {
                widget.homeBloc.postList.removeWhere((p) => p.id == post.id);
                setState(() {});
              },
            ),
          );
        }
        if (state is PostDataError) {
          return RetryWidget(
            errorMessage: state.errorMessage.isNotEmpty
                ? state.errorMessage
                : translation(context).msg_something_went_wrong_retry,
            onRetry: () => widget.homeBloc.add(ManualRetryEvent()),
          );
        }
        return Center(child: Text(translation(context).lbl_search_post));
      },
    );
  }
}
