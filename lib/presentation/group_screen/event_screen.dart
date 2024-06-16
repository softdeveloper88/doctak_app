import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../ads_setting/ads_widget/banner_ads_widget.dart';
import '../../core/utils/app/AppData.dart';
import '../home_screen/utils/SVColors.dart';

class EventsScreen extends StatefulWidget {
  EventsScreen( this.id, {super.key});
   String id;
  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
   TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }
  int selectIndex = 0;
  Widget _individualTab(String tabName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Tab(
            child: Text(tabName,style: GoogleFonts.poppins(color: svGetBodyColor()),),
          ),
        ),
        if (tabName == 'Upcoming Event')
          Container(
            height: 20,
            width: 1,
            decoration:  BoxDecoration(
                border: Border(
                    right: BorderSide(
                        color: svGetBodyColor(),
                        width: 1,
                        style: BorderStyle.solid))),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: svGetScaffoldColor(),
        backgroundColor: svGetScaffoldColor(),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Events',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: svGetScaffoldColor(),
            padding: const EdgeInsets.symmetric(
                horizontal: 2, vertical: 8),
            child: TabBar(
              controller: _tabController,
              dividerHeight: 1,
              dividerColor: Colors.grey,
              onTap: (index) {
                setState(() {
                  selectIndex = index;
                });
              },
              indicatorWeight: 4,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.all(4),
              indicatorColor: SVAppColorPrimary,
              tabs: [
                _individualTab('Upcoming Event'),
                _individualTab('Past Event'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  UpcomingEventsTab(),
                        Center(child: Text('Past Events')),
                  //
                 ]),
          ),
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget(),
          // Container(
          //   color: svGetScaffoldColor(),
          //   padding: const EdgeInsets.only(bottom: 10),
          //   child: Column(
          //     children: [
          //       const Divider(thickness: 0.3,color: Colors.grey,endIndent: 20,indent: 20,),
          //       TabBar(
          //         controller: _tabController,
          //         tabs: const [
          //           Tab(text: 'Upcoming Events'),
          //           Tab(text: 'Past Events'),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
          // Expanded(
          //   child: TabBarView(
          //     controller: _tabController,
          //     children: [
          //       UpcomingEventsTab(),
          //       const Center(child: Text('Past Events')),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

class UpcomingEventsTab extends StatelessWidget {
  const UpcomingEventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: const [
        EventCard(),
        EventCard(),
      ],
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomImageView(
                  imagePath: 'assets/images/img_event.png',
                  fit: BoxFit.cover,
                ),
              ), // Replace with your image asset
              const Positioned(
                top: 8.0,
                right: 8.0,
                child: Icon(Icons.favorite_border, color: Colors.black),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Medical Conference 2024',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(
                          'assets/images/img_avtar.png'), // Replace with your avatar asset
                    ),
                    CircleAvatar(
                      backgroundImage: AssetImage(
                          'assets/images/img_avtar.png'), // Replace with your avatar asset
                    ),
                    CircleAvatar(
                      backgroundImage: AssetImage(
                          'assets/images/img_avtar.png'), // Replace with your avatar asset
                    ),
                    SizedBox(width: 8.0),
                    Text('50 Participants'),
                    Spacer(),
                    Text('Free', style: TextStyle(color: Colors.green)),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16.0),
                    SizedBox(width: 4.0),
                    Text('July 15, 2024, 9:00 AM'),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16.0),
                    SizedBox(width: 4.0),
                    Text('Boston Medical Convention Center'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
