import 'package:doctak_app/core/utils/image_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String profilePicUrl;
  final String userName;
  final String? createdAt;
  final String? specialty;
  final VoidCallback onProfileTap;
  final VoidCallback onDeleteTap;
  final bool isCurrentUser;

  const ProfileHeaderWidget({
    Key? key,
    required this.profilePicUrl,
    required this.userName,
     this.createdAt,
     this.specialty,
    required this.onProfileTap,
    required this.onDeleteTap,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: ()=>onProfileTap(),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(profilePicUrl),
                      radius: 25,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          // clipBehavior: Clip.none,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: 38.w
                              ),
                              child: Text(
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: true,
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14
                                ),
                              ),
                            ),
                            const Text(
                              ' · ',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Image.asset('images/socialv/icons/ic_TickSquare.png',
                              height: 14,
                              width: 14,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                       if(specialty !=null) SizedBox(
                         width: 40.w,
                         child: Row(
                           spacing: 10,
                            // crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SvgPicture.asset(icSpecialty, height: 15,width: 15,color: Colors.grey,),
                              Expanded(
                                child: Text(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  (specialty?.length??0)>20?'${specialty?.substring(0,20)}...': specialty??'',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                
                                  ),
                                ),
                              ),
                            ],
                          ),
                       ) else Row(
                          children: [
                            Text(
                              createdAt??'',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,

                              ),
                            ),
                            const Text(
                              ' · ',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            SvgPicture.asset(icGlob, height: 12,width: 12,),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCurrentUser)
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Delete', child: Text('Delete')),
                  ],
                  onSelected: (value) {
                    if (value == 'Delete') {
                      onDeleteTap();
                    }
                  },
                ),
            ],
          ),

    );
  }
}