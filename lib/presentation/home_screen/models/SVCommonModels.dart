import 'package:flutter/cupertino.dart';

import '../../../localization/app_localization.dart';

class SVDrawerModel {
  String? title;
  String? image;

  SVDrawerModel({this.image, this.title});
}

List<SVDrawerModel> getDrawerOptions(BuildContext context) {
  List<SVDrawerModel> list = [];

  list.add(SVDrawerModel(image: 'assets/icon/ic_jobs.png', title: translation(context).lbl_jobs));
  list.add(SVDrawerModel(image: 'assets/icon/ic_drugs.png', title: translation(context).lbl_drug_list));
  list.add(SVDrawerModel(image: 'assets/icon/ic_conference.png', title: translation(context).lbl_conference));
  list.add(SVDrawerModel(image: 'assets/icon/ic_guidlines.png', title:translation(context).lbl_guidelines));
  list.add(SVDrawerModel(image: 'assets/icon/ic_moh.png', title:translation(context).lbl_moh_update ));
  list.add(SVDrawerModel(image: 'assets/icon/ic_library.png', title: translation(context).lbl_library_magazines));
  list.add(SVDrawerModel(image: 'assets/icon/ic_cme.png', title: translation(context).lbl_CME));
  list.add(SVDrawerModel(image: 'assets/images/img_group.png', title: 'Groups'));
  list.add(SVDrawerModel(image: 'assets/icon/ic_world_news.png', title: translation(context).lbl_world_news));
  list.add(SVDrawerModel(image: 'assets/icon/ic_discount.png', title: translation(context).lbl_discounts));
  list.add(SVDrawerModel(image: 'assets/icon/ic_suggestion.png', title: translation(context).lbl_suggestions));
  list.add(SVDrawerModel(image: 'assets/icon/ic_setting.png', title: 'App Setting'));
  // list.add(SVDrawerModel(image: 'assets/icon/ic_Send.png', title: translation(context).lbl_share_app));
  list.add(SVDrawerModel(image: 'assets/icon/ic_guidlines.png', title:"Privacy Policy" ));
  list.add(SVDrawerModel(image: 'assets/icon/ic_logout.png', title: translation(context).lbl_logout));
  list.add(SVDrawerModel(image: 'assets/icon/ic_logout.png', title:translation(context).lbl_delete_account));

  return list;
}
