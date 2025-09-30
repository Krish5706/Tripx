import 'package:dio/dio.dart';
import 'package:tripx_frontend/api/api_constants.dart';
import 'package:tripx_frontend/models/trip.dart';
import 'package:tripx_frontend/utils/secure_storage_service.dart';

class TripRepository {
  final Dio _dio = Dio();
  final SecureStorageService _storageService = SecureStorageService();

  // --- Method to get all trips for the logged-in user ---
  Future<List<Trip>> getTrips() async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    try {
      final response = await _dio.get(
        ApiConstants.baseUrl + ApiConstants.tripsUrl,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      if (response.data['status'] == 'success') {
        List<dynamic> tripData = response.data['data']['trips'];
        return tripData.map((json) => Trip.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trips');
      }
    } on DioException catch (e) {
      // If the token is invalid, the server will send a 401 error
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid token. Please log in again.');
      }
      throw Exception('Network Error: Could not connect to the server.');
    }
  }

  // --- Method to create a new trip ---
  Future<Map<String, dynamic>> createTrip({
    required String tripName,
    required String destination,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String budget,
    required List<String> activities,
  }) async {
    final token = await _storageService.readToken();
    if (token == null) {
      return {'status': 'fail', 'message': 'User not authenticated.'};
    }
    try {
      final response = await _dio.post(
        ApiConstants.baseUrl + ApiConstants.tripsUrl,
        data: {
          'tripName': tripName,
          'destination': destination,
          'description': description,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'budget': double.tryParse(budget) ?? 0,
          'activities': activities,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return e.response!.data;
      }
      return {'status': 'fail', 'message': 'Network Error: Could not connect.'};
    }
  }
}
