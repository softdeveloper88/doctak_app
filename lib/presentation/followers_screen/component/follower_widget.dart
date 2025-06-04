import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/followers_screen/bloc/followers_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../main.dart';

class FollowerWidget extends StatefulWidget {
  final dynamic element;
  final String userId;
  final Function onTap;
  final FollowersBloc bloc;

  const FollowerWidget({
    Key? key,
    required this.element,
    required this.onTap,
    required this.bloc,
    required this.userId,
  }) : super(key: key);

  @override
  State<FollowerWidget> createState() => _FollowerWidgetState();
}

class _FollowerWidgetState extends State<FollowerWidget> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: appStore.isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.withAlpha(26),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withAlpha(20),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              SVProfileFragment(userId: widget.element.id)
                  .launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Profile Picture with modern styling
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.withAlpha(51),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withAlpha(38),
                          offset: const Offset(0, 3),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.element.profilePic == '' || widget.element.profilePic == null
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue[100]!,
                                    Colors.blue[200]!,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.blue[600],
                                size: 28,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: widget.element.profilePic ?? '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[100]!,
                                      Colors.blue[200]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.blue[600],
                                  size: 28,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[100]!,
                                      Colors.blue[200]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.blue[600],
                                  size: 28,
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // User Info Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Name with verification badge
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.element.name ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: appStore.isDarkMode 
                                      ? Colors.white 
                                      : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // Specialty/User Type
                        Text(
                          capitalizeWords(widget.element.specialty ?? "Doctor"),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Poppins',
                            color: appStore.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Follow/Unfollow Button
                  if (widget.userId == AppData.logInUserId)
                    isLoading
                        ? SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[600]!,
                              ),
                            ),
                          )
                        : AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: MaterialButton(
                              minWidth: 80,
                              height: 36,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: widget.element.isCurrentlyFollow == true
                                      ? Colors.transparent
                                      : Colors.blue.withAlpha(77),
                                  width: 1,
                                ),
                              ),
                              onPressed: () async {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  await widget.onTap();
                                } catch (e) {
                                  // Handle error if needed
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              },
                              elevation: 0,
                              color: widget.element.isCurrentlyFollow == true
                                  ? Colors.blue[600]
                                  : Colors.transparent,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.element.isCurrentlyFollow == true
                                        ? Icons.person_remove_outlined
                                        : Icons.person_add_outlined,
                                    color: widget.element.isCurrentlyFollow == true
                                        ? Colors.white
                                        : Colors.blue[600],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.element.isCurrentlyFollow == true
                                        ? translation(context).lbl_unfollow
                                        : translation(context).lbl_follow,
                                    style: TextStyle(
                                      color: widget.element.isCurrentlyFollow == true
                                          ? Colors.white
                                          : Colors.blue[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}