import 'package:dio/dio.dart';
import 'package:tripx_frontend/api/api_constants.dart';
import 'package:tripx_frontend/models/schedule.dart';
import 'package:tripx_frontend/utils/secure_storage_service.dart';

class ScheduleRepository {
  final Dio _dio = Dio();
  final SecureStorageService _storageService = SecureStorageService();

  Future<List<Schedule>> getScheduleForTrip(String tripId) async {
    final token = await _storageService.readToken();
    if (token == null) throw Exception('User not authenticated.');

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/schedule/trip/$tripId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data['status'] == 'success') {
        List<dynamic> scheduleData = response.data['data']['schedule'];
        return scheduleData.map((json) => Schedule.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load schedule');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid token. Please log in again.');
      }
      throw Exception('Network Error: Could not connect to the server.');
    }
  }

  Future<Map<String, dynamic>> createScheduleItem({
    required String tripId,
    required String title,
    String? description,
    String? location,
    required String category,
    required String priority,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    final token = await _storageService.readToken();
    if (token == null) return {'status': 'fail', 'message': 'User not authenticated.'};
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/schedule/trip/$tripId',
        data: {
          'title': title,
          'description': description,
          'location': location,
          'category': category,
          'priority': priority,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime?.toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {'status': 'fail', 'message': 'Network Error.'};
    }
  }

  // --- NEW: Method to update a schedule item ---
  Future<Map<String, dynamic>> updateScheduleItem({
    required String itemId,
    required String title,
    String? description,
    String? location,
    required String category,
    required String priority,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    final token = await _storageService.readToken();
    if (token == null) return {'status': 'fail', 'message': 'User not authenticated.'};
    try {
      final response = await _dio.patch(
        '${ApiConstants.baseUrl}/schedule/$itemId',
        data: {
          'title': title,
          'description': description,
          'location': location,
          'category': category,
          'priority': priority,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime?.toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {'status': 'fail', 'message': 'Network Error.'};
    }
  }

  // --- NEW: Method to delete a schedule item ---
  Future<void> deleteScheduleItem(String itemId) async {
    final token = await _storageService.readToken();
    if (token == null) throw Exception('User not authenticated.');
    try {
      await _dio.delete(
        '${ApiConstants.baseUrl}/schedule/$itemId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException {
      throw Exception('Failed to delete item.');
    }
  }
}
