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

## Server-Side Configuration (CRITICAL)

For app links to work (open the app when a link is clicked), your web server must host verification files. Without these, links will always open in the browser instead of the app.

---

### ANDROID — `assetlinks.json`

**File**: `https://doctak.net/.well-known/assetlinks.json`

```json
[
  {
    "relation": [
      "delegate_permission/common.handle_all_urls"
    ],
    "target": {
      "namespace": "android_app",
      "package_name": "com.kt.doctak",
      "sha256_cert_fingerprints": [
        "E4:DE:91:CA:5B:A8:8B:48:32:3C:10:A7:0D:F8:89:0E:F5:DE:8B:20:59:D9:56:B1:2E:DD:5A:97:21:D5:A0:66"
      ]
    }
  }
]
```

**Server requirements for Android:**
1. Serve the file at **exactly** `https://doctak.net/.well-known/assetlinks.json`
2. Content-Type: `application/json`
3. Must be accessible over **HTTPS** (not HTTP)
4. **No redirects** — the URL must respond directly with a 200 status code (no 301/302 redirects)
5. File must be accessible without authentication
6. The `sha256_cert_fingerprints` must include ALL signing certificates:
   - **Release/Play Store signing key** (the one used by Google Play App Signing)
   - **Upload key** (the one you sign with locally)
   - **Debug key** (optional, for testing only)

**How to get your SHA256 fingerprints:**
```bash
# Debug key
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA256

# Upload/Release key  
keytool -list -v -keystore your-upload-key.jks -alias your-alias | grep SHA256

# Play Store App Signing key (from Google Play Console):
# Go to: Setup → App signing → App signing key certificate → SHA-256 fingerprint
```

> **IMPORTANT**: If you use Google Play App Signing (most apps do), the SHA256 from Play Console is the one that matters most for production. Add BOTH the Play Console SHA256 AND your upload key SHA256.

**Verify Android setup:**
```bash
# Google's verification tool (most reliable)
https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://doctak.net&relation=delegate_permission/common.handle_all_urls

# Force re-verify on device
adb shell pm set-app-links-allowed --package com.kt.doctak true

# Check verification status
adb shell pm get-app-links com.kt.doctak
```

---

### iOS — `apple-app-site-association` (AASA)

**File**: `https://doctak.net/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["588K7KH3K6.com.doctak.ios"],
        "components": [
          { "/": "/post/*" },
          { "/": "/job/*" },
          { "/": "/conference/*" },
          { "/": "/meeting/*" },
          { "/": "/call/*" },
          { "/": "/profile/*" }
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": ["588K7KH3K6.com.doctak.ios"]
  }
}
```

**Server requirements for iOS:**
1. Serve at **exactly** `https://doctak.net/.well-known/apple-app-site-association`
2. Content-Type: `application/json` (do **NOT** use `application/pkcs7-mime`)
3. Must be accessible over **HTTPS** with a valid TLS certificate
4. **No redirects** — Apple's CDN will reject files served with redirects
5. File must be **publicly accessible** (no auth, no captcha, no geo-blocking)
6. File size must be under 128 KB
7. The `appIDs` format is: `<TeamID>.<BundleID>` → `588K7KH3K6.com.doctak.ios`

**Verify iOS setup:**
```bash
# Apple's CDN validation (checks what Apple has cached)
curl -v "https://app-site-association.cdn-apple.com/a/v1/doctak.net"

# Direct check on your server
curl -v "https://doctak.net/.well-known/apple-app-site-association"

# Test on simulator
xcrun simctl openurl booted "https://doctak.net/post/123"
```

> **NOTE**: Apple caches the AASA file via their CDN. After updating, it can take **24-48 hours** to propagate. To force refresh during development, go to **Settings → Developer → Associated Domains Development** on the test device.

---

### Nginx Server Configuration Example

If you use Nginx, add this to your server block:

```nginx
# Serve .well-known files with correct headers
location /.well-known/assetlinks.json {
    default_type application/json;
    add_header Cache-Control "max-age=86400";
}

location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Cache-Control "max-age=86400";
}
```

### Apache Server Configuration Example

```apache
<Location "/.well-known/assetlinks.json">
    Header set Content-Type "application/json"
</Location>

<Location "/.well-known/apple-app-site-association">
    Header set Content-Type "application/json"
</Location>
```

### Laravel (if doctak.net backend is Laravel)

Add a route in `routes/web.php`:

```php
Route::get('/.well-known/assetlinks.json', function () {
    return response()->json([
        [
            'relation' => ['delegate_permission/common.handle_all_urls'],
            'target' => [
                'namespace' => 'android_app',
                'package_name' => 'com.kt.doctak',
                'sha256_cert_fingerprints' => [
                    'E4:DE:91:CA:5B:A8:8B:48:32:3C:10:A7:0D:F8:89:0E:F5:DE:8B:20:59:D9:56:B1:2E:DD:5A:97:21:D5:A0:66'
                ]
            ]
        ]
    ]);
});

Route::get('/.well-known/apple-app-site-association', function () {
    return response()->json([
        'applinks' => [
            'details' => [
                [
                    'appIDs' => ['588K7KH3K6.com.doctak.ios'],
                    'components' => [
                        ['/' => '/post/*'],
                        ['/' => '/job/*'],
                        ['/' => '/conference/*'],
                        ['/' => '/meeting/*'],
                        ['/' => '/call/*'],
                        ['/' => '/profile/*'],
                    ]
                ]
            ]
        ],
        'webcredentials' => [
            'apps' => ['588K7KH3K6.com.doctak.ios']
        ]
    ]);
});
```

---

### Fallback: Redirect to Play Store / App Store When App Not Installed

App Links / Universal Links only work when the app is installed. When the app is **not** installed, the link opens in the browser. Your server needs **fallback HTML pages** that detect the platform and redirect accordingly.

**Option A: Server-side route for each deep link path**

In your Laravel backend, add fallback routes:

```php
// routes/web.php — Fallback for all deep link paths
Route::get('/post/{id}', 'DeepLinkController@handleLink');
Route::get('/job/{id}', 'DeepLinkController@handleLink');
Route::get('/conference/{id}', 'DeepLinkController@handleLink');
Route::get('/meeting/{id}', 'DeepLinkController@handleLink');
Route::get('/call/{id}', 'DeepLinkController@handleLink');
Route::get('/profile/{id}', 'DeepLinkController@handleLink');
```

```php
// app/Http/Controllers/DeepLinkController.php
class DeepLinkController extends Controller
{
    public function handleLink(Request $request, $id = null)
    {
        $userAgent = $request->header('User-Agent', '');
        $currentUrl = $request->fullUrl();
        
        // If the app handled the link via App Links/Universal Links,
        // this page won't even load. This only fires when app is NOT installed.
        
        return view('deep-link-redirect', [
            'currentUrl' => $currentUrl,
            'playStoreUrl' => 'https://play.google.com/store/apps/details?id=com.kt.doctak',
            'appStoreUrl' => 'https://apps.apple.com/app/doctak/id YOUR_APP_STORE_ID',
            'webFallbackUrl' => 'https://doctak.net',
        ]);
    }
}
```

```html
<!-- resources/views/deep-link-redirect.blade.php -->
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Opening DocTak...</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: -apple-system, sans-serif; text-align: center; padding: 60px 20px; }
        .btn { display: inline-block; padding: 14px 32px; margin: 10px; border-radius: 8px; 
               text-decoration: none; color: white; font-size: 16px; }
        .android { background: #34A853; }
        .ios { background: #007AFF; }
        .web { background: #666; margin-top: 20px; }
    </style>
    <script>
        (function() {
            var ua = navigator.userAgent || '';
            var isAndroid = /android/i.test(ua);
            var isIOS = /iPad|iPhone|iPod/.test(ua);
            
            // Try custom scheme first (works if app is installed)
            var customSchemeUrl = 'doctak://open' + window.location.pathname + window.location.search;
            
            if (isAndroid) {
                // Android intent:// fallback — opens app or Play Store
                var intentUrl = 'intent://' + window.location.host + window.location.pathname + window.location.search
                    + '#Intent;scheme=https;package=com.kt.doctak;end';
                window.location = intentUrl;
            } else if (isIOS) {
                // Try universal link, then App Store
                setTimeout(function() {
                    window.location = '{{ $appStoreUrl }}';
                }, 2000);
                window.location = customSchemeUrl;
            }
        })();
    </script>
</head>
<body>
    <h2>Opening in DocTak App...</h2>
    <p>If the app doesn't open automatically:</p>
    <a href="{{ $playStoreUrl }}" class="btn android">Get it on Google Play</a>
    <a href="{{ $appStoreUrl }}" class="btn ios">Download on App Store</a>
    <br>
    <a href="{{ $webFallbackUrl }}" class="btn web">Continue on Web</a>
</body>
</html>
```

**Option B: Simple meta-redirect (static HTML)**

If you prefer static files, create an `index.html` inside each deep link folder:

```
doctak.net/post/index.html
doctak.net/job/index.html
...
```

**The Android `intent://` URI** is the most reliable fallback for Android — it will open the app if installed, or redirect to Play Store if not, all in one step.

---

### Checklist

| Step | Platform | Status |
|------|----------|--------|
| Host `/.well-known/assetlinks.json` on `doctak.net` | Android | ⬜ |
| Include BOTH Play Store signing key + upload key SHA256 | Android | ⬜ |
| Verify with Google Digital Asset Links API | Android | ⬜ |
| Host `/.well-known/apple-app-site-association` on `doctak.net` | iOS | ⬜ |
| `Content-Type: application/json` (no redirects) | Both | ⬜ |
| HTTPS with valid certificate | Both | ⬜ |
| Fallback HTML pages for store redirect | Both | ⬜ |
| Test `adb shell am start -d "https://doctak.net/post/123"` | Android | ⬜ |
| Test from iMessage/Notes with `https://doctak.net/post/123` | iOS | ⬜ |
| Wait 24-48h for Apple CDN to refresh AASA | iOS | ⬜ |

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

