import 'package:flutter/cupertino.dart';

import '../../../localization/app_localization.dart';

class SVDrawerModel {
  String? title;
  String? image;

  SVDrawerModel({this.image, this.title});
}

List<SVDrawerModel> getDrawerOptions(BuildContext context) {
  List<SVDrawerModel> list = [];
  list.add(SVDrawerModel(image: 'assets/icon/ic_guidlines.png', title: translation(context).lbl_about_us));
  list.add(SVDrawerModel(image: 'assets/images/docktak_ai_light.png', title: translation(context).lbl_medical_ai));
  list.add(SVDrawerModel(image: 'assets/icon/ic_jobs.png', title: translation(context).lbl_jobs));
  list.add(SVDrawerModel(image: 'assets/icon/ic_drugs.png', title: translation(context).lbl_drug_list));
  list.add(SVDrawerModel(image: 'assets/icon/ic_discussion.png', title: translation(context).lbl_case_discussion));
  list.add(SVDrawerModel(image: 'assets/icon/ic_poll.png', title: translation(context).lbl_post_poll));
  list.add(SVDrawerModel(image: 'assets/images/img_group.png', title: translation(context).lbl_groups_formation));
  list.add(SVDrawerModel(image: 'assets/icon/ic_guidlines.png', title: translation(context).lbl_guidelines));
  list.add(SVDrawerModel(image: 'assets/icon/ic_conference.png', title: translation(context).lbl_conference));
  list.add(SVDrawerModel(image: 'assets/icon/ic_moh.png', title: translation(context).lbl_moh_update));
  list.add(SVDrawerModel(image: 'assets/icon/ic_discussion.png', title: translation(context).lbl_meeting));
  list.add(SVDrawerModel(image: 'assets/icon/ic_cme.png', title: translation(context).lbl_CME));
  list.add(SVDrawerModel(image: 'assets/icon/ic_discount.png', title: translation(context).lbl_discounts));
  list.add(SVDrawerModel(image: 'assets/icon/ic_suggestion.png', title: translation(context).lbl_suggestions));
  list.add(SVDrawerModel(image: 'assets/icon/ic_setting.png', title: translation(context).lbl_app_settings));
  // list.add(SVDrawerModel(image: 'assets/icon/ic_Send.png', title: translation(context).lbl_share_app));
  list.add(SVDrawerModel(image: 'assets/images/privacy.png', title: translation(context).lbl_privacy_policy));
  list.add(SVDrawerModel(image: 'assets/icon/ic_logout.png', title: translation(context).lbl_logout));
  // list.add(SVDrawerModel(image: 'assets/icon/ic_logout.png', title: translation(context).lbl_delete_account));

  return list;
}
