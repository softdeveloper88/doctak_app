
import 'package:doctak_app/data/models/ads_model/ads_setting_model.dart';
import 'package:doctak_app/data/models/ads_model/ads_type_model.dart';

class AppData {
  // https://pharmadoc.net/
  static var base = "https://doctak.net/";
  static var basePath = "https://doctak.net/public/";
  static var imageUrl = "https://doctak-file.s3.ap-south-1.amazonaws.com/";
  static var remoteUrl = "https://doctak.net/api/v1";
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
  static String background="";
  static String userType='doctor';
  static String university="";
  static String currency="";
  static String countryName="";
  static List<AdsTypeModel> listAdsType=[];
  static  AdsSettingModel adsSettingModel=AdsSettingModel();
  /// Ads Setting
  static bool? isShowGoogleBannerAds;
  static String? androidBannerAdsId;
  static String? iosBannerAdsId;
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
