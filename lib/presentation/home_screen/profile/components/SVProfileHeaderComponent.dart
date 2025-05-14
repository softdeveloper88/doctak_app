import 'dart:io';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/followers_screen/follower_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/profile_image_screen/profile_image_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import 'SVProfilePostsComponent.dart';

class SVProfileHeaderComponent extends StatefulWidget {
  UserProfile? userProfile;
  ProfileBloc? profileBoc;
  bool? isMe;

  SVProfileHeaderComponent(
      {this.userProfile, this.profileBoc, this.isMe, Key? key})
      : super(key: key);

  @override
  State<SVProfileHeaderComponent> createState() =>
      _SVProfileHeaderComponentState();
}

Widget _buildPointsCard(BuildContext context) {
  return Card(
    elevation: 4.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            translation(context).lbl_your_earned_points,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '300',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    ),
  );
}

class _SVProfileHeaderComponentState extends State<SVProfileHeaderComponent> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Background Image
                InkWell(
                  onTap: (){
                    ProfileImageScreen(
                      imageUrl: '${widget.userProfile?.coverPicture}',
                    ).launch(context);
                  },
                  child: Container(
                  height: 260,
                  width: double.maxFinite,
                  decoration: BoxDecoration(),
                  child: widget.userProfile?.coverPicture == null ||
                          widget.userProfile?.coverPicture ==
                              'public/new_assets/assets/images/page-img/default-profile-bg.jpg'
                      ? Image.asset('assets/images/img_cover.png')
                      : CustomImageView(
                          imagePath: widget.userProfile?.coverPicture ?? '',
                          height: 260,
                          width: double.maxFinite,
                          fit: BoxFit.cover,
                          placeHolder: 'assets/images/img_cover.png',
                        ),
                              )
                ), // Back button and overlay
              if (!(widget.isMe ?? false))
                Positioned(
                  top: 40,
                  left: 16,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              if (widget.isMe ?? false)
                Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    onPressed: () async {
                        const permission = Permission.storage;
                        const permission1 = Permission.photos;
                        var status = await permission.status;
                        print(status);
                        if (await permission1.isGranted) {
                          _showFileOptions(false);
                          // _selectFiles(context);
                        } else if (await permission1.isDenied) {
                          final result = await permission1.request();
                          if (status.isGranted) {
                            _showFileOptions(false);
                            // _selectFiles(context);
                            print("isGranted");
                          } else if (result.isGranted) {
                            _showFileOptions(false);
                            // _selectFiles(context);
                            print("isGranted");
                          } else if (result.isDenied) {
                            final result = await permission.request();
                            print("isDenied");
                          } else if (result.isPermanentlyDenied) {
                            print("isPermanentlyDenied");
                            // _permissionDialog(context);
                          }
                        } else if (await permission.isPermanentlyDenied) {
                          print("isPermanentlyDenied");
                          // _permissionDialog(context);
                        }

                    },
                    icon: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              Positioned(
                 top: 230,
                  left: 0,
                  right: 0,
                  child: Container(
                     height: 100,
                decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    )
                            ))),

              Positioned(
                right: (100.w/2)-60,
                top: 180,
                child: Stack(
                  children: [
                    // Profile Picture
                    Container(
                      margin: const EdgeInsets.all(10),
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.grey.shade200,
                      ),
                      child: ClipOval(
                        child: widget.userProfile?.profilePicture == null
                            ? Image.asset(
                          'images/socialv/faces/face_5.png',
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        )
                            : CustomImageView(
                          imagePath: widget.userProfile?.profilePicture ?? '',
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          placeHolder: 'images/socialv/faces/face_5.png',
                        ),
                      ),
                    ).onTap(() async {

                        ProfileImageScreen(
                          imageUrl: '${widget.userProfile?.profilePicture}',
                        ).launch(context);

                    }),
                    // Camera Icon
                    if (widget.isMe ?? false)
                      Positioned(
                        top: 10,
                        right: 5,
                        child: Material(
                          color: Colors.transparent, // Ensure tap passes through transparent areas
                          child: InkWell(
                            onTap: () async {
                              const permission = Permission.storage;
                              const permission1 = Permission.photos;
                              var status = await permission.status;
                              print(status);
                              if (await permission1.isGranted) {
                                _showFileOptions(true);
                                // _selectFiles(context);
                              } else if (await permission1.isDenied) {
                                final result = await permission1.request();
                                if (status.isGranted) {
                                  _showFileOptions(true);
                                  // _selectFiles(context);
                                  print("isGranted");
                                } else if (result.isGranted) {
                                  _showFileOptions(true);
                                  // _selectFiles(context);
                                  print("isGranted");
                                } else if (result.isDenied) {
                                  final result = await permission.request();
                                  print("isDenied");
                                } else if (result.isPermanentlyDenied) {
                                  print("isPermanentlyDenied");
                                  // _permissionDialog(context);
                                }
                              } else if (await permission.isPermanentlyDenied) {
                                print("isPermanentlyDenied");
                                // _permissionDialog(context);
                              }
                            },
                            borderRadius: BorderRadius.circular(20), // For ripple effect shape
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            children: [
              // Profile Image
              const SizedBox(height:30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                      '${widget.userProfile?.user?.firstName ?? ''} ${widget.userProfile?.user?.lastName ?? ''}',
                      style: TextStyle(
                          color: svGetBodyColor(),
                          fontSize: 18,
                          fontWeight: FontWeight.w500)),
                  4.width,
                  Image.asset('images/socialv/icons/ic_TickSquare.png',
                      height: 14, width: 14, fit: BoxFit.cover),
                ],
              ),
              SizedBox(
                width: 80.w,
                child: Text('${widget.userProfile?.user?.state?? ''} ${widget.userProfile?.user?.state != null ?',':''}${widget.userProfile?.user?.country ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
              ),
              SizedBox(
                width: 80.w,
                child: Text(widget.userProfile?.user?.specialty ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: svGetBodyColor(),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )),
              ),
              SizedBox(
                width: 80.w,
                child: Text(widget.userProfile?.profile?.aboutMe ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: svGetBodyColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    )),
              ),
              // Follow button
              // ElevatedButton.icon(
              //   onPressed: () {},
              //   icon: const Icon(Icons.person_add),
              //   label: const Text('Follow'),
              //   style: ElevatedButton.styleFrom(
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(20),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 20),
              // // Stats Row
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //   children: [
              //     Column(
              //       children: const [
              //         Text(
              //           '150',
              //           style: TextStyle(
              //             fontSize: 18,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //         Text(
              //           'Posts',
              //           style: TextStyle(color: Colors.grey),
              //         ),
              //       ],
              //     ),
              //     Column(
              //       children: const [
              //         Text(
              //           '2500',
              //           style: TextStyle(
              //             fontSize: 18,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //         Text(
              //           'Following',
              //           style: TextStyle(color: Colors.grey),
              //         ),
              //       ],
              //     ),
              //     Column(
              //       children: const [
              //         Text(
              //           '3500',
              //           style: TextStyle(
              //             fontSize: 18,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //         Text(
              //           'Followers',
              //           style: TextStyle(color: Colors.grey),
              //         ),
              //       ],
              //     ),
              //   ],
              // ),
              if (widget.isMe ?? false) _buildPointsCard(context),
              if (widget.isMe != true)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        ChatRoomScreen(
                          username:
                          '${widget.userProfile?.user?.firstName} ${widget.userProfile?.user?.lastName}',
                          profilePic:
                          '${widget.userProfile?.profilePicture?.replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', '')}',
                          id: '${widget.userProfile?.user?.id}',
                          roomId: '',
                        ).launch(context);
                      },
                      child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border:
                            Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          height: 40.0,
                          child: SvgPicture.asset(
                            'assets/icon/ic_message.svg',
                            color: Colors.blue,
                          )
                        // Text('Chat',
                        //     style: boldTextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    MaterialButton(
                      height: 40.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      minWidth: 100,
                      onPressed: () {
                        if (widget.userProfile!.isFollowing ?? false) {
                          widget.profileBoc?.add(SetUserFollow(
                              widget.userProfile?.user?.id ?? '',
                              'unfollow'));

                          widget.userProfile!.isFollowing = false;
                        } else {
                          widget.profileBoc?.add(SetUserFollow(
                              widget.userProfile?.user?.id ?? '',
                              'follow'));

                          widget.userProfile!.isFollowing = true;
                        }
                        setState(() {});
                      },
                      elevation: 2,
                      color: SVAppColorPrimary,
                      child: Text(
                          widget.userProfile?.isFollowing ?? false
                              ? translation(context).lbl_following
                              : translation(context).lbl_follow,
                          style: boldTextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              16.height,
              // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Column(
                      children: [
                        Text('${widget.userProfile?.totalPosts ?? ''}',
                            style: boldTextStyle(size: 18)),
                        4.height,
                        Text(translation(context).lbl_posts,
                            style: secondaryTextStyle(
                                color: svGetBodyColor(), size: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (!(widget.isMe ?? false)) {
                        FollowerScreen(
                          isFollowersScreen: true,
                          userId: widget.userProfile?.user?.id ?? '',
                        ).launch(context);
                      } else {
                        FollowerScreen(
                          isFollowersScreen: true,
                          userId: AppData.logInUserId,
                        ).launch(context);
                      }
                    },
                    child: Column(
                      children: [
                        Text(
                            widget.userProfile?.totalFollows
                                ?.totalFollowings ??
                                '',
                            style: boldTextStyle(size: 18)),
                        4.height,
                        Text(translation(context).lbl_followers,
                            style: secondaryTextStyle(
                                color: svGetBodyColor(), size: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (!(widget.isMe ?? false)) {
                        FollowerScreen(
                          isFollowersScreen: false,
                          userId: widget.userProfile?.user?.id ?? '',
                        ).launch(context);
                      } else {
                        FollowerScreen(
                          isFollowersScreen: false,
                          userId: AppData.logInUserId,
                        ).launch(context);
                      }
                    },
                    child: Column(
                      children: [
                        Text(
                            widget.userProfile?.totalFollows
                                ?.totalFollowers ??
                                '',
                            style: boldTextStyle(size: 18)),
                        4.height,
                        Text(translation(context).lbl_followings,
                            style: secondaryTextStyle(
                                color: svGetBodyColor(), size: 12)),
                      ],
                    ),
                  )
                ],
              ),
              16.height,
              Container(
                color: svGetBgColor(),
                height: 10,
              ),
              SVProfilePostsComponent(
                widget.profileBoc!,
              ),
            ],
          ),

        ],
      ),
    );
  }

  var _selectedFile;

  void _showFileOptions(bool isProfilePic) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo),
                title: Text(translation(context).lbl_choose_from_gallery),
                onTap: () async {
                  Navigator.pop(context);
                  File? file = await _pickFile(ImageSource.gallery);
                  if (file != null) {
                    setState(() {
                      print('ddd${file.path}');
                      _selectedFile = file;
                      widget.profileBoc!.add(UpdateProfilePicEvent(
                          filePath: file.path, isProfilePicture: isProfilePic));
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(translation(context).lbl_take_a_picture),
                onTap: () async {
                  Navigator.pop(context);
                  File? file = await _pickFile(ImageSource.camera);
                  if (file != null) {
                    setState(() {
                      print('ddd${file.path}');
                      _selectedFile = file;
                      widget.profileBoc!.add(UpdateProfilePicEvent(
                          filePath: file.path, isProfilePicture: isProfilePic));
                    });
                  }
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.insert_drive_file),
              //   title: const Text('Select a document'),
              //   onTap: () async {
              //     Navigator.pop(context);
              //     File? file = await _pickFile(ImageSource.gallery);
              //     if (file != null) {
              //       setState(() {
              //         _selectedFile = file;
              //       });
              //     }
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }

  Future<File?> _pickFile(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }
}
