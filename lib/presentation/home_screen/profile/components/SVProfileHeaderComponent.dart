import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/SVConstants.dart';

class SVProfileHeaderComponent extends StatefulWidget {
  UserProfile? userProfile;
  ProfileBloc? profileBoc;

  SVProfileHeaderComponent({this.userProfile,this.profileBoc, Key? key}) : super(key: key);

  @override
  State<SVProfileHeaderComponent> createState() => _SVProfileHeaderComponentState();
}

class _SVProfileHeaderComponentState extends State<SVProfileHeaderComponent> {
  @override
  Widget build(BuildContext context) {
    // print(userProfile?.profilePicture);
    return Column(
      children: [
        GestureDetector(
          onTap: ()  async {

            const permission = Permission.photos;
            if (await permission.isGranted) {
              _showFileOptions(false);
              // _selectFiles(context);
            } else if (await permission.isDenied) {
              final result = await permission.request();
              if (result.isGranted) {
                _showFileOptions(false);
                // _selectFiles(context);
                print("isGranted");
              } else if (result.isDenied) {
                print("isDenied");
              } else if (result.isPermanentlyDenied) {
                print("isPermanentlyDenied");
                // _permissionDialog(context);
              }
            } else if (await permission.isPermanentlyDenied) {
              print("isPermanentlyDenied");
              // _permissionDialog(context);
            }
            _showFileOptions(false);

          },
          child: SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                widget.userProfile?.coverPicture == null || widget.userProfile?.coverPicture== 'public/new_assets/assets/images/page-img/default-profile-bg.jpg'
                    ? Image.asset(
                        'images/socialv/backgroundImage.png',
                        width: context.width(),
                        height: 130,
                        fit: BoxFit.cover,
                      ).cornerRadiusWithClipRRectOnly(
                        topLeft: SVAppCommonRadius.toInt(),
                        topRight: SVAppCommonRadius.toInt())
                    : CachedNetworkImage(
                       imageUrl:  '${widget.userProfile?.coverPicture}',
                        height: 130,
                        fit: BoxFit.cover,
                      ).cornerRadiusWithClipRRectOnly(
                        topLeft: SVAppCommonRadius.toInt(),
                        topRight: SVAppCommonRadius.toInt()),
                Positioned(
                  bottom: 0,
                  child: GestureDetector(
                    onTap: ()  async {

                        const permission = Permission.photos;
                        if (await permission.isGranted) {
                          _showFileOptions(true);
                          // _selectFiles(context);
                        } else if (await permission.isDenied) {
                          final result = await permission.request();
                          if (result.isGranted) {
                            _showFileOptions(true);
                            // _selectFiles(context);
                            print("isGranted");
                          } else if (result.isDenied) {
                            print("isDenied");
                          } else if (result.isPermanentlyDenied) {
                            print("isPermanentlyDenied");
                            // _permissionDialog(context);
                          }
                        } else if (await permission.isPermanentlyDenied) {
                          print("isPermanentlyDenied");
                          // _permissionDialog(context);
                        }
                        _showFileOptions(true);

                    },
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: radius(18)),
                      child: widget.userProfile?.profilePicture == null
                          ? Image.asset('images/socialv/faces/face_5.png',
                                  height: 88, width: 88, fit: BoxFit.cover)
                              .cornerRadiusWithClipRRect(SVAppCommonRadius)
                          : Image.network(
                                  '${widget.userProfile?.profilePicture.validate()}',
                                  height: 88,
                                  width: 88,
                                  fit: BoxFit.cover)
                              .cornerRadiusWithClipRRect(SVAppCommonRadius),
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
                      widget.profileBoc!.add(UpdateProfilePicEvent(filePath: file.path,isProfilePicture: isProfilePic));
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
                      widget.profileBoc!.add(UpdateProfilePicEvent(filePath: file.path,isProfilePicture:isProfilePic ));

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
