import 'package:doctak_app/core/utils/app/app_environment.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/data/models/ads_model/ads_setting_model.dart';
import 'package:doctak_app/data/models/ads_model/ads_type_model.dart';
import 'package:doctak_app/data/models/subscription/subscription_data_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/meeting_chat_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class AppData {
  // URLs are now driven by AppEnvironment (debug = local, release = production)
  // Override with: flutter run --dart-define=ENV=production
  //           or: flutter run --dart-define=LOCAL_IP=192.168.1.100
  static var base = AppEnvironment.base;
  static var base2 = AppEnvironment.base2;
  static var basePath = AppEnvironment.basePath;
  static var imageUrl = AppEnvironment.imageUrl;
  static var remoteUrl = AppEnvironment.apiUrl;
  static var remoteUrl2 = AppEnvironment.apiUrl;
  static var remoteUrl3 = AppEnvironment.apiUrl;
  static var remoteUrlV6 = AppEnvironment.apiUrlV6;
  static var userProfileUrl = AppEnvironment.userProfileUrl;
  static var chatifyUrl = AppEnvironment.chatifyUrl;

  /// Returns a full image URL for a given path.
  /// If the path is already an absolute URL (http/https), returns it as-is.
  /// If it's a relative path, prepends the S3 base [imageUrl].
  /// Returns empty string for null/empty paths.
  static String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$imageUrl$path';
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

  static String deviceToken = '';

  static PusherChannelsFlutter? _pusherInstance;

  static PusherChannelsFlutter get pusher {
    if (_pusherInstance == null) {
      throw Exception('Pusher not initialized. Call initializePusherIfNeeded() first.');
    }
    return _pusherInstance!;
  }

  // Lazily initialize Pusher with retry mechanism when first needed
  static Future<void> initializePusherIfNeeded() async {
    if (isPusherInitialized && _pusherInstance != null) return;

    const int maxRetries = 5;
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      try {
        print("Pusher initialization attempt $attempt of $maxRetries");

        // Add delay before first attempt and between retries
        if (attempt > 1) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
        }

        _pusherInstance = PusherChannelsFlutter.getInstance();

        await _pusherInstance!.init(
          apiKey: PusherConfig.key,
          cluster: PusherConfig.cluster,
          onConnectionStateChange: onConnectionStateChange,
          onError: onError,
          onSubscriptionSucceeded: onSubscriptionSucceeded,
          onEvent: onEvent,
        );

        await _pusherInstance!.connect();
        isPusherInitialized = true;
        print("Pusher initialized successfully on attempt $attempt");
        return;
      } catch (e) {
        print("Error initializing Pusher (attempt $attempt): $e");
        _pusherInstance = null;

        if (attempt >= maxRetries) {
          print("Failed to initialize Pusher after $maxRetries attempts");
          isPusherInitialized = false;
          // Don't rethrow - allow app to continue without Pusher
        }
      }
    }
  }

  // Callback functions
  static void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print("Connection: $currentState from $previousState");
  }

  static void onError(String message, int? code, dynamic e) {
    print("Error: $message code: $code exception: $e");
  }

  static void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("Subscription succeeded: $channelName data: $data");
  }

  static void onEvent(dynamic event) {
    print("Event received: $event");
  }

  static bool isPusherInitialized = false;

  // Optional map to track active subscriptions
  static final Map<String, bool> _activeChannels = {};

  // Helper method to check if channel is already subscribed
  static bool isChannelActive(String channelName) {
    return _activeChannels[channelName] == true;
  }

  // Mark channel as active
  static void markChannelActive(String channelName) {
    _activeChannels[channelName] = true;
  }

  // Mark channel as inactive
  static void markChannelInactive(String channelName) {
    _activeChannels.remove(channelName);
  }

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
