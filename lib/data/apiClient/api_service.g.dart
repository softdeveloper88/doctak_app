part of 'api_service.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers

class _ApiService implements ApiService {
  _ApiService(
      this._dio, {
        this.baseUrl,
      }) {
    baseUrl ??= 'https://doctak.net/api/v1';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<PostLoginDeviceAuthResp> login(
      String username,
      String password,
      String deviceType,
      String deviceId,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = {
      'email': username,
      'password': password,
      'device_type': deviceType,
      'device_id': deviceId,
    };
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<PostLoginDeviceAuthResp>(Options(
          method: 'POST',
          headers: _headers,
          extra: _extra,
          contentType: 'application/x-www-form-urlencoded',
        )
            .compose(
          _dio.options,
          '/login',
          queryParameters: queryParameters,
          data: _data,
        )
            .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = PostLoginDeviceAuthResp.fromJson(_result.data!);
    return value;
  }

  @override
  Future<PostLoginDeviceAuthResp> loginWithSocial(
      String username,
      String firstName,
      String lastName,
      String deviceType,
      String deviceId,
      bool isSocialLogin,
      String provider,
      String token,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = {
      'email': username,
      'first_name': firstName,
      'last_name': lastName,
      'device_type': deviceType,
      'device_id': deviceId,
      'isSocialLogin': isSocialLogin,
      'provider': provider,
      'token': token,
    };
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<PostLoginDeviceAuthResp>(Options(
          method: 'POST',
          headers: _headers,
          extra: _extra,
          contentType: 'application/x-www-form-urlencoded',
        )
            .compose(
          _dio.options,
          '/login',
          queryParameters: queryParameters,
          data: _data,
        )
            .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = PostLoginDeviceAuthResp.fromJson(_result.data!);
    return value;
  }
  @override
  Future<PostLoginDeviceAuthResp> completeProfile(
      String token,
      String firstName,
      String lastName,
      String country,
      String state,
      String phone,
      String userType,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = {
      'first_name': firstName,
      'last_name': lastName,
      'country': country,
      'state': state,
      'phone': phone,
      'user_type': userType,
    };
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<PostLoginDeviceAuthResp>(Options(
          method: 'POST',
          headers: _headers,
          extra: _extra,
          contentType: 'application/x-www-form-urlencoded',
        )
            .compose(
          _dio.options,
          '/complete-profile',
          queryParameters: queryParameters,
          data: _data,
        )
            .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = PostLoginDeviceAuthResp.fromJson(_result.data!);
    return value;
  }
  @override
  Future<HttpResponse<Map<String, String>>> register(
      String firstName,
      String lastName,
      String email,
      String password,
      String userType,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'user_type': userType,
    };
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<HttpResponse<Map<String, String>>>(Options(
          method: 'POST',
          headers: _headers,
          extra: _extra,
          contentType: 'application/x-www-form-urlencoded',
        )
            .compose(
          _dio.options,
          '/register',
          queryParameters: queryParameters,
          data: _data,
        )
            .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = _result.data!.cast<String, String>();
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse> forgotPassword(String email) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = {
      'email': email,
    };
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/forgot_password',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

 @override
  Future<HttpResponse> deletePost(String token,String postId) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    final _data = {
      'post_id': postId,
    };
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/delete_post',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<CountriesModel> getCountries() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<CountriesModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/country-list',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = CountriesModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<HttpResponse<dynamic>> getStates(String countryId) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'country_id': countryId};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/get-states',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<dynamic>> getSpecialty() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/specialty',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<dynamic>> getUniversityByStates(String userId) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/universities/state/${userId}',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<PostDataModel> getPosts(
      String token,
      String page,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'page': page};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<PostDataModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/posts',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = PostDataModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<PostDataModel> getMyPosts(
      String token,
      String page,
      String userId,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'user_id': userId,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<PostDataModel>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/user-profile-post',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = PostDataModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<JobsModel> getJobsList(
      String token,
      String page,
      String countryId,
      String searchTerm,
      String expiredJob,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'country_id': countryId,
      r'searchTerm': searchTerm,
      r'expired_job': expiredJob,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<JobsModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/jobs',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = JobsModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<JobDetailModel> getJobsDetails(
      String token,
      String jobId,) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'job_id': jobId,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<JobsModel>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/job_detail',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = JobDetailModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<JobsModel> getSearchJobsList(
      String token,
      String page,
      String countryId,
      String searchTerm,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'country': countryId,
      r'searchTerm': searchTerm,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<JobsModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/search-jobs',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = JobsModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<PostDataModel> getSearchPostList(
      String token,
      String page,
      String searchTerm,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'search': searchTerm,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<PostDataModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/search-post',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = PostDataModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<DrugsModel> getDrugsList(
      String token,
      String page,
      String countryId,
      String searchTerm,
      String type,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'countryId': countryId,
      r'searchTerm': searchTerm,
      r'type': type,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<DrugsModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/drug-search',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = DrugsModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<SearchPeopleModel> getSearchPeople(
      String token,
      String page,
      String searchTerm,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'searchTerm': searchTerm,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<SearchPeopleModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/searchPeople',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = SearchPeopleModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<HttpResponse<dynamic>> setUserFollow(
      String token,
      String userId,
      String follow,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/user/${userId}/${follow}',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<ChatGptAskQuestionResponse> askQuestionFromGpt(
      String token,
      String sessionId,
      String question,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<ChatGptAskQuestionResponse>(Options(
          method: 'GET',
          headers: _headers,
          extra: _extra,
          contentType: 'application/x-www-form-urlencoded',
        )
            .compose(
          _dio.options,
          '/ask-question/${sessionId}/${question}',
          queryParameters: queryParameters,
          data: _data,
        )
            .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = ChatGptAskQuestionResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<ChatGptSession> gptChatSession(String token) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<ChatGptSession>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/gptChat-session',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = ChatGptSession.fromJson(_result.data!);
    return value;
  }

  @override
  Future<ChatGptMessageHistory> gptChatMessages(
      String token,
      dynamic id,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<ChatGptMessageHistory>(Options(
          method: 'GET',
          headers: _headers,
          extra: _extra,
          contentType: 'application/x-www-form-urlencoded',
        )
            .compose(
          _dio.options,
          '/gptChat-history/${id}',
          queryParameters: queryParameters,
          data: _data,
        )
            .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = ChatGptMessageHistory.fromJson(_result.data!);
    return value;
  }

  @override
  Future<HttpResponse<dynamic>> newChat(String token) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/new-chat',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<dynamic>> deleteChatgptSession(
      String token,
      String sessionId,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'session_id': sessionId
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/delete-chatgpt-session',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<dynamic>> getConferenceCountries(String token) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/conference-countries',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<SearchConferenceModel> searchConferences(
      String token,
      String page,
      String country,
      String searchTerm,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'country': country,
      r'search_term': searchTerm,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<SearchConferenceModel>(Options(
          method: 'GET',
          headers: _headers,
          extra: _extra,
          contentType: 'application/x-www-form-urlencoded',
        )
            .compose(
          _dio.options,
          '/search-conferences',
          queryParameters: queryParameters,
          data: _data,
        )
            .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = SearchConferenceModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<List<NewsModel>> newsChannel(
      String token,
      String news,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch<List<dynamic>>(_setStreamType<List<NewsModel>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/${news}',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    var value = _result.data!
        .map((dynamic i) => NewsModel.fromJson(i as Map<String, dynamic>))
        .toList();
    return value;
  }

  @override
  Future<GuidelinesModel> guideline(
      String token,
      String page,
      String searchTerm,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'search_term': searchTerm,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<GuidelinesModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/guideline',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = GuidelinesModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<SearchUserTagModel> searchTagFriend(
      String token,
      String page,
      String name,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'name': name,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<SearchUserTagModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/search-users-for-tag',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = SearchUserTagModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<CheckInSearchModel> checkInSearch(
      String token,
      String page,
      String name,
      String latitude,
      String longitude,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'name': name,
      r'latitude': latitude,
      r'longitude': longitude,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<CheckInSearchModel>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/check_in_search',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = CheckInSearchModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<HttpResponse<dynamic>> newPost(
      String token,
      String title,
      String name,
      String locationName,
      String lat,
      String lng,
      String backgroundColor,
      List<MultipartFile> images,
      List<MultipartFile> videos,
      String tagging,
      String feelings,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'title': title,
      r'name': name,
      r'location_name': locationName,
      r'lat': lat,
      r'lng': lng,
      r'background_color': backgroundColor,
      r'tagging': tagging,
      r'feelings': feelings,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = FormData();
    _data.files.addAll(images.map((i) => MapEntry('images', i)));
    _data.files.addAll(videos.map((i) => MapEntry('videos', i)));
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'multipart/form-data',
    )
        .compose(
      _dio.options,
      '/new_post',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<UserProfile> getProfile(
      String token,
      String userId,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'user_id': userId};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<UserProfile>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/profile',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = UserProfile.fromJson(_result.data!);
    return value;
  }

  @override
  Future<List<InterestModel>> getInterests(
      String token,
      String userId,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'user_id': userId};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<List<dynamic>>(_setStreamType<List<InterestModel>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/interests',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    var value = _result.data!
        .map((dynamic i) => InterestModel.fromJson(i as Map<String, dynamic>))
        .toList();
    return value;
  }

  @override
  Future<HttpResponse<dynamic>> getInterestsUpdate(
      String token,
      List<InterestModel> dataList,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = dataList.map((e) => e.toJson()).toList();
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/interests/update',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<List<WorkEducationModel>> getWorkEducation(
      String token,
      String userId,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'user_id': userId};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<List<dynamic>>(_setStreamType<List<WorkEducationModel>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/work-and-education',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    var value = _result.data!
        .map((dynamic i) =>
        WorkEducationModel.fromJson(i as Map<String, dynamic>))
        .toList();
    return value;
  }

  @override
  Future<HttpResponse<dynamic>> getWorkEducationUpdate(
      String token,
      List<WorkEducationModel> dataList,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = dataList.map((e) => e.toJson()).toList();
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/work-and-education/update',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<PlaceLiveModel> getPlacesLived(
      String token,
      String userId,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'user_id': userId};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<PlaceLiveModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/places-lived',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = PlaceLiveModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<HttpResponse<dynamic>> getPlacesLivedUpdate(
      String token,
      String place,
      String description,
      String privacy,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'place': place,
      r'description': description,
      r'privacy': privacy,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/places-lived/update',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<FamilyRelationshipModel> getFamilyRelationship(
      String token,
      String userId,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'user_id': userId};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<FamilyRelationshipModel>(Options(
          method: 'GET',
          headers: _headers,
          extra: _extra,
          contentType: 'application/x-www-form-urlencoded',
        )
            .compose(
          _dio.options,
          '/family-relationship',
          queryParameters: queryParameters,
          data: _data,
        )
            .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = FamilyRelationshipModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<HttpResponse<dynamic>> getFamilyRelationshipUpdate(
      String token) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/family-relationship/update',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<dynamic>> updateAboutMe(
      String token,
      String aboutMe,
      String address,
      String brithPlace,
      String liveIn,
      String aboutMePrivacy,
      String addressPrivacy,
      String birthplacePrivacy,
      String languagesPrivacy,
      String livesInPrivacy,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'about_me': aboutMe,
      r'address': address,
      r'birthplace': brithPlace,
      r'live_in': liveIn,
      r'about_me_privacy': aboutMePrivacy,
      r'address_privacy': addressPrivacy,
      r'birthplace_privacy': birthplacePrivacy,
      r'language_privacy': languagesPrivacy,
      r'lives_in_privacy': livesInPrivacy,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/about-me/update',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<dynamic>> getAboutMe(String token) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/about-me',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<dynamic>> getProfileUpdate(
      String token,
      String firstName,
      String lastName,
      String phone,
      String licenseNo,
      String specialty,
      String dob,
      String gender,
      String country,
      String city,
      String countryOrigin,
      String dobPrivacy,
      String emailPrivacy,
      String genderPrivacy,
      String phonePrivacy,
      String licenseNoPrivacy,
      String specialtyPrivacy,
      String countryPrivacy,
      String cityPrivacy,
      String countryOriginPrivacy,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'first_name': firstName,
      r'last_name': lastName,
      r'phone': phone,
      r'license_no': licenseNo,
      r'specialty': specialty,
      r'dob': dob,
      r'gender': gender,
      r'country': country,
      r'city': city,
      r'country_origin': countryOrigin,
      r'dob_privacy': dobPrivacy,
      r'email_privacy': emailPrivacy,
      r'gender_privacy': genderPrivacy,
      r'phone_privacy': phonePrivacy,
      r'license_no_privacy': licenseNoPrivacy,
      r'specialty_privacy': specialtyPrivacy,
      r'country_privacy': countryPrivacy,
      r'city_privacy': cityPrivacy,
      r'country_origin_privacy': countryOriginPrivacy,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/profile/update',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<PostCommentModel> getPostComments(
      String token,
      String postId,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'post_id': postId};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<PostCommentModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/get-post-comments',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = PostCommentModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<HttpResponse<dynamic>> makeComment(
      String token,
      String postId,
      String comment,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'post_id': postId,
      r'comment': comment,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/post-comment',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<dynamic>> like(
      String token,
      String postId,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'post_id': postId};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/like',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<ContactsModel> getContacts(
      String token,
      String page,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'page': page};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<ContactsModel>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/get-contacts',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = ContactsModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<SearchContactsModel> searchContacts(
      String token,
      String page,
      String keyword,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'keyword': keyword,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<SearchContactsModel>(Options(
          method: 'POST',
          headers: _headers,
          extra: _extra,
          contentType: 'application/x-www-form-urlencoded',
        )
            .compose(
          _dio.options,
          '/search-contacts',
          queryParameters: queryParameters,
          data: _data,
        )
            .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = SearchContactsModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<MessageModel> getRoomMessenger(
      String token,
      String page,
      String userId,
      String roomId,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'user_id': userId,
      r'room_id': roomId,
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<MessageModel>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/messenger',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = MessageModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<SendMessageModel> sendMessage(
      String token,
      String userId,
      String roomId,
      String receiverId,
      String attachmentType,
      String message,
      String filePath,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    // final _data = {
    //   'user_id': userId,
    //   'room_id': roomId,
    //   'receiver_id': receiverId,
    //   'attachment_type': attachmentType,
    //   'message': message,
    // };
    final formData = FormData.fromMap({
      'user_id': userId,
      'room_id': roomId,
      'receiver_id': receiverId,
      'attachment_type': attachmentType,
      'message': message,
      'file': await MultipartFile.fromFile(filePath),
    });
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<SendMessageModel>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'multipart/form-data',
    )
        .compose(
      _dio.options,
      '/send-message',
      queryParameters: queryParameters,
      data: formData,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = SendMessageModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<SendMessageModel> sendMessageWithoutFile(
      String token,
      String userId,
      String roomId,
      String receiverId,
      String attachmentType,
      String message,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = {
      'user_id': userId,
      'room_id': roomId,
      'receiver_id': receiverId,
      'attachment_type': attachmentType,
      'message': message,
    };
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<SendMessageModel>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/send-message',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = SendMessageModel.fromJson(_result.data!);
    return value;
  }

  @override
  Future<HttpResponse<dynamic>> saveSuggestion(
      String token,
      String name,
      String phone,
      String email,
      String message,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = {
      'name': name,
      'phone': phone,
      'email': email,
      'message': message,
    };
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/save-suggestion',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<dynamic>> uploadProfilePicture(
      String token,
      String filePath,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    // final _data = FormData();
    final formData = FormData.fromMap({
      'profile_pic': await MultipartFile.fromFile(filePath),
    });
    final _result =
    await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'multipart/form-data',
    ).compose(
      _dio.options,
      '/upload-profile-pic',
      queryParameters: queryParameters,
      data: formData,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }
  @override
  Future<HttpResponse<dynamic>> uploadCoverPicture(
      String token,
      String filePath,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    // final _data = FormData();
    final formData = FormData.fromMap({
      'background': await MultipartFile.fromFile(filePath),
    });
    final _result =
        await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'multipart/form-data',
    ).compose(
              _dio.options,
              '/upload-cover-pic',
              queryParameters: queryParameters,
              data: formData,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<List<AdsTypeModel>> advertisementTypes(String token) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<List<dynamic>>(_setStreamType<List<AdsTypeModel>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/advertisement-types',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    var value = _result.data!
        .map((dynamic i) => AdsTypeModel.fromJson(i as Map<String, dynamic>))
        .toList();
    return value;
  }
  @override
  Future<AdsSettingModel> advertisementSetting(token) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);

    const Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<AdsSettingModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
        .compose(
      _dio.options,
      '/advertisement-setting',
      queryParameters: queryParameters,
      data: _data,
    )
        .copyWith(
        baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
    final value = AdsSettingModel.fromJson(_result.data!);
    return value;
  }
  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(
      String dioBaseUrl,
      String? baseUrl,
      ) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }


}

