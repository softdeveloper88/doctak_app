import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/data/models/search_people_model/search_people_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../bloc/search_people_bloc.dart';

class SVSearchCardComponent extends StatefulWidget {
  final Data element;
  final Function onTap;
  final SearchPeopleBloc bloc;

  SVSearchCardComponent({
    required this.element,
    required this.onTap,
    required this.bloc,
  });

  @override
  _SVSearchCardComponentState createState() => _SVSearchCardComponentState();
}

class _SVSearchCardComponentState extends State<SVSearchCardComponent> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Picture
          GestureDetector(
            onTap: () {
              SVProfileFragment(userId: widget.element.id)
                  .launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: widget.element.profilePic?.isEmpty ?? true
                    ? Container(
                        color: Colors.blue[50],
                        child: Center(
                          child: Text(
                            '${widget.element.firstName?.substring(0, 1).toUpperCase() ?? 'U'}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl:
                            '${AppData.imageUrl}${widget.element.profilePic.validate()}',
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.blue[50],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.blue[400],
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.blue[50],
                          child: Center(
                            child: Icon(
                              Icons.person,
                              color: Colors.blue[400],
                              size: 28,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: GestureDetector(
              onTap: () {
                SVProfileFragment(userId: widget.element.id)
                    .launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "${widget.element.firstName ?? ''} ${widget.element.lastName ?? ''}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (widget.element.isFollowedByCurrentUser ?? false) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    capitalizeWords(
                      widget.element.specialty ??
                          widget.element.userType ??
                          "Medical Professional",
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Follow/Unfollow Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? Container(
                    width: 90,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                  )
                : InkWell(
                    onTap: () async {
                      setState(() {
                        isLoading = true;
                      });
                      await widget.onTap();
                      setState(() {
                        isLoading = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.element.isFollowedByCurrentUser == true
                            ? Colors.blue
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.element.isFollowedByCurrentUser == true
                              ? Colors.blue
                              : Colors.blue.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        widget.element.isFollowedByCurrentUser == true
                            ? translation(context).lbl_unfollow
                            : translation(context).lbl_follow,
                        style: TextStyle(
                          color: widget.element.isFollowedByCurrentUser == true
                              ? Colors.white
                              : Colors.blue[700],
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
    );
  }
}
