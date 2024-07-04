import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/profile_image_screen/profile_image_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/SVConstants.dart';

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

class _SVProfileHeaderComponentState extends State<SVProfileHeaderComponent> {
  @override
  Widget build(BuildContext context) {
    // print(userProfile?.profilePicture);
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            if (widget.isMe ?? false) {
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
            }else{
              ProfileImageScreen(imageUrl:'${widget.userProfile?.coverPicture}' ,).launch(context);
            }
            // _showFileOptions(false);
          },
          child: SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                widget.userProfile?.coverPicture == null ||
                        widget.userProfile?.coverPicture ==
                            'public/new_assets/assets/images/page-img/default-profile-bg.jpg'
                    ? Image.asset(
                        'images/socialv/backgroundImage.png',
                        width: context.width(),
                        height: 130,
                        fit: BoxFit.cover,
                      )
                    .cornerRadiusWithClipRRectOnly(
                        bottomLeft: SVAppCommonRadius.toInt(),
                        bottomRight: SVAppCommonRadius.toInt())
                    : CustomImageView(
                        imagePath: '${widget.userProfile?.coverPicture}',
                        height: 130,
                        fit: BoxFit.cover,
                        width: double.maxFinite,
                      ).cornerRadiusWithClipRRectOnly(
                        bottomLeft: 20,
                        bottomRight: 20),
                        if(!widget.isMe!) Positioned(
                            left: 16,
                            top: 30,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: white,
                                borderRadius: BorderRadius.circular(40)
                              ),
                              child: Center(
                                child: IconButton(
                                  onPressed: (){
                                    Navigator.pop(context);
                                  },
                                    icon: const Icon(Icons.arrow_back_ios,)),
                              ),
                            )),
                Positioned(
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () async {
                      if (widget.isMe ?? false) {
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
                      }else{
                        ProfileImageScreen(imageUrl:'${widget.userProfile?.profilePicture}' ,).launch(context);

                      }
                      // _showFileOptions(true);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: radius(200)),
                      child: widget.userProfile?.profilePicture == null
                          ? Image.asset('images/socialv/faces/face_5.png',
                                  height: 100, width: 100, fit: BoxFit.cover)
                              .cornerRadiusWithClipRRect(SVAppCommonRadius)
                          : CachedNetworkImage(
                          placeholder: (context, url) => Container(
                            color:  Colors.transparent,
                            height: 100,
                            width: 100,
                            child:Image.asset(
                              'images/socialv/faces/face_5.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),

                          errorWidget: (context, url, error) => Image.asset(
                            'images/socialv/faces/face_5.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                                  imageUrl: '${widget.userProfile?.profilePicture.validate()}',
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover)
                              .cornerRadiusWithClipRRect(200),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                title: const Text('Choose from gallery'),
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
                title: const Text('Take a picture'),
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
