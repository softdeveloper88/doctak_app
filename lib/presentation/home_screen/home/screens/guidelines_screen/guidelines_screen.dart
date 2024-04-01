import 'dart:async';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/guidelines_model/guidelines_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_state.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bloc/guideline_event.dart';

class GuidelinesScreen extends StatefulWidget {
  const GuidelinesScreen({Key? key}) : super(key: key);

  @override
  State<GuidelinesScreen> createState() => _GuidelinesScreenState();
}

class _GuidelinesScreenState extends State<GuidelinesScreen> {
  Timer? _debounce;

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
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
          elevation: 0,
          backgroundColor: svGetScaffoldColor(),
          title: Container(
            padding: const EdgeInsets.only(left: 8.0),

                  decoration: BoxDecoration(
                      color: context.cardColor, borderRadius: radius(8)),
                  child: AppTextField(
                    onChanged: (searchTxt) async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce =
    Timer(const Duration(milliseconds: 500), ()
    {
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
                      hintText: 'Search Here ',
                      hintStyle: secondaryTextStyle(color: svGetBodyColor()),
                      suffixIcon: Image.asset(
                          'images/socialv/icons/ic_Search.png',
                          height: 16,
                          width: 16,
                          fit: BoxFit.cover,
                          color: svGetBodyColor())
                          .paddingAll(16),
                    ),
                  ),
                )
              ),
      body: Column(
        children: [
          BlocConsumer<GuidelinesBloc, GuidelineState>(
            bloc: guidelineBloc,
            // listenWhen: (previous, current) => current is PaginationLoadedState,
            // buildWhen: (previous, current) => current is! PaginationLoadedState,
            listener: (BuildContext context, GuidelineState state) {
              if (state is DataError) {
                showDialog(
                  context: context,
                  builder: (context) =>
                      AlertDialog(
                        content: Text(state.errorMessage),
                      ),
                );
              }
            },
            builder: (context, state) {
              print("state $state");
              if (state is PaginationLoadingState) {
                return const Expanded(
                    child: Center(child: CircularProgressIndicator()));
              } else if (state is PaginationLoadedState) {
                // print(state.drugsModel.length);
                // return _buildPostList(context);
                final bloc = guidelineBloc;
                return Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      if(bloc.pageNumber <= bloc.numberOfPage) {
                        if (index == bloc.guidelinesList.length -
                            bloc.nextPageTrigger) {
                          bloc.add(CheckIfNeedMoreDataEvent(index: index));
                        }
                      }
                      return bloc.numberOfPage != bloc.pageNumber - 1 &&
                          index >= bloc.guidelinesList.length - 1
                          ? const Center(
                        child: CircularProgressIndicator(),
                      )
                          : _buildDiseaseAndGuidelinesItem(
                          bloc.guidelinesList[index]);

                      // SVProfileFragment().launch(context);
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider(height: 20);
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
    String description = item.description!.replaceAll('\r', '').replaceAll(
        '\n', '').replaceAll('\u0002', ' ');
    // print(description);
    String trimmedDescription = _trimDescription(description, 100);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
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
                color: Colors.black,
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
              child: Html(
                data: expandedMap[item.diseaseName]!
                    ? "<p>$description</p>"
                    : "<p>$trimmedDescription</p>",
                style: {
                  '#': Style(
                    fontFamily: "Robotic",
                    textAlign: TextAlign.justify,
                    color: Colors.grey[900],
                  ),
                },
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
            alignment: Alignment.centerRight,
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
                  expandedMap[item.diseaseName]! ? 'Download PDF' : 'See More'),
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
