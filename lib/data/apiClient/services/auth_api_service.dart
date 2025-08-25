import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Authentication API Service
/// Handles all authentication related API calls
class AuthApiService {
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  /// User login with email/password
  Future<ApiResponse<PostLoginDeviceAuthResp>> login({
    required String email,
    required String password,
    required String deviceType,
    required String deviceId,
    required String deviceToken,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/login',
          method: networkUtils.HttpMethod.POST,
          request: {
            'email': email,
            'password': password,
            'device_type': deviceType,
            'device_id': deviceId,
            'device_token': deviceToken,
          },
        ),
      );
      return ApiResponse.success(PostLoginDeviceAuthResp.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Login failed: $e');
    }
  }

  /// Social login (Google, Apple, Facebook, etc.)
  Future<ApiResponse<PostLoginDeviceAuthResp>> loginWithSocial({
    required String email,
    required String firstName,
    required String lastName,
    required String deviceType,
    required String deviceId,
    required String deviceToken,
    required String provider,
    required String token,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/login',
          method: networkUtils.HttpMethod.POST,
          request: {
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'device_type': deviceType,
            'device_id': deviceId,
            'device_token': deviceToken,
            'isSocialLogin': true,
            'provider': provider,
            'token': token,
          },
        ),
      );
      return ApiResponse.success(PostLoginDeviceAuthResp.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Social login failed: $e');
    }
  }

  /// User registration
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String userType,
    required String deviceToken,
    required String deviceType,
    required String deviceId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/register',
          method: networkUtils.HttpMethod.POST,
          request: {
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'password': password,
            'user_type': userType,
            'device_token': deviceToken,
            'device_type': deviceType,
            'device_id': deviceId,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Registration failed: $e');
    }
  }

  /// Complete user profile after registration
  Future<ApiResponse<PostLoginDeviceAuthResp>> completeProfile({
    required String firstName,
    required String lastName,
    required String country,
    required String state,
    required String specialty,
    required String phone,
    required String userType,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/complete-profile',
          method: networkUtils.HttpMethod.POST,
          request: {
            'first_name': firstName,
            'last_name': lastName,
            'country': country,
            'state': state,
            'specialty': specialty,
            'phone': phone,
            'user_type': userType,
          },
        ),
      );
      return ApiResponse.success(PostLoginDeviceAuthResp.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Profile completion failed: $e');
    }
  }

  /// Forgot password
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/forgot_password',
          method: networkUtils.HttpMethod.POST,
          request: {'email': email},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Password reset failed: $e');
    }
  }

  /// Get countries list
  Future<ApiResponse<CountriesModel>> getCountries() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/country-list',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(CountriesModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get countries: $e');
    }
  }

  /// Get states by country
  Future<ApiResponse<Map<String, dynamic>>> getStates({
    required String countryId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/get-states?country_id=$countryId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get states: $e');
    }
  }

  /// Get specialty list
  Future<ApiResponse<Map<String, dynamic>>> getSpecialty() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/specialty',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get specialties: $e');
    }
  }

  /// Get universities by state
  Future<ApiResponse<Map<String, dynamic>>> getUniversitiesByState({
    required String stateId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/universities/state/$stateId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get universities: $e');
    }
  }

  // ================================== BACKWARD COMPATIBILITY ==================================
  // Note: Backward compatibility is maintained through the existing methods above
}