import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:doctak_app/data/models/jobs_model/job_detail_model.dart';
import 'package:doctak_app/data/models/jobs_model/job_applicants_model.dart';
// Note: jobs_speciality_model.dart doesn't exist, using Map for specialties
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Jobs API Service
/// Handles all job-related API calls
class JobsApiService {
  static final JobsApiService _instance = JobsApiService._internal();
  factory JobsApiService() => _instance;
  JobsApiService._internal();

  /// Get all jobs with pagination
  Future<ApiResponse<JobsModel>> getJobs({
    required String page,
  }) async {
    // try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs?page=$page',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobsModel.fromJson(response));
    // } on ApiException catch (e) {
    //   return ApiResponse.error(e.message, statusCode: e.statusCode);
    // } catch (e) {
    //   return ApiResponse.error('Failed to get jobs: $e');
    // }
  }

  /// Search jobs by keyword and filters
  Future<ApiResponse<JobsModel>> searchJobs({
    required String page,
    required String keyword,
    String? location,
    String? specialty,
    String? jobType,
    String? experience,
  }) async {
    // try {
      String queryParams = 'page=$page&keyword=$keyword';
      if (location != null && location.isNotEmpty) {
        queryParams += '&location=$location';
      }
      if (specialty != null && specialty.isNotEmpty) {
        queryParams += '&specialty=$specialty';
      }
      if (jobType != null && jobType.isNotEmpty) {
        queryParams += '&job_type=$jobType';
      }
      if (experience != null && experience.isNotEmpty) {
        queryParams += '&experience=$experience';
      }

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search-job?$queryParams',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobsModel.fromJson(response));
    // } on ApiException catch (e) {
    //   return ApiResponse.error(e.message, statusCode: e.statusCode);
    // } catch (e) {
    //   return ApiResponse.error('Failed to search jobs: $e');
    // }
  }

  /// Get job specialities/categories
  Future<ApiResponse<List<Map<String, dynamic>>>> getJobSpecialities() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs-speciality',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final List<dynamic> specialitiesData = response is List ? response : response['data'] ?? [];
      final specialities = specialitiesData.map((json) => Map<String, dynamic>.from(json)).toList();
      return ApiResponse.success(specialities);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get job specialities: $e');
    }
  }

  /// Apply for a job
  Future<ApiResponse<Map<String, dynamic>>> applyForJob({
    required String jobId,
    required String coverLetter,
    String? resumeFilePath,
  }) async {
    try {
      final request = {
        'job_id': jobId,
        'cover_letter': coverLetter,
      };
      
      if (resumeFilePath != null) {
        request['resume'] = resumeFilePath; // This would need proper file upload handling
      }

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs/apply',
          method: networkUtils.HttpMethod.POST,
          request: request,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to apply for job: $e');
    }
  }

  /// Save/Bookmark a job
  Future<ApiResponse<Map<String, dynamic>>> saveJob({
    required String jobId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs/save',
          method: networkUtils.HttpMethod.POST,
          request: {'job_id': jobId},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to save job: $e');
    }
  }

  /// Unsave/Remove bookmark from a job
  Future<ApiResponse<Map<String, dynamic>>> unsaveJob({
    required String jobId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs/unsave',
          method: networkUtils.HttpMethod.POST,
          request: {'job_id': jobId},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to unsave job: $e');
    }
  }

  /// Get saved/bookmarked jobs
  Future<ApiResponse<JobsModel>> getSavedJobs({
    required String page,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs/saved?page=$page',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get saved jobs: $e');
    }
  }

  /// Get applied jobs history
  Future<ApiResponse<JobsModel>> getAppliedJobs({
    required String page,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs/applied?page=$page',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get applied jobs: $e');
    }
  }

  /// Get job details by ID
  Future<ApiResponse<JobDetailModel>> getJobDetails({
    required String jobId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs/$jobId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobDetailModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get job details: $e');
    }
  }

  /// Get recommended jobs based on user profile
  Future<ApiResponse<JobsModel>> getRecommendedJobs({
    required String page,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs/recommended?page=$page',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get recommended jobs: $e');
    }
  }

  /// Get jobs by location
  Future<ApiResponse<JobsModel>> getJobsByLocation({
    required String page,
    required String location,
  }) async {
    // try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs/location?page=$page&location=$location',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobsModel.fromJson(response));
    // } on ApiException catch (e) {
    //   return ApiResponse.error(e.message, statusCode: e.statusCode);
    // } catch (e) {
    //   return ApiResponse.error('Failed to get jobs by location: $e');
    // }
  }

  /// Get jobs by specialty
  Future<ApiResponse<JobsModel>> getJobsBySpecialty({
    required String page,
    required String specialtyId,
  }) async {
    // try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs/specialty?page=$page&specialty_id=$specialtyId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobsModel.fromJson(response));
    // } on ApiException catch (e) {
    //   return ApiResponse.error(e.message, statusCode: e.statusCode);
    // } catch (e) {
    //   return ApiResponse.error('Failed to get jobs by specialty: $e');
    // }
  }

  /// Withdraw job application
  Future<ApiResponse<Map<String, dynamic>>> withdrawApplication({
    required String jobId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs-applicants/$jobId/withdraw-application',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to withdraw application: $e');
    }
  }

  /// Get job applicants
  Future<ApiResponse<JobApplicantsModel>> getJobApplicants({
    required String jobId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs-applicants/$jobId/applicants',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobApplicantsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get job applicants: $e');
    }
  }

  /// Post a new job (for employers)
  Future<ApiResponse<Map<String, dynamic>>> postJob({
    required String title,
    required String description,
    required String location,
    required String specialty,
    required String jobType,
    required String experience,
    required String salary,
    required String companyName,
    required String contactEmail,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs/post',
          method: networkUtils.HttpMethod.POST,
          request: {
            'title': title,
            'description': description,
            'location': location,
            'specialty': specialty,
            'job_type': jobType,
            'experience': experience,
            'salary': salary,
            'company_name': companyName,
            'contact_email': contactEmail,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to post job: $e');
    }
  }

  // ================================== BACKWARD COMPATIBILITY ==================================

  /// Get jobs list (backward compatibility)
  Future<ApiResponse<JobsModel>> getJobsList({
    required String page,
    String? searchTerm,
  }) async {
    if (searchTerm != null && searchTerm.isNotEmpty) {
      return searchJobs(page: page, keyword: searchTerm);
    } else {
      return getJobs(page: page);
    }
  }

  /// Get job details (backward compatibility)
  Future<ApiResponse<JobDetailModel>> getJobsDetails({
    required String jobId,
  }) async {
    return getJobDetails(jobId: jobId);
  }
}