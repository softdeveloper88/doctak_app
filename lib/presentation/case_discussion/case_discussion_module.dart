import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

// Import all the files created above
import 'repository/case_discussion_repository.dart';
import 'bloc/discussion_list_bloc.dart';
import 'bloc/discussion_detail_bloc.dart';
import 'bloc/create_discussion_bloc.dart';
import 'screens/discussion_list_screen.dart';

class CaseDiscussionModule extends StatelessWidget {
  final String baseUrl;
  final String Function() getAuthToken;

  const CaseDiscussionModule({
    Key? key,
    required this.baseUrl,
    required this.getAuthToken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => CaseDiscussionRepository(
        baseUrl: baseUrl,
        getAuthToken: getAuthToken,
        dio: Dio(),
      ),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => DiscussionListBloc(
              repository: context.read<CaseDiscussionRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => DiscussionDetailBloc(
              repository: context.read<CaseDiscussionRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => CreateDiscussionBloc(
              repository: context.read<CaseDiscussionRepository>(),
            ),
          ),
        ],
        child: const DiscussionListScreen(),
      ),
    );
  }
}

// Usage in your main app:
/*
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CaseDiscussionModule(
        baseUrl: 'https://your-api-domain.com',
        getAuthToken: () => 'your_auth_token_here',
      ),
    );
  }
}
*/