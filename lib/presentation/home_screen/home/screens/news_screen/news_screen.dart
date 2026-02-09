import 'dart:convert';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/data/models/news_model/news_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/news_screen/bloc/news_state.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/AnimatedBackground.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';

import 'bloc/news_bloc.dart';
import 'bloc/news_event.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final bbcUrl = Uri.parse("${AppData.remoteUrl}/bbc-news");
    final cnnUrl = Uri.parse("${AppData.remoteUrl}/cnn-news");

    final headers = <String, String>{
      'Authorization': 'Bearer ${AppData.userToken}',
      // Add the token as a bearer token
    };

    try {
      final bbcResponse = await http.get(bbcUrl, headers: headers);
      final cnnResponse = await http.get(cnnUrl, headers: headers);

      if (bbcResponse.statusCode == 200 && cnnResponse.statusCode == 200) {
        final bbcData = json.decode(bbcResponse.body) as List<dynamic>;
        final cnnData = json.decode(cnnResponse.body) as List<dynamic>;

        setState(() {
          // bbcNews = bbcData.cast<Map<String, dynamic>>();
          // cnnNews = cnnData.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        // Handle API request errors
        // You can show an error message or perform other error handling here.
      }
    } catch (e) {
      // Handle network or decoding errors
      // You can show an error message or perform other error handling here.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NewsBloc()..add(GetPost(newsChannel: 'bbc-news')),
      child: Scaffold(
        backgroundColor: svGetScaffoldColor(),
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios),
          ),
          backgroundColor: svGetScaffoldColor(),
          iconTheme: IconThemeData(color: context.iconColor),
          title: Text(translation(context).lbl_world_news, style: boldTextStyle(size: 18)),
          elevation: 0,
          centerTitle: true,
          actions: const [
            // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
          ],
        ),
        body: DefaultTabController(
          length: 2,
          child: Scaffold(
            body: AnimatedBackground(
              child: Column(
                children: <Widget>[
                  Material(
                    color: context.cardColor, // Set the color of the TabBar
                    child: TabBar(
                      labelColor: svGetBodyColor(),
                      // Set the color of the selected tab text
                      unselectedLabelColor: Colors.grey,
                      // Set the color of the unselected tab text
                      indicatorColor: svGetBodyColor(),

                      // Set the color of the tab indicator
                      tabs: [
                        Tab(text: translation(context).lbl_bbc_news),
                        Tab(text: translation(context).lbl_cnn_news),
                      ],
                    ),
                  ),
                  BlocBuilder<NewsBloc, NewsState>(
                    builder: (context, state) {
                      print("state $state");
                      if (state is PaginationLoadingState) {
                        return Expanded(child: ShimmerCardList());
                      } else if (state is PaginationLoadedState) {
                        // print(state.drugsModel.length);
                        print(state.bbcNews.toList());

                        return Expanded(child: TabBarView(children: [buildNewsTab(state.bbcNews), buildNewsTab(state.cnnNews)]));
                      } else if (state is DataError) {
                        return Expanded(child: Center(child: Text(state.errorMessage)));
                      } else {
                        return Expanded(child: Center(child: Text(translation(context).msg_something_went_wrong)));
                      }
                    },
                  ),
                  // if (AppData.isShowGoogleBannerAds ?? false)
                  //   BannerAdWidget()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNewsTab(List<NewsModel> news) {
    return news.isEmpty
        ? Center(child: Text(translation(context).msg_no_news_found))
        : ListView.builder(
            itemCount: news.length,
            itemBuilder: (context, index) {
              final article = news[index];
              bool hasDescription = article.description != null && article.description.toString().trim().isNotEmpty;

              // Only build the Card if there is a description
              if (hasDescription) {
                return Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(10.0),
                        leading: article.link != null ? CustomImageView(imagePath: article.link ?? '', width: 100.0, fit: BoxFit.cover) : null,
                        title: Text(article.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(article.description ?? ''),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(child: Text(translation(context).lbl_read_more), onPressed: () => _launchURL(article.link ?? '')),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                );
              } else {
                // Return an empty container if there is no description
                return Container();
              }
            },
          );
  }

  Future<void> _launchURL(String urlString) async {
    await PostUtils.launchURL(context, urlString);
  }
}
