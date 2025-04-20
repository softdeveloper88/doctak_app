import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/guidelines_model/guidelines_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_state.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../main.dart';
import 'bloc/guideline_event.dart';

class GuidelinesScreen extends StatefulWidget {
  const GuidelinesScreen({Key? key}) : super(key: key);

  @override
  State<GuidelinesScreen> createState() => _GuidelinesScreenState();
}

class _GuidelinesScreenState extends State<GuidelinesScreen> {
  Timer? _debounce;
  bool isSearchShow = true;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    guidelineBloc.add(
      LoadPageEvent(page: 1, searchTerm: ''),
    );
    super.initState();
  }

  var selectedValue;
  GuidelinesBloc guidelineBloc = GuidelinesBloc();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        surfaceTintColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Guidelines', style: boldTextStyle(size: 18)),
        actions: [
          InkWell(
            onTap: () {
              setState(() {});
              isSearchShow = !isSearchShow;
            },
            child: isSearchShow
                ? Icon(Icons.close,
                        size: 25,
                        // height: 16,
                        // width: 16,
                        // fit: BoxFit.cover,
                        color: svGetBodyColor())
                    .paddingLeft(4)
                : Image.asset(
                    'assets/images/search.png',
                    height: 20,
                    width: 20,
                    color: svGetBodyColor(),
                  ),
          ).paddingRight(16)
        ],
      ),

      body: Column(
        children: [
          if (isSearchShow)
            Container(
              color: svGetScaffoldColor(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.only(left: 8.0),

                  decoration: BoxDecoration(
                      color: context.dividerColor.withOpacity(0.4),
                      borderRadius: radius(5),
                      border: Border.all(color: svGetBodyColor(), width: 0.5)),
                  child: AppTextField(
                    onChanged: (searchTxt) async {
                      if (_debounce?.isActive ?? false) _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        guidelineBloc.add(
                          LoadPageEvent(
                            page: 1,
                            searchTerm: searchTxt,
                          ),
                        );
                        // guidelineBloc.add(SearchFieldData(
                        //    searchTxt,
                        // ));
                      });
                    },
                    textFieldType: TextFieldType.NAME,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search  ',
                      hintStyle: secondaryTextStyle(color: svGetBodyColor()),
                      suffixIcon: Image.asset('images/socialv/icons/ic_Search.png',
                              height: 16,
                              width: 16,
                              fit: BoxFit.cover,
                              color: svGetBodyColor())
                          .paddingAll(16),
                    ),
                  ),
                ),
              ),
            ),
          BlocConsumer<GuidelinesBloc, GuidelineState>(
            bloc: guidelineBloc,
            // listenWhen: (previous, current) => current is PaginationLoadedState,
            // buildWhen: (previous, current) => current is! PaginationLoadedState,
            listener: (BuildContext context, GuidelineState state) {
              if (state is DataError) {
                // showDialog(
                //   context: context,
                //   builder: (context) => AlertDialog(
                //     content: Text(state.errorMessage),
                //   ),
                // );
              }
            },
            builder: (context, state) {
              print("state $state");
              if (state is PaginationLoadingState) {
                return Expanded(
                    child:ShimmerCardList());
              } else if (state is PaginationLoadedState) {
                // print(state.drugsModel.length);
                // return _buildPostList(context);
                final bloc = guidelineBloc;
                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 16,right: 16,bottom: 16),
                    shrinkWrap: true,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (bloc.pageNumber <= bloc.numberOfPage) {
                        if (index ==
                            bloc.guidelinesList.length - bloc.nextPageTrigger) {
                          bloc.add(CheckIfNeedMoreDataEvent(index: index));
                        }
                      }
                      if( bloc.numberOfPage != bloc.pageNumber - 1 &&
                              index >= bloc.guidelinesList.length - 1
                      ) {
                        return SizedBox(
                            height: 300,
                            child: ShimmerCardList());
                      }
                      else if ((index % 5 == 0 && index != 0) &&
                          AppData.isShowGoogleNativeAds) {
                        return NativeAdWidget();
                      }else {
                        return _buildDiseaseAndGuidelinesItem(
                            bloc.guidelinesList[index]);
                      }

                      // SVProfileFragment().launch(context);
                    },
                    itemCount: bloc.guidelinesList.length,
                  ),
                );
              } else if (state is DataError) {
                return Expanded(
                  child: Center(
                    child: Text(state.errorMessage),
                  ),
                );
              } else {
                return const Expanded(
                    child: Center(child: Text('Something went wrong')));
              }
            },
          ),
          // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
      // SingleChildScrollView(
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Text('RECENT', style: boldTextStyle()).paddingAll(16),
      //       ListView.separated(
      //         padding: EdgeInsets.all(16),
      //         shrinkWrap: true,
      //         physics: NeverScrollableScrollPhysics(),
      //         itemBuilder: (context, index) {
      //           return SVSearchCardComponent(element: list[index]).onTap(() {
      //             // SVProfileFragment().launch(context);
      //           });
      //         },
      //         separatorBuilder: (BuildContext context, int index) {
      //           return Divider(height: 20);
      //         },
      //         itemCount: list.length,
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  Map<String, bool> expandedMap = {};

  Widget _buildDiseaseAndGuidelinesItem(Data item) {
    expandedMap[item.diseaseName!] ??= false;
    String description = item.description!
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .replaceAll('\u0002', ' ');
    // print(description);
    String trimmedDescription = _trimDescription(description, 100);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // boxShadow: [
        //   BoxShadow(
        //     color: svGetBodyColor().withOpacity(0.15),
        //     spreadRadius: 0,
        //     blurRadius: 10,
        //     offset: const Offset(0, 3),
        //   ),
        // ],
        color: appStore.isDarkMode ? context.cardColor : context.cardColor ,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              item.diseaseName ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: svGetBodyColor(),
              ),
            ),
            subtitle: GestureDetector(
              onTap: () {
                setState(() {
                  // Toggle expanded state
                  expandedMap[item.diseaseName ?? ''] =
                      !expandedMap[item.diseaseName]!;
                });
              },
              child: HtmlWidget(
                expandedMap[item.diseaseName]!
                    ? "<p>$description</p>"
                    : "<p>$trimmedDescription</p>",
              ),
              // Text(
              //   expandedMap[item.diseaseName]!
              //       ? description
              //       : trimmedDescription,
              //   style: TextStyle(
              //     color: themeProvider.themeMode == ThemeModeType.Dark
              //         ? Colors.white
              //         : Colors.grey[900],
              //   ),
              //   textAlign: TextAlign.justify, // Align the text to justify
              // ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                if (expandedMap[item.diseaseName]!) {
                  // If description is expanded, download the file
                  downloadAndOpenFile(
                      "${AppData.base}/guidelines/${item.fileName!}");
                } else {
                  // If description is not expanded, expand it
                  setState(() {
                    expandedMap[item.diseaseName ?? ''] = true;
                  });
                }
              },
              child: Text(
                expandedMap[item.diseaseName]! ? 'Download PDF' : 'See More',
                style:  TextStyle(fontFamily: 'Poppins',color: svGetBodyColor()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> downloadAndOpenFile(String url) async {
    try {
      final Uri fileUri = Uri.parse(url); // Convert the URL to a Uri object

      // Check if the URL can be launched

      await launchUrl(fileUri); // Launch the URL
    } catch (e) {
      // Handle errors or show an alert to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _trimDescription(String description, int wordLimit) {
    List<String> words = description.split(' ');
    if (words.length <= wordLimit) return description;
    return '${words.take(wordLimit).join(' ')}...';
  }
}
