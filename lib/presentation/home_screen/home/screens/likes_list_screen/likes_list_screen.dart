import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'bloc/likes_bloc.dart';

class LikesListScreen extends StatefulWidget {
  final String id;

  const LikesListScreen({required this.id, super.key});

  @override
  State<LikesListScreen> createState() => _LikesListScreenState();
}

class _LikesListScreenState extends State<LikesListScreen> {
  LikesBloc likesBloc = LikesBloc();

  @override
  void initState() {
    likesBloc.add(LoadPageEvent(postId: widget.id));
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(title: translation(context).lbl_people_who_likes, titleIcon: Icons.favorite_rounded),
      body: BlocConsumer<LikesBloc, LikesState>(
        bloc: likesBloc,
        listener: (BuildContext context, LikesState state) {
          if (state is DataError) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: theme.cardBackground,
                content: Text(state.errorMessage, style: TextStyle(color: theme.textPrimary)),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DataInitial) {
            return const UserShimmer();
          } else if (state is PaginationLoadedState) {
            return likesBloc.postLikesList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 64, color: theme.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          translation(context).msg_no_likes,
                          style: TextStyle(color: theme.textSecondary, fontSize: 16, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    scrollDirection: Axis.vertical,
                    physics: const BouncingScrollPhysics(),
                    itemCount: likesBloc.postLikesList.length,
                    itemBuilder: (context, index) {
                      final user = likesBloc.postLikesList[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.border, width: 0.5),
                          boxShadow: theme.cardShadow,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: GestureDetector(
                            onTap: () {
                              SVProfileFragment(userId: user.id).launch(context);
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.primary.withValues(alpha: 0.2), width: 2),
                                boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: user.profilePic!.isEmpty
                                  ? Image.asset('images/socialv/faces/face_5.png', fit: BoxFit.cover).cornerRadiusWithClipRRect(25)
                                  : CachedNetworkImage(
                                      imageUrl: user.profilePic!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: theme.surfaceVariant),
                                      errorWidget: (context, url, error) => Icon(Icons.error, color: theme.error),
                                    ).cornerRadiusWithClipRRect(25),
                            ),
                          ),
                          title: Text(
                            user.name.validate(),
                            style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Poppins'),
                          ),
                          trailing: Icon(Icons.favorite, color: theme.likeColor, size: 20),
                        ),
                      );
                    },
                  );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }
}
