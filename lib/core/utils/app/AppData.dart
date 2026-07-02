import 'package:doctak_app/core/utils/app/app_environment.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/data/models/ads_model/ads_setting_model.dart';
import 'package:doctak_app/data/models/ads_model/ads_type_model.dart';
import 'package:doctak_app/data/models/subscription/subscription_data_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/meeting_chat_screen.dart';
import 'package:flutter/foundation.dart';

class AppData {
  // URLs are now driven by AppEnvironment (debug = local, release = production)
  // Override with: flutter run --dart-define=ENV=production
  //           or: flutter run --dart-define=LOCAL_IP=192.168.1.100
  static String get base => AppEnvironment.base;
  static String get base2 => AppEnvironment.base2;
  static String get basePath => AppEnvironment.basePath;
  static String get imageUrl => AppEnvironment.imageUrl;
  static String get remoteUrl => AppEnvironment.apiUrl;
  static String get remoteUrl2 => AppEnvironment.apiUrl;
  static String get remoteUrl3 => AppEnvironment.apiUrl;
  static String get remoteUrlV6 => AppEnvironment.apiUrlV6;
  /// Base URL for doctak-node routes (/api/meetings, /api/notifications, etc.)
  static String get nodeApiUrl => AppEnvironment.nodeApiUrl;
  static String get userProfileUrl => AppEnvironment.userProfileUrl;
  static String get chatifyUrl => AppEnvironment.chatifyUrl;
  static String get chatApiUrl => AppEnvironment.chatApiUrl;

  /// Host markers for the legacy S3 bucket whose objects are now served through
  /// the R2 proxy (`/r2-media`). Direct S3 access returns 403 for newer keys, so
  /// every such URL must be rewritten onto [imageUrl].
  static const String _legacyS3Marker = 'amazonaws.com';
  static const String _legacyBucketHostPrefix = 'doctak-file';

  static bool _isLegacyObjectStorageHost(String host) {
    final h = host.toLowerCase();
    return h.contains(_legacyS3Marker) || h.startsWith(_legacyBucketHostPrefix);
  }

  static String? _extractLegacyStorageKey(Uri uri) {
    if (!_isLegacyObjectStorageHost(uri.host)) return null;
    var key = uri.path;
    if (uri.host.toLowerCase().startsWith('s3.') || uri.host.toLowerCase().startsWith('s3-')) {
      final segs = uri.pathSegments;
      if (segs.length > 1) key = '/${segs.sublist(1).join('/')}';
    }
    final normalized = key.startsWith('/') ? key.substring(1) : key;
    return normalized.isEmpty ? null : normalized;
  }

  /// Returns a full, R2-served image URL for a given [path].
  /// - null / empty / "null"            -> '' (callers render their fallback)
  /// - legacy S3 absolute URL           -> rewritten onto the R2 proxy [imageUrl]
  ///   (handles both virtual-hosted `<bucket>.s3...amazonaws.com/<key>` and
  ///    path-style `s3.<region>.amazonaws.com/<bucket>/<key>`; S3 query params dropped)
  /// - any other absolute URL           -> returned as-is (already on doctak.net / r2-media / data:)
  /// - relative path                    -> prepended with the R2 media base [imageUrl]
  static String fullImageUrl(String? path) {
    if (path == null) return '';
    final p = path.trim();
    if (p.isEmpty || p.toLowerCase() == 'null') return '';

    if (p.startsWith('http://') || p.startsWith('https://')) {
      final uri = Uri.tryParse(p);
      if (uri != null) {
        // Rewrite localhost/dev URLs onto the active API host so mobile builds
        // can load media that was saved with a local absolute URL.
        final host = uri.host.toLowerCase();
        if (host == 'localhost' ||
            host == '127.0.0.1' ||
            host == '0.0.0.0' ||
            host == '10.0.2.2' ||
            host == '[::1]') {
          if (uri.path.startsWith('/profile-media/') ||
              uri.path.startsWith('/r2-media/') ||
              uri.path.startsWith('/legacy-media/')) {
            return '$base2${uri.path}';
          }
        }

        if (_isLegacyObjectStorageHost(uri.host)) {
          final key = _extractLegacyStorageKey(uri);
          if (key != null) return _joinMedia(key);
        } else if (p.contains(_legacyS3Marker)) {
          final key = _extractLegacyStorageKey(uri);
          if (key != null) return _joinMedia(key);
        }
      }
      return p;
    }

    // Node-served media proxies (profile media, legacy disk files, R2 proxy).
    // In development the Next.js API returns these as host-relative paths
    // (e.g. /legacy-media/..., /r2-media/...); prefix the active node host
    // instead of nesting them under the R2 media base.
    if (p.startsWith('/profile-media/') || p.startsWith('profile-media/') ||
        p.startsWith('/legacy-media/') || p.startsWith('legacy-media/') ||
        p.startsWith('/r2-media/') || p.startsWith('r2-media/')) {
      final path = p.startsWith('/') ? p : '/$p';
      return '$base2$path';
    }

    return _joinMedia(p);
  }

  /// Returns true when [raw] resolves to a loadable http(s) image URL.
  static bool isValidHttpImageUrl(String? raw) {
    final url = fullImageUrl(raw);
    if (url.isEmpty || url.toLowerCase() == 'null') return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return false;
    if (uri.host.isEmpty) return false;
    return true;
  }

  /// Joins a relative media [key] onto the R2 media base [imageUrl] without
  /// producing a double slash.
  static String _joinMedia(String key) {
    final k = key.startsWith('/') ? key.substring(1) : key;
    return imageUrl.endsWith('/') ? '$imageUrl$k' : '$imageUrl/$k';
  }

  /// Resolves chat attachment URLs (voice, images, video) from doctak-node.
  /// Web uploads use `/api/chat/media/chat/{conversationId}/...` or bare `chat/...` keys.
  static String resolveChatMediaUrl(String? path) {
    if (path == null) return '';
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return '';

    String toChatApi(String key) {
      final normalized = key.replaceFirst(RegExp(r'^/+'), '').replaceFirst(RegExp(r'^public/'), '');
      final base = nodeApiUrl.endsWith('/') ? nodeApiUrl.substring(0, nodeApiUrl.length - 1) : nodeApiUrl;
      return '$base/api/chat/media/$normalized';
    }

    String? extractChatKey(String raw) {
      if (raw.startsWith('chat/')) {
        return raw.replaceFirst(RegExp(r'^/+'), '');
      }

      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        final uri = Uri.tryParse(raw);
        if (uri == null) return null;

        final apiIdx = uri.path.indexOf('/api/chat/media/');
        if (apiIdx >= 0) {
          final key = uri.path.substring(apiIdx + '/api/chat/media/'.length).replaceFirst(RegExp(r'^/+'), '');
          if (key.startsWith('chat/')) return key;
        }

        final chatMatch = RegExp(r'(?:^|/)((?:chat/\d+/.+))$').firstMatch(uri.path);
        if (chatMatch != null) return chatMatch.group(1);

        final r2Idx = uri.path.indexOf('/r2-media/');
        if (r2Idx >= 0) {
          final encoded = uri.path.substring(r2Idx + '/r2-media/'.length);
          final decoded = Uri.decodeComponent(encoded);
          if (decoded.startsWith('chat/')) return decoded;
        }
        return null;
      }

      var localPath = raw;
      if (!localPath.startsWith('/')) {
        if (localPath.startsWith('api/chat/media/')) {
          final key = localPath.substring('api/chat/media/'.length);
          return key.startsWith('chat/') ? key : null;
        }
        if (localPath.startsWith('profile-media/') || localPath.startsWith('r2-media/')) {
          localPath = '/$localPath';
        }
      }

      if (localPath.startsWith('/api/chat/media/')) {
        final key = localPath.substring('/api/chat/media/'.length).replaceFirst(RegExp(r'^/+'), '');
        if (key.startsWith('chat/')) return key;
      }
      if (localPath.startsWith('/profile-media/chat/')) {
        return localPath.replaceFirst('/profile-media/', '');
      }
      if (localPath.startsWith('/r2-media/')) {
        final decoded = Uri.decodeComponent(localPath.substring('/r2-media/'.length));
        if (decoded.startsWith('chat/')) return decoded;
      }

      final bare = raw.replaceFirst(RegExp(r'^/+'), '').replaceFirst(RegExp(r'^public/'), '').replaceFirst(RegExp(r'^profile-media/'), '');
      if (bare.startsWith('chat/')) return bare;
      return null;
    }

    final storageKey = extractChatKey(trimmed);
    if (storageKey != null) {
      return toChatApi(storageKey);
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final host = uri.host.toLowerCase();
        if (host == 'localhost' ||
            host == '127.0.0.1' ||
            host == '0.0.0.0' ||
            host == '10.0.2.2' ||
            host == '[::1]') {
          if (uri.path.startsWith('/api/chat/media/')) {
            return '$base2${uri.path}';
          }
          if (uri.path.startsWith('/profile-media/chat/')) {
            return toChatApi(uri.path.replaceFirst('/profile-media/', ''));
          }
        }
      }
      return trimmed;
    }

    if (trimmed.startsWith('/api/chat/media/') || trimmed.startsWith('api/chat/media/')) {
      final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
      return '$base2$path';
    }

    if (trimmed.startsWith('/profile-media/chat/')) {
      return toChatApi(trimmed.replaceFirst('/profile-media/', ''));
    }
    if (trimmed.startsWith('profile-media/chat/')) {
      return toChatApi(trimmed.replaceFirst('profile-media/', ''));
    }

    return fullImageUrl(trimmed);
  }

  /// Notifier that fires whenever the user's profile picture changes.
  /// Widgets can use [ValueListenableBuilder] to rebuild automatically.
  static final profilePicNotifier = ValueNotifier<String>('');

  /// Convenience getter for the current user's full profile pic URL.
  static String get profilePicUrl => fullImageUrl(profile_pic);

  /// Updates [profile_pic] everywhere: static var, [profilePicNotifier], and
  /// persists to SecureStorageService so the value survives app restart.
  static Future<void> updateProfilePic(String newPic) async {
    profile_pic = newPic;
    profilePicNotifier.value = fullImageUrl(newPic);
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      await prefs.setString('profile_pic', newPic);
    } catch (_) {}
  }

  /// Updates [background] (cover photo) and persists to SecureStorageService.
  static Future<void> updateBackground(String newBg) async {
    background = newBg;
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      await prefs.setString('background', newBg);
    } catch (_) {}
  }

  static String? userToken;
  static var name = "";
  static var email = "";
  static var profile_pic = "";
  static var specialty = "";
  static bool isVerified = false;
  static var phone = "";
  static var licenseNo = "";
  static var title = "";
  static var city = "";
  static var countryOrigin = "";
  static var college = "";
  static var clinicName = "";
  static var dob = "";
  static var practicingCountry = "";
  static var gender = "";
  static var logInUserId;
  static String background = "";
  static String userType = 'doctor';
  static String university = "";
  static String currency = "";
  static String countryName = "";
  static List<AdsTypeModel> listAdsType = [];
  static AdsSettingModel adsSettingModel = AdsSettingModel();

  // ===================== Subscription & Feature Data (v6) =====================
  static bool isPremium = false;
  static String accountType = 'free';
  static String? planName;
  static String? planSlug;
  static String? planExpiresAt;
  static int? daysRemaining;
  static bool autoRenew = false;
  static bool monetizationEnabled = false;
  static SubscriptionData? subscriptionData;
  static FeaturesMap? featuresMap;

  /// Check if user has access to a specific feature
  static bool hasFeatureAccess(String featureSlug) {
    return featuresMap?.hasAccess(featureSlug) ?? false;
  }

  /// Get feature details
  static FeatureAccess? getFeature(String featureSlug) {
    return featuresMap?.getFeature(featureSlug);
  }

  /// Populate subscription fields from a PostLoginDeviceAuthResp
  static void updateSubscriptionData(SubscriptionData? subscription, FeaturesMap? features) {
    if (subscription != null) {
      subscriptionData = subscription;
      isPremium = subscription.isPremium;
      accountType = subscription.accountType;
      planName = subscription.planName;
      planSlug = subscription.planSlug;
      planExpiresAt = subscription.planExpiresAt;
      daysRemaining = subscription.daysRemaining;
      autoRenew = subscription.autoRenew;
      monetizationEnabled = subscription.monetizationEnabled;
    }
    if (features != null) {
      featuresMap = features;
    }
  }

  /// Clear subscription data on logout
  static void clearVerificationData() {
    isVerified = false;
  }

  static void clearSubscriptionData() {
    isPremium = false;
    accountType = 'free';
    planName = null;
    planSlug = null;
    planExpiresAt = null;
    daysRemaining = null;
    autoRenew = false;
    monetizationEnabled = false;
    subscriptionData = null;
    featuresMap = null;
  }

  /// Ads Setting
  static bool? isShowGoogleBannerAds;
  static String? androidBannerAdsId;
  static String? iosBannerAdsId;

  /// Native Ads Setting
  static bool isShowGoogleNativeAds = false;
  static String? androidNativeAdsId;
  static String? iosNativeAdsId;
  static List<Message> chatMessages = [];

  /// Server-assigned UUIDs of messages already shown in the UI.
  /// Persists across bottom-sheet opens so re-fetching the full history
  /// never adds duplicates.
  static final Set<String> seenMessageIds = {};

  /// Incremented whenever a new chat message is added (sent or received).
  /// Widgets (e.g. the chat bottom sheet) can listen to this notifier to
  /// rebuild without re-fetching the full history.
  static final ValueNotifier<int> chatMessagesNotifier = ValueNotifier(0);

  static String deviceToken = '';

  // LocalInvitation? _localInvitation;
  // RemoteInvitation? _remoteInvitation;
  // static AgoraRtmClient? _client;
  //
  // static AgoraRtmChannel? _channel;
  //
  //
  //
  //
  // static Future<void> initializeClient() async {
  //   // Create a local variable _client to store the AgoraRtmClient instance
  //   AgoraRtmClient? _client;
  //
  //   // Initialize _client
  //   _client = (await AgoraRtmClient.createInstance('f2cf99f1193a40e69546157883b2159f'));
  //   await _client?.setParameters('{"rtm.log_filter": 15}');
  //   await _client?.setLogFile('');
  //   await _client?.setLogFilter(RtmLogFilter.info);
  //   await _client?.setLogFileSize(10240);
  //
  //   // Log in to the client using AppData.logInUserId
  //   await _client?.login(null, AppData.logInUserId);
  //
  //   // Assign _client to the static property in AppData
  //   _client = _client;
  // }
}
