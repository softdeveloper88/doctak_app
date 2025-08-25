import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/post_comman_widget.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';

import '../../main.dart';

// Add a baseUrl for AI Chat API
String get baseUrl => '${AppData.remoteUrl2}/api';

// Add getHeaders function for AI Chat API
Future<Map<String, String>> getHeaders() async {
  return buildHeaderTokens(contentType: 'application/json');
}

Map<String, String> buildHeaderTokens({String? contentType='application/x-www-form-urlencoded'}) {
  Map<String, String> header = {
    HttpHeaders.contentTypeHeader: contentType??'application/x-www-form-urlencoded',
    // HttpHeaders.cacheControlHeader: 'no-cache',
    // HttpHeaders.cacheControlHeader: 'no-cache',
    // HttpHeaders.contentTypeHeader: 'application/json',
    // 'Access-Control-Allow-Headers': '*',
    // 'Access-Control-Allow-Headers': '*',
    // 'Access-Control-Allow-Origin': '*',
  };
  
  print("⚠️ AppData.logInUserId: ${AppData.logInUserId}");
  print("⚠️ AppData.userToken: ${AppData.userToken != null ? 'Token exists' : 'Token is null'}");
  
  if (AppData.logInUserId != '') {
    header.putIfAbsent(HttpHeaders.authorizationHeader, () => 'Bearer ${AppData.userToken}');
    print("⚠️ Added auth header: Bearer ${AppData.userToken?.substring(0, 10)}...");
  } else {
    print("⚠️ WARNING: No user ID found, not adding authorization header!");
  }
  
  log(jsonEncode(header));
  return header;
}

Uri buildBaseUrl(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http')) url = Uri.parse('${AppData.remoteUrl2}$endPoint');

  log('URL: ${url.toString()}');

  return url;
}
Uri buildBaseUrl3(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http')) url = Uri.parse('${AppData.remoteUrl3}$endPoint');

  log('URL: ${url.toString()}');

  return url;
}
Uri buildBaseUrl1(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http')) url = Uri.parse('${AppData.remoteUrl}$endPoint');

  log('URL: ${url.toString()}');

  return url;
}

Future<Response> buildHttpResponse1(String endPoint, {HttpMethod method = HttpMethod.GET, Map? request}) async {
  if (await isNetworkAvailable()) {
    var headers = buildHeaderTokens();
    Uri url = buildBaseUrl1(endPoint);

    print('Header:${headers.toString()}');

    try {
      Response response;

      if (method == HttpMethod.POST) {
        log('Request: $request');
        response = await http.post(url, body:  request?.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&'), headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      } else if (method == HttpMethod.DELETE) {
        response = await delete(url, headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      } else if (method == HttpMethod.PUT) {
        var headers = buildHeaderTokens(contentType: 'application/json');

        log('Request: $request');
        response = await put(url, body: jsonEncode(request), headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      } else {
        response = await get(url, headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      }

      log('Response ($method): ${url.toString()} ${response.statusCode} ${response.body}');

      return response;
    } catch (e) {
      throw 'Something Went Wrong $e';
    }
  } else {
    throw 'Your internet is not working';
  }
}
Future<Response> buildHttpResponse(String endPoint, {HttpMethod method = HttpMethod.GET, Map? request}) async {
  if (await isNetworkAvailable()) {
    var headers = buildHeaderTokens();
    Uri url = buildBaseUrl(endPoint);

    print('Header:${headers.toString()}');

    try {
      Response response;

      if (method == HttpMethod.POST) {
        log('Request: $request');
        response = await http.post(url, body:  request?.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&'), headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      } else if (method == HttpMethod.DELETE) {
        response = await delete(url, headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      } else if (method == HttpMethod.PUT) {
        var headers = buildHeaderTokens(contentType: 'application/json');

        log('Request: $request');
        response = await put(url, body: jsonEncode(request), headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      } else {
        response = await get(url, headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      }

      log('Response ($method): ${url.toString()} ${response.statusCode} ${response.body}');

      return response;
    } catch (e) {

      throw 'Something Went Wrong $e';
    }
  } else {
    throw 'Your internet is not working';
  }
}
Future<Response> buildHttpResponse2(String endPoint, {HttpMethod method = HttpMethod.GET, Map? request}) async {
  if (await isNetworkAvailable()) {
    var headers = buildHeaderTokens();
    Uri url = buildBaseUrl3(endPoint);

    print('⚠️ URL: ${url.toString()}');
    print('⚠️ Headers: ${headers.toString()}');
    print('⚠️ Method: $method');
    print('⚠️ Request: $request');

    try {
      Response response;

      if (method == HttpMethod.POST) {
        log('Request: $request');
        response = await http.post(url, body:  request?.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&'), headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      } else if (method == HttpMethod.DELETE) {
        response = await delete(url, headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      } else if (method == HttpMethod.PUT) {
        var headers = buildHeaderTokens(contentType: 'application/json');

        log('Request: $request');
        response = await put(url, body: jsonEncode(request), headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      } else {
        response = await get(url, headers: headers).timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding after 60 seconds');
      }

      log('Response ($method): ${url.toString()} ${response.statusCode} ${response.body}');

      return response;
    } catch (e) {

      throw 'Something Went Wrong $e';
    }
  } else {
    throw 'Your internet is not working';
  }
}

//region Common

Future handleResponse(Response response, [bool? avoidTokenError]) async {
  if (!await isNetworkAvailable()) {
    throw 'Your internet is not working';
  }
  if (response.statusCode == 401) {
    if (AppData.logInUserId ==null) {
      // Map req = {
      //   'emailPhone': sharedPref.getString(USER_EMAIL),
      //   'password': sharedPref.getString(USER_PASSWORD),
      // };
      //
      // await logInApi(req).then((value) {
      //   throw 'Please try again.';
      // }).catchError((e) {
      //   throw TokenException(e);
      // });
    } else {
      throw '';
    }
  }

  if ((response.statusCode >= 200 && response.statusCode < 300) || response.statusCode == 403) {
    return jsonDecode(response.body);
  } else {
    try {
      var body = jsonDecode(response.body);
      throw parseHtmlString(body['message']);
    } on Exception catch (e) {
      log(e);
      throw 'Something Went Wrong';
    }
  }
}

enum HttpMethod { GET, POST, DELETE, PUT }

class TokenException implements Exception {
  final String message;

  const TokenException([this.message = ""]);

  String toString() => "FormatException: $message";
}