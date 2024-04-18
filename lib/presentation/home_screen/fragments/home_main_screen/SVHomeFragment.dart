import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVHomeDrawerComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVPostComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVStoryComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/components/user_chat_component.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/user_chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../ads_setting/ads_widget/banner_ads_widget.dart';
import '../../../../localization/app_localization.dart';
import '../../../chat_gpt_screen/ChatDetailScreen.dart';
import 'bloc/home_bloc.dart';

class SVHomeFragment extends StatefulWidget {
  SVHomeFragment({Key? key}) : super(key: key);

  @override
  State<SVHomeFragment> createState() => _SVHomeFragmentState();
}

class _SVHomeFragmentState extends State<SVHomeFragment> {
//   @override
  var scaffoldKey = GlobalKey<ScaffoldState>();

  HomeBloc homeBloc = HomeBloc();
  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    homeBloc.add(PostLoadPageEvent(page: 1));
    homeBloc.add(AdsSettingEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    afterBuildCreated(() {
      setStatusBarColor(svGetScaffoldColor());
    });
    return Scaffold(
        // resizeToAvoidBottomInset: false,
        key: scaffoldKey,
        backgroundColor: svGetScaffoldColor(),
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          elevation: 0,
          leading: IconButton(
            icon: Image.asset(
              'images/socialv/icons/ic_More.png',
              width: 18,
              height: 18,
              fit: BoxFit.cover,
              color: context.iconColor,
            ),
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Text(translation(context).lbl_home,
              style: boldTextStyle(size: 18)),
          actions: [
            TextButton(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.lightBlue,
                  borderRadius: BorderRadius.all(Radius.circular(10))
                  
                ),
                  child:  const Text("ChatGPT",style:TextStyle(color: Colors.white,fontWeight: FontWeight.bold),)),
              // color: context.cardColor,
              // icon: Image.asset(
              //   'assets/images/chatgpt.png',
              //   width: 30,
              //   height: 30,
              //   fit: BoxFit.fill,
              //   color: context.iconColor,
              // ),
              onPressed: () async {
                const ChatDetailScreen().launch(context);
              },
            ),
            IconButton(
              color: context.cardColor,
              icon:
              // Image.asset('assets/images/chat.png',height: 24,width: 24,
                Icon(CupertinoIcons.chat_bubble_2,
                size: 30,
                color: context.iconColor,
              ),
              onPressed: () async {
                UserChatScreen().launch(context);
              },
            ),
          ],
        ),
        drawer:  SVHomeDrawerComponent(),

        body: CustomScrollView(
            shrinkWrap: true,
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              // SliverList(delegate: SliverChildListDelegate([
              //
              //   // SVStoryComponent(),
              //   // 10.height,
              // ])),
              SliverList(
                  delegate: SliverChildListDelegate([
                UserChatComponent(),
                // 10.height,
              ])),
              SliverList(
                  delegate: SliverChildListDelegate([
                SVPostComponent(homeBloc),
              ])),
            ]));
    // body: Column(
    //   crossAxisAlignment: CrossAxisAlignment.stretch,
    //   children: [
    //     16.height,
    //     SVStoryComponent(),
    //     10.height,
    //     UserChatComponent(),
    //     10.height,
    //     Expanded(child: SVPostComponent(homeBloc)),
    //     16.height,
    //   ],
    // ));
  }
}
