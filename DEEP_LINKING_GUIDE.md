# Deep Linking Implementation Guide

This document describes the deep linking implementation for the DocTak app using the `app_links` package (v7.0.0).

## Overview

Deep linking allows users to share content from the app (posts, jobs, meetings, etc.) via WhatsApp or other mediums, and when another user clicks the link, they are automatically redirected to the specific screen in the app.

## Supported Deep Link Types

| Type | URL Pattern | Target Screen |
|------|-------------|---------------|
| Post | `https://doctak.net/post/{postId}` | PostDetailsScreen |
| Job | `https://doctak.net/job/{jobId}` | JobsDetailsScreen |
| Conference | `https://doctak.net/conference/{conferenceId}` | ConferencesScreen |
| Meeting | `https://doctak.net/meeting/{meetingId}` | Dashboard (Meetings Tab) |
| Call | `https://doctak.net/call/{callId}` | CallScreen |
| Profile | `https://doctak.net/profile/{userId}` | SVProfileFragment |

## Architecture

### DeepLinkService

The main service located at `lib/core/utils/deep_link_service.dart` handles all deep linking functionality:

```dart
// Global instance for easy access
final deepLinkService = DeepLinkService();

// Initialize (called in main.dart)
await deepLinkService.initialize();

// Get initial link (cold start)
final uri = await deepLinkService.getInitialLink();

// Listen for links while app is running
deepLinkService.listenForLinks((uri) {
  final deepLinkData = deepLinkService.parseDeepLink(uri);
  deepLinkService.handleDeepLink(context, deepLinkData);
});

// Parse a URI to get structured data
final deepLinkData = deepLinkService.parseDeepLink(uri);

// Handle navigation based on deep link data
await deepLinkService.handleDeepLink(context, deepLinkData);
```

### DeepLinkData Model

```dart
class DeepLinkData {
  final DeepLinkType type;      // post, job, conference, meeting, call, profile, unknown
  final String? id;             // The resource ID
  final Map<String, String> queryParams;  // Additional parameters
  final Uri originalUri;        // Original URI
}
```

## How to Share Content

### Share a Post

```dart
import 'package:doctak_app/core/utils/deep_link_service.dart';

// Share with system share sheet
await DeepLinkService.sharePost(
  postId: 123,
  title: 'My Medical Case Study',
);

// Or just get the link
final link = DeepLinkService.generatePostLink(123);
// Returns: https://doctak.net/post/123
```

### Share a Job

```dart
await DeepLinkService.shareJob(
  jobId: '456',
  title: 'Cardiologist Position',
  company: 'City Hospital',
  location: 'New York',
);

// Or just get the link
final link = DeepLinkService.generateJobLink('456');
// Returns: https://doctak.net/job/456
```

### Share a Conference

```dart
await DeepLinkService.shareConference(
  conferenceId: '789',
  title: 'International Cardiology Summit 2026',
  date: 'March 15-17, 2026',
  location: 'Dubai',
);
```

### Share a Meeting

```dart
await DeepLinkService.shareMeeting(
  meetingId: 'abc123',
  title: 'Team Standup',
  date: 'January 15, 2026',
  time: '10:00 AM',
);
```

## Legacy API (dynamic_link.dart)

For backward compatibility, the legacy `createDynamicLink` function still works:

```dart
import 'package:doctak_app/core/utils/dynamic_link.dart';

// Legacy method - still works but deprecated
await createDynamicLink(postTitle, postUrl, imageUrl);

// New helper methods
await createJobLink(jobId: '456', title: 'Job Title');
await createConferenceLink(conferenceId: '789', title: 'Conference');
await createMeetingLink(meetingId: 'abc123', title: 'Meeting');
```

## Platform Configuration

### Android (AndroidManifest.xml)

Intent filters are configured for all supported deep link paths:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="doctak.net" android:pathPrefix="/post/" />
</intent-filter>
<!-- Similar filters for /job/, /conference/, /meeting/, /call/, /profile/ -->
```

### iOS (Runner.entitlements)

Associated domains are configured:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:doctak.page.link</string>
    <string>applinks:doctak.net</string>
    <string>webcredentials:doctak.net</string>
</array>
```

## Server-Side Requirements

For deep links to work properly on iOS, you need to host an `apple-app-site-association` file at:
`https://doctak.net/.well-known/apple-app-site-association`

Example content:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.doctak.ios",
        "paths": ["/post/*", "/job/*", "/conference/*", "/meeting/*", "/call/*", "/profile/*"]
      }
    ]
  }
}
```

For Android, you need an `assetlinks.json` file at:
`https://doctak.net/.well-known/assetlinks.json`

Example content:
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.kt.doctak",
    "sha256_cert_fingerprints": ["YOUR_APP_SHA256_FINGERPRINT"]
  }
}]
```

## Handling Authentication

When a user clicks a deep link but is not logged in:

1. The deep link is stored as a "pending" link
2. User is redirected to login screen
3. After successful login, the pending deep link is processed
4. User is navigated to the intended screen

```dart
// Check if user is logged in
if (AppData.userToken == null) {
  deepLinkService.storePendingDeepLink(deepLinkData);
  // Redirect to login
} else {
  await deepLinkService.handleDeepLink(context, deepLinkData);
}

// After login, handle any pending deep link
await deepLinkService.handlePendingDeepLink(context);
```

## Testing Deep Links

### Android

```bash
# Test post deep link
adb shell am start -W -a android.intent.action.VIEW -d "https://doctak.net/post/123"

# Test job deep link
adb shell am start -W -a android.intent.action.VIEW -d "https://doctak.net/job/456"

# Test meeting deep link
adb shell am start -W -a android.intent.action.VIEW -d "https://doctak.net/meeting/abc123"
```

### iOS

Use Safari to open the links, or use the `xcrun simctl openurl` command:

```bash
xcrun simctl openurl booted "https://doctak.net/post/123"
```

## Troubleshooting

1. **Links not opening the app on Android**: Make sure `android:autoVerify="true"` is set and the `assetlinks.json` is correctly configured on the server.

2. **Links not opening the app on iOS**: Verify the `apple-app-site-association` file is correctly hosted and the Team ID matches.

3. **App opens but wrong screen**: Check the logs for parsing errors:
   ```
   🔗 DeepLinkService: Parsing URI: https://doctak.net/post/123
   🔗 DeepLinkService: Parsed result: DeepLinkData(type: post, id: 123, params: {})
   ```

4. **Deep link not working after fresh install**: On Android, app links verification may take some time. Test with `adb shell pm set-app-links-allowed --package com.kt.doctak true`.

## Share Button Integrations

The share functionality is integrated in the following screens:

### Posts
- **SVPostComponent** (`lib/presentation/home_screen/home/components/SVPostComponent.dart`) - Share button in post feed
- **PostDetailsScreen** (`lib/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart`) - Share button in post detail view

### Jobs
- **VirtualizedJobsList** (`lib/presentation/home_screen/home/screens/jobs_screen/widgets/virtualized_jobs_list.dart`) - Share button in job list items
- **JobsDetailsScreen** (`lib/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart`) - Share button in job detail app bar

### Conferences
- **MemoryOptimizedConferenceItem** (`lib/presentation/home_screen/home/screens/conferences_screen/memory_optimized_conference_item.dart`) - Share button in conference cards

### Meetings
- **ManageMeetingScreen** (`lib/presentation/home_screen/home/screens/meeting_screen/manage_meeting_screen.dart`) - Share dialog with multiple share options (Email, SMS, Copy, More)

## Meeting Auto-Join Flow

When a user clicks a shared meeting link, the app automatically:

1. **Opens ManageMeetingScreen** with the meeting code pre-filled
2. **Auto-triggers the join process** - starts joining immediately
3. **Shows loading** while waiting for the host to accept
4. **Listens for Pusher events**:
   - `new-user-allowed`: Navigates to VideoCallScreen
   - `new-user-rejected`: Shows rejection message
5. **Joins the meeting** when accepted by the host

### Code Flow

```dart
// Deep link received: https://doctak.net/meeting/MT-123456
// DeepLinkService parses and extracts meeting code

// Navigate to ManageMeetingScreen with auto-join
ManageMeetingScreen(
  meetingCode: 'MT-123456',
  autoJoin: true,
).launch(context);

// ManageMeetingScreen.initState() auto-triggers:
// 1. Pre-fills meeting code field
// 2. Calls _autoJoinMeeting()
// 3. _checkJoinStatus() sends join request
// 4. Pusher listens for host acceptance
// 5. On 'new-user-allowed' -> VideoCallScreen
```

### Manual Navigation with Auto-Join

You can also programmatically open the meeting screen with auto-join:

```dart
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/manage_meeting_screen.dart';

// Navigate with auto-join
ManageMeetingScreen(
  meetingCode: 'MT-123456',
  autoJoin: true,
).launch(context);

// Navigate with pre-filled code but no auto-join
ManageMeetingScreen(
  meetingCode: 'MT-123456',
  autoJoin: false,
).launch(context);
```

