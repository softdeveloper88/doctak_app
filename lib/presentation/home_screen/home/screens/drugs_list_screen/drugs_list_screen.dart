import 'dart:async';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_state.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('Drugs List', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        actions: const [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
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
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 8.0),
                      margin: const EdgeInsets.only(
                          left: 16, top: 16.0, bottom: 16.0),
                      decoration: BoxDecoration(
                          color: context.cardColor, borderRadius: radius(8)),
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
                                    state.searchTerms ?? '',
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
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CustomDropdownButtonFormField(
                      items: list1,
                      value: list1.first,
                      width: 100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      onChanged: (String? newValue) {
                        print(newValue);
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
                                newValue ?? "Brand",
                                state.searchTerms ?? '',
                                ''));
                        drugsBloc.add(LoadPageEvent(
                            page: 1,
                            countryId: state.countryFlag != ''
                                ? state.countryFlag
                                : '${state.countriesModel.countries?.first.id ?? 1}',
                            searchTerm: state.searchTerms ?? '',
                            type: newValue!));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomDropdownField(
                      items: state.countriesModel.countries ?? [],
                      value: state.countriesModel.countries!.first.flag,
                      width: 50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      onChanged: (String? newValue) {
                        print("ddd ${state.countryFlag}");
                        var index = state.countriesModel.countries!
                            .indexWhere((element) => newValue == element.flag);
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
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
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
        ],
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    final bloc = drugsBloc;
    print("bloc$bloc");
    print("len${bloc.drugsData.length}");
    return Expanded(
      child: ListView.builder(
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
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bloc.drugsData[index].tradeName ?? "",
                        style: secondaryTextStyle(
                            color: svGetBodyColor(), size: 18),
                      ),
                      const SizedBox(height: 5),
                      Text(bloc.drugsData[index].genericName ?? 'N/A',
                          style: secondaryTextStyle(color: svGetBodyColor())),
                      const SizedBox(height: 5),
                      Text(bloc.drugsData[index].strength ?? 'N/A',
                          style: secondaryTextStyle(color: svGetBodyColor())),
                      const SizedBox(height: 10),
                      Text(bloc.drugsData[index].manufacturerName ?? 'N/A',
                          style: secondaryTextStyle(color: svGetBodyColor())),
                      const SizedBox(height: 5),
                      Text(
                          "${bloc.drugsData[index].mrp ?? '0'} ${AppData.currency}",
                          style: secondaryTextStyle(color: svGetBodyColor())),
                    ],
                  ),
                );
          // return PostItem(bloc.drugsData[index].title, bloc.posts[index].body);
        },
      ),
    );
  }
}
