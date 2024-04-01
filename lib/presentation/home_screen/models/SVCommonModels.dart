import 'package:flutter/cupertino.dart';

import '../../../localization/app_localization.dart';

class SVDrawerModel {
  String? title;
  String? image;

  SVDrawerModel({this.image, this.title});
}

List<SVDrawerModel> getDrawerOptions(BuildContext context) {
  List<SVDrawerModel> list = [];

  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Profile.png', title: translation(context).lbl_jobs));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_2User.png', title: translation(context).lbl_drug_list));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_3User.png', title: translation(context).lbl_conference));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Image.png', title:translation(context).lbl_guidelines));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Document.png', title:translation(context).lbl_moh_update ));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Document.png', title: translation(context).lbl_library_magazines));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Document.png', title: translation(context).lbl_CME));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Document.png', title: translation(context).lbl_world_news));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Document.png', title: translation(context).lbl_discounts));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Document.png', title: translation(context).lbl_suggestions));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Document.png', title: 'App Setting'));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Send.png', title: translation(context).lbl_share_app));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Star.png', title:translation(context).lbl_rate_us ));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Logout.png', title: translation(context).lbl_logout));
  list.add(SVDrawerModel(image: 'images/socialv/icons/ic_Document.png', title:translation(context).lbl_delete_account));

  return list;
}
