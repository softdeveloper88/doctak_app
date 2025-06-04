import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../core/app_export.dart';
import '../../add_post/bloc/add_post_event.dart';

class TagFriendsListBottomSheet extends StatefulWidget {
  AddPostBloc searchPeopleBloc;

  TagFriendsListBottomSheet(this.searchPeopleBloc, {Key? key})
      : super(key: key);

  @override
  State<TagFriendsListBottomSheet> createState() =>
      _TagFriendsListBottomSheetState();
}

class _TagFriendsListBottomSheetState extends State<TagFriendsListBottomSheet> {
  @override
  void initState() {
    widget.searchPeopleBloc.add(LoadPageEvent(page: 1, name: ''));
    super.initState();
    afterBuildCreated(() {
      setStatusBarColor(svGetScaffoldColor());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: svGetScaffoldColor(),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modern Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tag Friends',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Colors.blue[800],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search Field
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: appStore.isDarkMode
                  ? Colors.grey[800]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.blue.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.blue.withOpacity(0.6),
                    size: 24,
                  ),
                ),
                Expanded(
                  child: AppTextField(
                    textFieldType: TextFieldType.NAME,
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: appStore.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                    onChanged: (name) {
                      widget.searchPeopleBloc.add(
                        LoadPageEvent(
                          page: 1,
                          name: name,
                        ),
                      );
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search friends...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Selected Friends
          BlocConsumer<AddPostBloc, AddPostState>(
            bloc: widget.searchPeopleBloc,
            listener: (BuildContext context, AddPostState state) {},
            builder: (context, state) {
              if (state is PaginationLoadedState &&
                  widget.searchPeopleBloc.selectedSearchPeopleData.isNotEmpty) {
                return Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.searchPeopleBloc.selectedSearchPeopleData.length,
                    itemBuilder: (context, index) {
                      final person = widget.searchPeopleBloc.selectedSearchPeopleData[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  person.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Name
                            Text(
                              '${person.firstName} ${person.lastName}',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Remove Button
                            GestureDetector(
                              onTap: () {
                                widget.searchPeopleBloc.add(
                                  SelectFriendEvent(
                                    userData: person,
                                    isAdd: false,
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.blue[700],
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          if (widget.searchPeopleBloc.selectedSearchPeopleData.isNotEmpty)
            Divider(
              color: Colors.grey.withOpacity(0.2),
              indent: 16,
              endIndent: 16,
            ),
          // Friends List
          BlocConsumer<AddPostBloc, AddPostState>(
            bloc: widget.searchPeopleBloc,
            listener: (BuildContext context, AddPostState state) {},
            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue[600],
                      strokeWidth: 3,
                    ),
                  ),
                );
              } else if (state is PaginationLoadedState) {
                final bloc = widget.searchPeopleBloc;
                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: bloc.searchPeopleData.length,
                    itemBuilder: (context, index) {
                      if (bloc.pageNumber <= bloc.numberOfPage) {
                        if (index ==
                            bloc.searchPeopleData.length - bloc.nextPageTrigger) {
                          bloc.add(CheckIfNeedMoreDataEvent(index: index));
                        }
                      }
                      
                      if (bloc.numberOfPage != bloc.pageNumber - 1 &&
                          index >= bloc.searchPeopleData.length - 1) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.blue[600],
                            strokeWidth: 3,
                          ),
                        );
                      }
                      
                      final person = bloc.searchPeopleData[index];
                      return InkWell(
                        onTap: () {
                          bloc.add(SelectFriendEvent(
                            userData: person,
                            isAdd: true,
                          ));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: appStore.isDarkMode
                                ? Colors.grey[900]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                offset: const Offset(0, 2),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Profile Picture
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: person.profilePic?.isNotEmpty == true
                                      ? CachedNetworkImage(
                                          imageUrl: '${AppData.imageUrl}${person.profilePic}',
                                          height: 48,
                                          width: 48,
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
                                              child: Text(
                                                person.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                                                style: TextStyle(
                                                  color: Colors.blue[700],
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.blue[50],
                                          child: Center(
                                            child: Text(
                                              person.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Name and Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '${person.firstName} ${person.lastName}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Poppins',
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // if (person.isVerified ?? false) ...[
                                        //   const SizedBox(width: 6),
                                        //   Container(
                                        //     padding: const EdgeInsets.all(2),
                                        //     decoration: BoxDecoration(
                                        //       color: Colors.blue,
                                        //       shape: BoxShape.circle,
                                        //     ),
                                        //     child: const Icon(
                                        //       Icons.check,
                                        //       size: 10,
                                        //       color: Colors.white,
                                        //     ),
                                        //   ),
                                        // ],
                                      ],
                                    ),
                                    // if (person.specialty != null) ...[
                                    //   const SizedBox(height: 2),
                                    //   Text(
                                    //     person.specialty!,
                                    //     style: TextStyle(
                                    //       fontSize: 13,
                                    //       color: Colors.grey[600],
                                    //       fontFamily: 'Poppins',
                                    //     ),
                                    //     overflow: TextOverflow.ellipsis,
                                    //   ),
                                    // ],
                                  ],
                                ),
                              ),
                              // Add Icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              } else if (state is DataError) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const Expanded(
                  child: Center(
                    child: Text(
                      'Start typing to search friends',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}