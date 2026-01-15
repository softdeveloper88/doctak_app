class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.message, this.statusCode});

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(success: true, data: data, message: message, statusCode: 200);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(success: false, message: message, statusCode: statusCode);
  }
}
