# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app in debug mode
flutter run

# Build APK for Android
flutter build apk

# Build IPA for iOS
flutter build ios

# Run Flutter analyzer
flutter analyze

# Format code
flutter format lib/

# Clean build files
flutter clean
```

## App Architecture

DocTak is a Flutter app that follows a **BLoC (Business Logic Component)** architecture pattern with some MobX and Provider elements. It's a social networking platform for medical professionals with features for communication, content sharing, and professional resources.

### Key Architecture Components

1. **BLoC Pattern**: Business logic is separated into BLoC classes with events, states, and business logic components. Each feature has its own BLoC (e.g., `HomeBloc`, `LoginBloc`, `ProfileBloc`).

2. **State Management**:
   - Primary: BLoC pattern with flutter_bloc package
   - Secondary: MobX for some global state (AppStore)
   - Provider for simpler state management and dependency injection

3. **Navigation**:
   - Named routes with RouteGenerator
   - NavigatorService with global navigator key
   - Deep link handling for notifications

4. **API Communication**:
   - Retrofit for type-safe API calls
   - Dio for HTTP client functionality
   - NetworkInterceptor for auth tokens and error handling

5. **Real-time Features**:
   - Pusher Channels for real-time messaging
   - Firebase Messaging for push notifications
   - Agora SDK for video/audio calls

### Core Services

- **CallService & CallKitService**: Manage VoIP calls and native call integration
- **NotificationService**: Handle push notifications
- **PusherService**: Real-time event handling
- **AgoraService**: Video/audio conferencing
- **ApiService**: Central API client
- **ConnectivityService**: Network monitoring

### Main Features

- **Authentication**: Login/signup with social integration
- **Social Feed**: Posts, comments, likes, follows
- **Chat**: Real-time messaging
- **Video/Audio Calling**: One-on-one calls
- **ChatGPT Integration**: AI assistance
- **Meetings/Conferences**: Group video calls
- **Profiles**: User profiles with privacy settings
- **Groups**: Group creation and management
- **Professional Resources**: Jobs, guidelines, drug information
- **Case Discussions**: Medical case sharing

### Project Structure

- **/lib/presentation/**: UI components organized by feature
- **/lib/data/**: Data models and repositories
- **/lib/core/**: Core utilities and services
- **/lib/theme/**: App theming
- **/lib/widgets/**: Reusable widgets
- **/lib/routes/**: App navigation

## Tips for Working with this Codebase

1. **BLoC Implementation**: When adding a feature, create a new BLoC with event, state, and business logic classes following the existing pattern.

2. **Call Handling**: Call functionality is complex with multiple services interacting. Be careful when modifying CallService or CallKitService.

3. **Navigation**: Use the NavigatorService for navigation to ensure consistency.

4. **API Integration**: Use the existing ApiService and follow the repository pattern when adding new endpoints.

5. **Localization**: The app supports multiple languages. Add new strings to the appropriate .arb files in lib/l10n/.

6. **State Management**: For complex features, use BLoC; for simpler state, consider Provider.

7. **Firebase Services**: Firebase is used extensively for notifications, authentication, and crash reporting.

8. **Responsive Design**: Use the Sizer package for responsive layouts.

9. **Theme Consistency**: Follow the existing theme structure for UI consistency.

10. **Error Handling**: Use structured error handling with custom exceptions and Crashlytics logging.