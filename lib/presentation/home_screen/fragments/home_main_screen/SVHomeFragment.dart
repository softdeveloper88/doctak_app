import 'package:doctak_app/presentation/home_screen/home/components/SVPostComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/components/user_chat_component.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/user_chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../localization/app_localization.dart';
import '../../../chat_gpt_screen/ChatDetailScreen.dart';
import '../../utils/SVColors.dart';
import 'bloc/home_bloc.dart';

class SVHomeFragment extends StatefulWidget {
  SVHomeFragment({required this.homeBloc, required this.openDrawer, Key? key})
      : super(key: key);
  Function openDrawer;
  HomeBloc homeBloc;

  @override
  State<SVHomeFragment> createState() => _SVHomeFragmentState();
}

class _SVHomeFragmentState extends State<SVHomeFragment> {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  // HomeBloc widget.homeBloc = HomeBloc();
  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    widget.homeBloc.add(PostLoadPageEvent(page: 1));
    widget.homeBloc.add(AdsSettingEvent());
    super.initState();
  }

  Future<void> _refresh() async {
    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      widget.homeBloc.add(PostLoadPageEvent(page: 1));
      widget.homeBloc.add(AdsSettingEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    afterBuildCreated(() {
      setStatusBarColor(svGetScaffoldColor());
    });
    return Scaffold(
        // resizeToAvoidBottomInset: false,
        key: scaffoldKey,
        backgroundColor: svGetBgColor(),
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
            onPressed: () => widget.openDrawer(),
          ),
          title: Text(translation(context).lbl_home,
              style: boldTextStyle(size: 18)),
          actions: [
            MaterialButton(
              textColor: Colors.black,
              // shapeBorder: RoundedRectangleBorder(borderRadius: radius(4),side: BorderSide()),
              // text: ' Artificial Intelligence ',
              // textStyle: secondaryTextStyle(color: Colors.white, size: 10),
              onPressed: () {
                 ChatDetailScreen(isFromMainScreen:true).launch(context);
              },
              elevation: 6,
              color: Colors.white,
              minWidth: 80,
              shape:  RoundedRectangleBorder(borderRadius: radius(4),side: const BorderSide(color: Colors.blue)),
              animationDuration: const Duration(milliseconds: 300),
              focusColor: SVAppColorPrimary,
              hoverColor: SVAppColorPrimary,
              splashColor: SVAppColorPrimary,
              height: 25,
              padding: const EdgeInsets.all(0),
              child: Text(" Artificial Intelligence ",style: GoogleFonts.poppins(color: Colors.black,fontWeight: FontWeight.w500,),),
            ),
            IconButton(
              color: context.cardColor,
              icon: Icon(
                CupertinoIcons.chat_bubble_2,
                size: 30,
                color: context.iconColor,
              ),
              onPressed: () async {
                UserChatScreen().launch(context);
              },
            ),
          ],
        ),
        body: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
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
                    SVPostComponent(widget.homeBloc),
                  ])),
                ])));
  }
}
