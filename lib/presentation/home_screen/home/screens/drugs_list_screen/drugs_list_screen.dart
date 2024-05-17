import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_state.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/custom_dropdown_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import 'bloc/drugs_event.dart';
import 'bloc/drugs_state.dart';

class DrugsListScreen extends StatefulWidget {
  const DrugsListScreen({Key? key}) : super(key: key);

  @override
  State<DrugsListScreen> createState() => _DrugsListScreenState();
}

class _DrugsListScreenState extends State<DrugsListScreen> {
  Timer? _debounce;

  late final ScrollController _scrollController;
  DrugsBloc drugsBloc = DrugsBloc();

  @override
  void initState() {
    drugsBloc.add(
      LoadPageEvent(
          page: 1,
          countryId: AppData.countryName,
          searchTerm: '',
          type: 'Brand'),
    );
    super.initState();
    // _scrollController = ScrollController()..addListener(_onScroll);
  }
  var selectedValue;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
int selectedIndex=0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      body: Column(
        children: [
          BlocBuilder<SplashBloc, SplashState>(builder: (context, state) {
            if (state is CountriesDataInitial) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Center(child: CircularProgressIndicator()),
                ],
              );
            } else if (state is CountriesDataLoaded) {
              List<String> list1 = ['Brand', 'Active'];
              for (var element in state.countriesModel.countries!) {
                if (element.flag == state.countryFlag) {
                  selectedValue = state.countriesModel.countries?.first.flag ??
                      element.flag;
                }
              }
              return Column(
                children: [
                  AppBar(
                    backgroundColor: svGetScaffoldColor(),
                    iconTheme: IconThemeData(color: context.iconColor),
                    title: Row(
                      children: [
                        Expanded(child: Center(child: Text('Drugs List', style: boldTextStyle(size: 20)))),
                        Expanded(
                          child: CustomDropdownField(
                            items: state.countriesModel.countries ?? [],
                            value: state.countriesModel.countries!.first.countryName,
                            width: 50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            onChanged: (String? newValue) {
                              print("ddd ${state.countryFlag}");
                              var index = state.countriesModel.countries!
                                  .indexWhere((element) => newValue == element.countryName);
                              var countryId =
                                  state.countriesModel.countries![index].id;
                              // BlocProvider.of<DrugsBloc>(context).add(
                              //   GetPost(
                              //       page: '1',
                              //       countryId: countryId.toString(),
                              //       searchTerm: '',
                              //       type: state.typeValue),
                              // );
                              // countryId = countryIds.toString();
                              BlocProvider.of<SplashBloc>(context).add(
                                  LoadDropdownData(countryId.toString(),
                                      state.typeValue, state.searchTerms ?? '', ''));
                              drugsBloc.add(LoadPageEvent(
                                  page: 1,
                                  countryId: countryId.toString(),
                                  searchTerm: state.searchTerms ?? "",
                                  type: state.typeValue));
                          
                              // BlocProvider.of<DrugsBloc>(context)
                              //     .add(UpdateFirstDropdownValue(newValue!));
                            },
                          ),
                        ),

                      ],
                    ),
                    elevation: 0,
                    surfaceTintColor: Colors.white,

                    centerTitle: true,
                    leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.black),
                        onPressed:(){Navigator.pop(context);}
                    ),
                    actions: const [
                      // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 8.0),
                        margin: const EdgeInsets.only(
                          left: 16,
                          top: 8.0,
                          bottom: 0.0,
                          right: 16,
                        ),
                        decoration: BoxDecoration(
                            color: context.dividerColor.withOpacity(0.4),
                            borderRadius: radius(5),
                            border: Border.all(
                                color: Colors.black, width: 0.3)),
                        child: AppTextField(
                          textFieldType: TextFieldType.NAME,
                          onChanged: (searchTxt) async {
                            if (_debounce?.isActive ?? false) _debounce?.cancel();

                            _debounce =
                                Timer(const Duration(milliseconds: 500), () {
                              // BlocProvider.of<DrugsBloc>(context).add(
                              //   GetPost(
                              //       page: '1',
                              //       countryId: "1",
                              //       searchTerm: searchTxt,
                              //       type: state.typeValue),
                              // );
                              BlocProvider.of<SplashBloc>(context).add(
                                  LoadDropdownData(
                                      state.countryFlag,
                                      state.typeValue,
                                      searchTxt ?? '',
                                      ''));
                              drugsBloc.add(LoadPageEvent(
                                  page: 1,
                                  countryId: state.countryFlag != ''
                                      ? state.countryFlag
                                      : '${state.countriesModel.countries?.first.id ?? 1}',
                                  searchTerm: searchTxt,
                                  type: state.typeValue));
                            });
                            // BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(newValue,state.typeValue));
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search Here',
                            hintStyle:
                                secondaryTextStyle(color: svGetBodyColor()),
                            suffixIcon: Image.asset(
                                    'images/socialv/icons/ic_Search.png',
                                    height: 16,
                                    width: 16,
                                    fit: BoxFit.cover,
                                    color: svGetBodyColor())
                                .paddingAll(16),
                          ),
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.all(16.0),
                      //   child: CustomDropdownButtonFormField(
                      //     items: list1,
                      //     value: list1.first,
                      //     width: 100,
                      //     contentPadding: const EdgeInsets.symmetric(
                      //       horizontal: 10,
                      //       vertical: 0,
                      //     ),
                      //     onChanged: (String? newValue) {
                      //       print(newValue);
                      //       // BlocProvider.of<DrugsBloc>(context).add(
                      //       //   GetPost(
                      //       //       page: '1',
                      //       //       countryId: state.countryFlag,
                      //       //       searchTerm: '',
                      //       //       type: newValue!),
                      //       // );
                      //       BlocProvider.of<SplashBloc>(context).add(
                      //           LoadDropdownData(
                      //               state.countryFlag,
                      //               newValue ?? "Brand",
                      //               state.searchTerms ?? '',
                      //               ''));
                      //       drugsBloc.add(LoadPageEvent(
                      //           page: 1,
                      //           countryId: state.countryFlag != ''
                      //               ? state.countryFlag
                      //               : '${state.countriesModel.countries?.first.id ?? 1}',
                      //           searchTerm: state.searchTerms ?? '',
                      //           type: newValue!));
                      //     },
                      //   ),
                      // ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    selectedIndex = 0;
                                          // BlocProvider.of<DrugsBloc>(context).add(
                                          //   GetPost(
                                          //       page: '1',
                                          //       countryId: state.countryFlag,
                                          //       searchTerm: '',
                                          //       type: newValue!),
                                          // );
                                          BlocProvider.of<SplashBloc>(context).add(
                                              LoadDropdownData(
                                                  state.countryFlag,
                                                  "Brand",
                                                  state.searchTerms ?? '',
                                                  ''));
                                          drugsBloc.add(LoadPageEvent(
                                              page: 1,
                                              countryId: state.countryFlag != ''
                                                  ? state.countryFlag
                                                  : '${state.countriesModel.countries?.first.id ?? 1}',
                                              searchTerm: state.searchTerms ?? '',
                                              type: 'Brand'));
                                  },
                                  child: Text(
                                    'Brand',
                                    style: TextStyle(
                                      color: SVAppColorPrimary,
                                      fontSize: 14,
                                      fontWeight: selectedIndex == 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 2,
                                  width: context.width() / 2 - 10,
                                  color: selectedIndex == 0
                                      ? SVAppColorPrimary
                                      : SVAppColorPrimary.withOpacity(0.2),
                                ),
                              ],
                            ),
                            Center(
                                child: Container(
                                  color: Colors.grey,
                                  height: 30,
                                  width: 1,
                                )),
                            Column(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    selectedIndex = 1;
                                    BlocProvider.of<SplashBloc>(context).add(
                                        LoadDropdownData(
                                            state.countryFlag,
                                            "Active",
                                            state.searchTerms ?? '',
                                            ''));
                                    drugsBloc.add(LoadPageEvent(
                                        page: 1,
                                        countryId: state.countryFlag != ''
                                            ? state.countryFlag
                                            : '${state.countriesModel.countries?.first.id ?? 1}',
                                        searchTerm: state.searchTerms ?? '',
                                        type: 'Active'));
                                  },
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      color: SVAppColorPrimary,
                                      fontSize: 14,
                                      fontWeight: selectedIndex == 1
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 2,
                                  width: context.width() / 2 - 10,
                                  color: selectedIndex == 1
                                      ? SVAppColorPrimary
                                      : SVAppColorPrimary.withOpacity(0.2),
                                ),
                              ],
                            ),
                            16.height,
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else if (state is CountriesDataError) {
              BlocProvider.of<SplashBloc>(context).add(
                LoadDropdownData('', '', '', ''),
              );

              return Center(child: Text('Error: ${state.errorMessage}'));
            } else {
              BlocProvider.of<SplashBloc>(context).add(
                LoadDropdownData('', '', '', ''),
              );

              return const Center(child: Text('Unknown state'));
            }
          }),
          BlocConsumer<DrugsBloc, DrugsState>(
            bloc: drugsBloc,
            // listenWhen: (previous, current) => current is DrugsState,
            // buildWhen: (previous, current) => current is! DrugsState,
            listener: (BuildContext context, DrugsState state) {
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
              if (state is PaginationLoadingState) {
                return const Expanded(
                    child: Center(child: CircularProgressIndicator()));
              } else if (state is PaginationLoadedState) {
                // print(state.drugsModel.length);
                return _buildPostList(context);
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
          if(AppData.isShowGoogleBannerAds??false)BannerAdWidget()
        ],
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    final bloc = drugsBloc;

    return Expanded(
      child: bloc.drugsData.isEmpty?const Center(child: Text("No Drugs Found"),) : ListView.builder(
        itemCount: bloc.drugsData.length,
        itemBuilder: (context, index) {
          if (bloc.pageNumber <= bloc.numberOfPage) {
            if (index == bloc.drugsData.length - bloc.nextPageTrigger) {
              bloc.add(CheckIfNeedMoreDataEvent(index: index));
            }
          }
          return bloc.numberOfPage != bloc.pageNumber - 1 &&
                  index >= bloc.drugsData.length - 1
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Container(
                  margin: const EdgeInsets.symmetric(vertical: 5,horizontal: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bloc.drugsData[index].genericName ?? "",
                        style: GoogleFonts.poppins(color:Colors.black,fontSize:14.sp,fontWeight:FontWeight.w500),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(bloc.drugsData[index].strength ?? '',
                              style: GoogleFonts.poppins(color:Colors.black,fontSize:10.sp,fontWeight:FontWeight.w400)),
                          Text(' - ',
                              style: GoogleFonts.poppins(color:Colors.black,fontSize:10.sp,fontWeight:FontWeight.w400)),
                          Text(bloc.drugsData[index].packageSize ?? '',
                              style: GoogleFonts.poppins(color:Colors.black,fontSize:10.sp,fontWeight:FontWeight.w400)),

                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(bloc.drugsData[index].tradeName ?? 'N/A',
                          style: GoogleFonts.poppins(color:Colors.black,fontSize:10.sp)),
                      const SizedBox(height: 5),
                      const SizedBox(height: 10),
                       Divider(color: Colors.grey[300],),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Text('Manufacturer Name',style: GoogleFonts.poppins(color:Colors.grey,fontSize:12.sp),),
                                Text(bloc.drugsData[index].manufacturerName ?? '',
                                  style: GoogleFonts.poppins(color:Colors.black,fontSize:12.sp),),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text('Price',style: GoogleFonts.poppins(color:Colors.grey,fontSize:12.sp)),
                                  Text("${bloc.drugsData[index].mrp ?? '0'} ${AppData.currency}",
                                      style: GoogleFonts.poppins(color:Colors.black,fontSize:12.sp)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
          // return PostItem(bloc.drugsData[index].title, bloc.posts[index].body);
        },
      ),
    );
  }
}
