import 'package:doctak_app/data/models/ads_model/ads_setting_model.dart';
import 'package:doctak_app/data/models/ads_model/ads_type_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/meeting_chat_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class AppData {
  // http://pharmadoc.net/
  static var base = "https://doctak.net/";
  static var base2 = "https://doctak.net";
  static var basePath = "https://doctak.net/public/";
  // FIXED: Changed to HTTPS for better compatibility with Android security restrictions
  static var imageUrl = "https://doctak-file.s3.ap-south-1.amazonaws.com/";
  static var remoteUrl = "https://doctak.net/api/v4";
  static var remoteUrl2 = "https://doctak.net/api/v4";
  static var remoteUrl3 = "https://doctak.net/api/v4";
  static var userProfileUrl = "https://doctak.net/";
  static const chatifyUrl = "https://doctak.net/chatify/api/";

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
