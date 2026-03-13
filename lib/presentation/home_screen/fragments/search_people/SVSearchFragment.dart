import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/search_people.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:flutter/material.dart';

class SVSearchFragment extends StatefulWidget {
  final Function? backPress;

  const SVSearchFragment({this.backPress, super.key});

  @override
  State<SVSearchFragment> createState() => _SVSearchFragmentState();
}

class _SVSearchFragmentState extends State<SVSearchFragment> {
  SearchPeopleBloc searchPeopleBloc = SearchPeopleBloc();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchPeopleBloc.add(SearchPeopleLoadPageEvent(page: 1, searchTerm: ''));
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchPeopleBloc.close();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    searchPeopleBloc.add(SearchPeopleLoadPageEvent(page: 1, searchTerm: query));
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakSearchableAppBar(
        title: translation(context).lbl_search_peoples,
        searchHint: translation(context).lbl_search_people,
        searchController: _searchController,
        onSearchChanged: _onSearchChanged,
        startWithSearch: true,
        showBackButton: true,
        onBackPressed: widget.backPress != null ? () => widget.backPress!() : null,
      ),
      body: SearchPeopleList(searchPeopleBloc: searchPeopleBloc),
    );
  }
}
