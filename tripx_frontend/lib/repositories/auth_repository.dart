import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:tripx_frontend/api/api_constants.dart';
import 'package:tripx_frontend/api/dio_client.dart';

class AuthRepository {
  final Logger _logger = Logger();

  // Method to register a new user with retry logic
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    const maxRetries = 2;
    var attempt = 0;

    while (attempt <= maxRetries) {
      try {
        _logger.i('Registration attempt ${attempt + 1}/${maxRetries + 1}');

        final response = await dio.post(
          ApiConstants.registerUrl,
          data: {
            'name': name,
            'email': email,
            'password': password,
          },
        ).timeout(const Duration(seconds: 20)); // Additional timeout for the request

        _logger.i('Registration successful on attempt ${attempt + 1}');
        return response.data;
      } on DioException catch (e) {
        attempt++;
        _logger.e('DioException on attempt $attempt: ${e.response?.data}');
        _logger.e('Status Code: ${e.response?.statusCode}');
        _logger.e('Message: ${e.message}');

        // Handle API errors (e.g., user already exists)
        if (e.response != null && e.response?.data is Map) {
          return e.response?.data;
        }

        // If this is the last attempt or it's not a timeout error, return the error
        if (attempt > maxRetries || e.type != DioExceptionType.connectionTimeout) {
          return {
            'status': 'fail',
            'message': e.type == DioExceptionType.connectionTimeout
                ? 'Connection timeout. Please check your internet connection and try again.'
                : e.message ?? 'Network error occurred'
          };
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        attempt++;
        _logger.e('Unexpected error on attempt $attempt: ${e.toString()}');

        if (attempt > maxRetries) {
          return {
            'status': 'fail',
            'message': 'An unexpected error occurred: ${e.toString()}'
          };
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    // This should never be reached, but just in case
    return {
      'status': 'fail',
      'message': 'Registration failed after all retry attempts'
    };
  }

  // Method to log in a user with retry logic
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    const maxRetries = 2;
    var attempt = 0;

    while (attempt <= maxRetries) {
      try {
        _logger.i('Login attempt ${attempt + 1}/${maxRetries + 1}');

        final response = await dio.post(
          ApiConstants.loginUrl,
          data: {
            'email': email,
            'password': password,
          },
        ).timeout(const Duration(seconds: 20)); // Additional timeout for the request

        _logger.i('Login successful on attempt ${attempt + 1}');
        return response.data;
      } on DioException catch (e) {
        attempt++;
        _logger.e('DioException on login attempt $attempt: ${e.response?.data}');
        _logger.e('Status Code: ${e.response?.statusCode}');
        _logger.e('Message: ${e.message}');

        // Handle API errors (e.g., invalid credentials)
        if (e.response != null && e.response?.data is Map) {
          return e.response?.data;
        }

        // If this is the last attempt or it's not a timeout error, return the error
        if (attempt > maxRetries || e.type != DioExceptionType.connectionTimeout) {
          return {
            'status': 'fail',
            'message': e.type == DioExceptionType.connectionTimeout
                ? 'Connection timeout. Please check your internet connection and try again.'
                : 'Network Error: Could not connect to the server.'
          };
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        attempt++;
        _logger.e('Unexpected error on login attempt $attempt: ${e.toString()}');

        if (attempt > maxRetries) {
          return {
            'status': 'fail',
            'message': 'An unexpected error occurred: ${e.toString()}'
          };
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    // This should never be reached, but just in case
    return {
      'status': 'fail',
      'message': 'Login failed after all retry attempts'
    };
  }
}
