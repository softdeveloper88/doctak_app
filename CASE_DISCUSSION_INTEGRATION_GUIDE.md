# Case Discussion Module Integration Guide

## Overview
This guide explains how to integrate the CaseDiscussionModule into your DocTak app's main.dart file.

## Current Setup
Your app already has a partial setup for case discussions in the MultiBlocProvider (line 700-706 in main.dart):

```dart
BlocProvider(
    create: (context) => DiscussionListBloc(
        repository: CaseDiscussionRepository(
            baseUrl: 'https://doctak.net',
            getAuthToken: () {
                return AppData.userToken ?? "";
            }),
    )),
```

## Required Changes

### 1. Add Missing BLoC Providers
You need to add the missing BLoCs (DiscussionDetailBloc and CreateDiscussionBloc) to your MultiBlocProvider. 

In `main.dart`, find the MultiBlocProvider (around line 683) and add these providers after the existing DiscussionListBloc:

```dart
// Existing DiscussionListBloc
BlocProvider(
    create: (context) => DiscussionListBloc(
        repository: CaseDiscussionRepository(
            baseUrl: 'https://doctak.net',
            getAuthToken: () {
                return AppData.userToken ?? "";
            }),
    )),

// ADD THESE TWO NEW PROVIDERS:
BlocProvider(
    create: (context) => DiscussionDetailBloc(
        repository: CaseDiscussionRepository(
            baseUrl: 'https://doctak.net',
            getAuthToken: () {
                return AppData.userToken ?? "";
            }),
    )),
BlocProvider(
    create: (context) => CreateDiscussionBloc(
        repository: CaseDiscussionRepository(
            baseUrl: 'https://doctak.net',
            getAuthToken: () {
                return AppData.userToken ?? "";
            }),
    )),
```

### 2. Add Required Imports
Add these imports at the top of main.dart (if not already present):

```dart
import 'package:doctak_app/presentation/case_discussion/bloc/discussion_detail_bloc.dart';
import 'package:doctak_app/presentation/case_discussion/bloc/create_discussion_bloc.dart';
```

### 3. Add Routes for Case Discussion Screens
In your routes map (around line 942), add these routes:

```dart
routes: {
  // ... existing routes ...
  
  // Add these case discussion routes:
  '/case_discussions': (context) => const DiscussionListScreen(),
  '/case_discussion_detail': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return DiscussionDetailScreen(caseId: args['caseId']);
  },
  '/create_case_discussion': (context) => const CreateDiscussionScreen(),
  
  // ... rest of existing routes ...
},
```

### 4. Add Import for Screens
Add this import at the top of main.dart:

```dart
import 'package:doctak_app/presentation/case_discussion/screens/discussion_list_screen.dart';
import 'package:doctak_app/presentation/case_discussion/screens/discussion_detail_screen.dart';
import 'package:doctak_app/presentation/case_discussion/screens/create_discussion_screen.dart';
```

### 5. Navigation Usage

To navigate to the case discussion module from anywhere in your app:

```dart
// Navigate to case discussions list
Navigator.pushNamed(context, '/case_discussions');

// Navigate to a specific case discussion
Navigator.pushNamed(
  context, 
  '/case_discussion_detail',
  arguments: {'caseId': 123}, // Replace with actual case ID
);

// Navigate to create new case discussion
Navigator.pushNamed(context, '/create_case_discussion');
```

### 6. Alternative: Using CaseDiscussionModule Widget

If you prefer to use the CaseDiscussionModule widget directly (for example, in a drawer item or tab):

```dart
// In your navigation drawer or wherever you want to show it:
ListTile(
  title: Text('Case Discussions'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaseDiscussionModule(
          baseUrl: 'https://doctak.net',
          getAuthToken: () => AppData.userToken ?? "",
        ),
      ),
    );
  },
),
```

## Important Notes

1. **Base URL**: Make sure to use the correct base URL for your API. The example uses 'https://doctak.net'.

2. **Auth Token**: The getAuthToken function should return the current user's authentication token. The example uses `AppData.userToken`.

3. **Repository Singleton**: Consider creating a singleton instance of CaseDiscussionRepository to avoid creating multiple instances:

```dart
// Create a singleton instance (optional optimization)
final caseDiscussionRepository = CaseDiscussionRepository(
  baseUrl: 'https://doctak.net',
  getAuthToken: () => AppData.userToken ?? "",
);

// Then use it in all BlocProviders:
BlocProvider(
  create: (context) => DiscussionListBloc(
    repository: caseDiscussionRepository,
  )),
```

4. **Error Handling**: The module includes error handling, but you may want to add global error handling or logging based on your app's requirements.

5. **Permissions**: Ensure users have appropriate permissions to access case discussions based on your app's user roles.

## Testing

After integration, test the following:

1. Navigate to the case discussions list
2. Create a new case discussion
3. View case discussion details
4. Add comments to a discussion
5. Like/unlike discussions and comments
6. Search and filter discussions

## Troubleshooting

If you encounter issues:

1. Check that all imports are correct
2. Verify the base URL and authentication token are valid
3. Ensure all BLoC providers are properly registered
4. Check the console for any error messages
5. Verify that the API endpoints match your backend implementation