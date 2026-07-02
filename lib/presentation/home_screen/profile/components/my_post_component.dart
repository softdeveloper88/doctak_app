import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/find_likes.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/post_feed_list_view.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';

/// Profile posts tab — same feed card UI as home/search via [PostFeedListView].
class MyPostComponent extends StatefulWidget {
  const MyPostComponent(this.profileBloc, {super.key});

  final ProfileBloc profileBloc;

  @override
  State<MyPostComponent> createState() => _MyPostComponentState();
}

class _MyPostComponentState extends State<MyPostComponent> {
  final HomeBloc _homeBloc = HomeBloc();

  void _confirmDelete(Post post) {
    showDialog(
      context: context,
      builder: (_) => CustomAlertDialog(
        title: 'Are you sure you want to delete this post?',
        callback: () {
          widget.profileBloc.postList.removeWhere((p) => p.id == post.id);
          _homeBloc.add(DeletePostEvent(postId: post.id));
          setState(() {});
        },
      ),
    );
  }

  void _mutateLike(Post post) {
    setState(() {
      if (findIsLiked(post.likes)) {
        post.likes?.removeWhere((e) => e.userId == AppData.logInUserId);
      } else {
        post.likes ??= [];
        post.likes!.add(
          Likes(
            userId: AppData.logInUserId,
            postId: post.id.toString(),
          ),
        );
      }
    });
    _homeBloc.add(PostLikeEvent(postId: post.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      bloc: widget.profileBloc,
      listener: (_, state) {},
      builder: (context, state) {
        if (state is PaginationLoadedState || state is FullProfileLoadedState) {
          if (widget.profileBloc.postList.isEmpty) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Text(translation(context).msg_no_post_found),
              ),
            );
          }

          final hasMore = widget.profileBloc.numberOfPage !=
              widget.profileBloc.pageNumber - 1;

          return PostFeedListView(
            posts: widget.profileBloc.postList,
            homeBloc: _homeBloc,
            scrollMode: PostFeedScrollMode.nested,
            showPaginationFooter: hasMore,
            onNearEnd: (index) {
              if (widget.profileBloc.pageNumber <=
                      widget.profileBloc.numberOfPage &&
                  index ==
                      widget.profileBloc.postList.length -
                          widget.profileBloc.nextPageTrigger) {
                widget.profileBloc.add(CheckIfNeedMoreDataEvent(index: index));
              }
            },
            hooks: PostFeedCardHooks(
              onDelete: _confirmDelete,
              onLikeMutate: _mutateLike,
              onDismiss: (post) {
                widget.profileBloc.postList.removeWhere((p) => p.id == post.id);
                setState(() {});
              },
              onUserBlocked: (post) {
                widget.profileBloc.postList.removeWhere((p) => p.id == post.id);
                setState(() {});
              },
            ),
          );
        }
        if (state is DataError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text(state.errorMessage)),
          );
        }
        return Center(
          child: CircularProgressIndicator(color: OneUITheme.of(context).primary),
        );
      },
    );
  }
}
