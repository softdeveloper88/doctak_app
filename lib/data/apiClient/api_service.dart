import 'package:dio/dio.dart';
import 'package:doctak_app/data/models/ads_model/ads_setting_model.dart';
import 'package:doctak_app/data/models/ads_model/ads_type_model.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_ask_question_response.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'package:doctak_app/data/models/chat_model/contacts_model.dart';
import 'package:doctak_app/data/models/chat_model/message_model.dart';
import 'package:doctak_app/data/models/chat_model/search_contacts_model.dart';
import 'package:doctak_app/data/models/chat_model/send_message_model.dart';
import 'package:doctak_app/data/models/check_in_search_model/check_in_search_model.dart';
import 'package:doctak_app/data/models/conference_model/search_conference_model.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:doctak_app/data/models/guidelines_model/guidelines_model.dart';
import 'package:doctak_app/data/models/jobs_model/job_detail_model.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';
import 'package:doctak_app/data/models/news_model/news_model.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/data/models/profile_model/family_relationship_model.dart';
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/place_live_model.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:doctak_app/data/models/search_people_model/search_people_model.dart';
import 'package:doctak_app/data/models/search_user_tag_model/search_user_tag_model.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';

@RestApi(
    // baseUrl: "http://pharmadoc.net/api/v1") // replace with your API base URL
    baseUrl: "https://doctak.net/api/v1") // replace with your API base URL
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @FormUrlEncoded()
  @POST("/login")
  Future<PostLoginDeviceAuthResp> login(
      @Field("email") String username,
      @Field("password") String password,
      @Field("device_type") String deviceType,
      @Field("device_id") String deviceId);

  @FormUrlEncoded()
  @POST("/login")
  Future<PostLoginDeviceAuthResp> loginWithSocial(
    @Field("email") String username,
    @Field("first_name") String firstName,
    @Field("last_name") String lastName,
    @Field("device_type") String deviceType,
    @Field("device_id") String deviceId,
    @Field("isSocialLogin") bool isSocialLogin,
    @Field("provider") String provider,
    @Field("token") String token,
  );

  @FormUrlEncoded()
  @POST("/register")
  Future<HttpResponse<Map<String, String>>> register(
      @Field("first_name") String firstName,
      @Field("last_name") String lastName,
      @Field("email") String email,
      @Field("password") String password,
      @Field("user_type") String userType);

  @FormUrlEncoded()
  @POST("/complete-profile")
  Future<PostLoginDeviceAuthResp> completeProfile(
      @Header('Authorization') String token,
      @Field("first_name") String firstName,
      @Field("last_name") String lastName,
      @Field("country") String country,
      @Field("state") String state,
      @Field("phone") String phone,
      @Field("user_type") String userType);

  @FormUrlEncoded()
  @POST("/forgot_password")
  Future<HttpResponse> forgotPassword(@Field("email") String email);

  @FormUrlEncoded()
  @GET("/country-list")
  Future<CountriesModel> getCountries();

  @FormUrlEncoded()
  @GET("/get-states")
  Future<HttpResponse> getStates(@Query('country_id') String countryId);

  @FormUrlEncoded()
  @GET("/specialty")
  Future<HttpResponse> getSpecialty();

  @FormUrlEncoded()
  @GET("/universities/state/{statesId}")
  Future<HttpResponse> getUniversityByStates(@Path("statesId") String userId);

  @FormUrlEncoded()
  @GET("/posts")
  Future<PostDataModel> getPosts(
      @Header('Authorization') String token, @Query('page') String page);

  @FormUrlEncoded()
  @POST("/user-profile-post")
  Future<PostDataModel> getMyPosts(@Header('Authorization') String token,
      @Query('page') String page, @Query('user_id') String userId);

  @FormUrlEncoded()
  @GET("/jobs")
  Future<JobsModel> getJobsList(
      @Header('Authorization') String token,
      @Query('page') String page,
      @Query('country_id') String countryId,
      @Query('searchTerm') String searchTerm,
      @Query('expired_job') String expiredJob);

  @FormUrlEncoded()
  @POST("/jobs_detail")
  Future<JobDetailModel> getJobsDetails(
      @Header('Authorization') String token, @Query('job_id') String jobId);

  @FormUrlEncoded()
  @GET("/search-jobs")
  Future<JobsModel> getSearchJobsList(
    @Header('Authorization') String token,
    @Query('page') String page,
    @Query('country') String countryId,
    @Query('searchTerm') String searchTerm,
  );

  @FormUrlEncoded()
  @GET("/search-post")
  Future<PostDataModel> getSearchPostList(
    @Header('Authorization') String token,
    @Query('page') String page,
    @Query('search') String searchTerm,
  );

  @FormUrlEncoded()
  @GET("/drug-search")
  Future<DrugsModel> getDrugsList(
      @Header('Authorization') String token,
      @Query('page') String page,
      @Query('countryId') String countryId,
      @Query('searchTerm') String searchTerm,
      @Query('type') String type);

  @FormUrlEncoded()
  @GET("/searchPeople")
  Future<SearchPeopleModel> getSearchPeople(
      @Header('Authorization') String token,
      @Query('page') String page,
      @Query('searchTerm') String searchTerm);

  @FormUrlEncoded()
  @GET("/user/{userId}/{follow}")
  Future<HttpResponse> setUserFollow(@Header('Authorization') String token,
      @Path("userId") String userId, @Path("follow") String follow);

  //chat gpt api

  @FormUrlEncoded()
  @GET("/ask-question/{sessionId}/{question}")
  Future<ChatGptAskQuestionResponse> askQuestionFromGpt(
      @Header('Authorization') String token,
      @Path("sessionId") String sessionId,
      @Path("question") String question);

  @FormUrlEncoded()
  @GET("/gptChat-session")
  Future<ChatGptSession> gptChatSession(@Header('Authorization') String token);

  @FormUrlEncoded()
  @GET("/gptChat-history/{id}")
  Future<ChatGptMessageHistory> gptChatMessages(
      @Header('Authorization') String token, @Path('id') id);

  @FormUrlEncoded()
  @GET("/new-chat")
  Future<HttpResponse> newChat(@Header('Authorization') String token);

  @FormUrlEncoded()
  @GET("/delete-chatgpt-session")
  Future<HttpResponse> deleteChatgptSession(
      @Header('Authorization') String token, @Query('session_id') sessionId);

  @FormUrlEncoded()
  @GET("/conference-countries")
  Future<HttpResponse> getConferenceCountries(
      @Header('Authorization') String token);

  @FormUrlEncoded()
  @GET("/search-conferences")
  Future<SearchConferenceModel> searchConferences(
      @Header('Authorization') String token,
      @Query('page') String page,
      @Query('country') String country,
      @Query('search_term') String searchTerm);

  @FormUrlEncoded()
  @GET("/{news}")
  Future<List<NewsModel>> newsChannel(
      @Header('Authorization') String token, @Path('news') String news);

  @FormUrlEncoded()
  @GET("/guideline")
  Future<GuidelinesModel> guideline(@Header('Authorization') String token,
      @Query('page') String page, @Query('search_term') String searchTerm);

  ///search tag friends api
  @FormUrlEncoded()
  @GET("/search-users-for-tag")
  Future<SearchUserTagModel> searchTagFriend(
      @Header('Authorization') String token,
      @Query('page') String page,
      @Query('name') String name);

  @FormUrlEncoded()
  @POST("/check_in_search")
  Future<CheckInSearchModel> checkInSearch(
      @Header('Authorization') String token,
      @Query('page') String page,
      @Query('name') String name,
      @Query('latitude') String latitude,
      @Query('longitude') String longitude);

  @POST("/new_post")
  @MultiPart()
  Future<HttpResponse> newPost(
      @Header('Authorization') String token,
      @Query('title') String title,
      @Query('name') String name,
      @Query('location_name') String locationName,
      @Query('lat') String lat,
      @Query('lng') String lng,
      @Query('background_color') String backgroundColor,
      @Part(name: "images") List<MultipartFile> images,
      @Part(name: "videos") List<MultipartFile> videos,
      @Query('tagging') String tagging,
      @Query('feelings') String feelings);

  // profile apis
  @FormUrlEncoded()
  @GET("/profile")
  Future<UserProfile> getProfile(
      @Header('Authorization') String token, @Query('user_id') String userId);

  @FormUrlEncoded()
  @GET("/interests")
  Future<List<InterestModel>> getInterests(
      @Header('Authorization') String token, @Query('user_id') String userId);

  @FormUrlEncoded()
  @POST("/interests/update")
  Future<HttpResponse> getInterestsUpdate(@Header('Authorization') String token,
      @Body() List<InterestModel> dataList);

  @FormUrlEncoded()
  @GET("/work-and-education")
  Future<List<WorkEducationModel>> getWorkEducation(
      @Header('Authorization') String token, @Query('user_id') String userId);

  @FormUrlEncoded()
  @POST("/work-and-education/update")
  Future<HttpResponse> getWorkEducationUpdate(
      @Header('Authorization') String token,
      @Body() List<WorkEducationModel> dataList);

  @FormUrlEncoded()
  @GET("/places-lived")
  Future<PlaceLiveModel> getPlacesLived(
      @Header('Authorization') String token, @Query('user_id') String userId);

  @FormUrlEncoded()
  @POST("/places-lived/update")
  Future<HttpResponse> getPlacesLivedUpdate(
    @Header('Authorization') String token,
    @Query('place') String place,
    @Query('description') String description,
    @Query('privacy') String privacy,
  );

  @FormUrlEncoded()
  @GET("/family-relationship")
  Future<FamilyRelationshipModel> getFamilyRelationship(
      @Header('Authorization') String token, @Query('user_id') String userId);

  @FormUrlEncoded()
  @POST("/family-relationship/update")
  Future<HttpResponse> getFamilyRelationshipUpdate(
      @Header('Authorization') String token);

  @FormUrlEncoded()
  @POST("/about-me/update")
  Future<HttpResponse> updateAboutMe(
      @Header('Authorization') String token,
      @Query('about_me') String aboutMe,
      @Query('address') String address,
      @Query('birthplace') String brithPlace,
      @Query('live_in') String liveIn,
      @Query('about_me_privacy') String aboutMePrivacy,
      @Query('address_privacy') String addressPrivacy,
      @Query('birthplace_privacy') String birthplacePrivacy,
      @Query('language_privacy') String languagesPrivacy,
      @Query('lives_in_privacy') String livesInPrivacy);

  @FormUrlEncoded()
  @GET("/about-me")
  Future<HttpResponse> getAboutMe(@Header('Authorization') String token);

  @FormUrlEncoded()
  @POST("/profile/update")
  Future<HttpResponse> getProfileUpdate(
      @Header('Authorization') String token,
      @Query('first_name') String firstName,
      @Query('last_name') String lastName,
      @Query('phone') String phone,
      @Query('license_no') String licenseNo,
      @Query('specialty') String specialty,
      @Query('dob') String dob,
      @Query('gender') String gender,
      @Query('country') String country,
      @Query('city') String city,
      @Query('country_origin') String countryOrigin,
      @Query('dob_privacy') String dobPrivacy,
      @Query('email_privacy') String emailPrivacy,
      @Query('gender_privacy') String genderPrivacy,
      @Query('phone_privacy') String phonePrivacy,
      @Query('license_no_privacy') String licenseNoPrivacy,
      @Query('specialty_privacy') String specialtyPrivacy,
      @Query('country_privacy') String countryPrivacy,
      @Query('city_privacy') String cityPrivacy,
      @Query('country_origin_privacy') String countryOriginPrivacy);

  @FormUrlEncoded()
  @GET("/get-post-comments")
  Future<PostCommentModel> getPostComments(
      @Header('Authorization') String token, @Query('post_id') String postId);

  @FormUrlEncoded()
  @POST("/post-comment")
  Future<HttpResponse> makeComment(@Header('Authorization') String token,
      @Query('post_id') String postId, @Query('comment') String comment);

  @FormUrlEncoded()
  @POST("/like")
  Future<HttpResponse> like(
      @Header('Authorization') String token, @Query('post_id') String postId);

  // chat api
  @FormUrlEncoded()
  @POST("/get-contacts")
  Future<ContactsModel> getContacts(
      @Header('Authorization') String token, @Query('page') String page);

  @FormUrlEncoded()
  @POST("/search-contacts")
  Future<SearchContactsModel> searchContacts(
      @Header('Authorization') String token,
      @Query('page') String page,
      @Query('keyword') String keyword);

  @FormUrlEncoded()
  @POST("/messenger")
  Future<MessageModel> getRoomMessenger(
      @Header('Authorization') String token,
      @Query('page') String page,
      @Query('user_id') String userId,
      @Query('room_id') String roomId);

  @MultiPart()
  @POST("/send-message")
  Future<SendMessageModel> sendMessage(
      @Header('Authorization') String token,
      @Field('user_id') String userId,
      @Field('room_id') String roomId,
      @Field('receiver_id') String receiverId,
      @Field('attachment_type') String attachmentType,
      @Field('message') String message,
      @Part(name: 'file') String filePath);

  @FormUrlEncoded()
  @POST("/send-message")
  Future<SendMessageModel> sendMessageWithoutFile(
    @Header('Authorization') String token,
    @Field('user_id') String userId,
    @Field('room_id') String roomId,
    @Field('receiver_id') String receiverId,
    @Field('attachment_type') String attachmentType,
    @Field('message') String message,
  );

  @FormUrlEncoded()
  @POST("/save-suggestion")
  Future<HttpResponse> saveSuggestion(
    @Header('Authorization') String token,
    @Field('name') String name,
    @Field('phone') String phone,
    @Field('email') String email,
    @Field('message') String message,
  );

  @MultiPart()
  @POST("/upload-profile-pic")
  Future<HttpResponse> uploadProfilePicture(
      @Header('Authorization') String token,
      @Part(name: 'profile_pic') String filePath);

  @MultiPart()
  @POST("/upload-cover-pic")
  Future<HttpResponse> uploadCoverPicture(@Header('Authorization') String token,
      @Part(name: 'background') String filePath);

  @FormUrlEncoded()
  @GET("/advertisement-types")
  Future<List<AdsTypeModel>> advertisementTypes(
    @Header('Authorization') String token,
  );

  @FormUrlEncoded()
  @GET("/advertisement-setting")
  Future<AdsSettingModel> advertisementSetting(
      @Header('Authorization') String token);

  @FormUrlEncoded()
  @POST("/delete_post")
  Future<HttpResponse> deletePost(
      @Header('Authorization') String token, @Query('post_id') String postId);
}
