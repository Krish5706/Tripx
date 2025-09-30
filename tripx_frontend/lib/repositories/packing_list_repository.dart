import 'package:dio/dio.dart';
import 'package:tripx_frontend/api/api_constants.dart';
import 'package:tripx_frontend/models/packing_list_item.dart';
import 'package:tripx_frontend/utils/secure_storage_service.dart';

class PackingListRepository {
  final Dio _dio = Dio();
  final SecureStorageService _storageService = SecureStorageService();

  // --- Method to get all packing list items for a specific trip ---
  Future<List<PackingListItem>> getPackingListForTrip(String tripId) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/packing-list/trip/$tripId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data['status'] == 'success') {
        List<dynamic> itemData = response.data['data']['items'];
        return itemData.map((json) => PackingListItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load packing list');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid token. Please log in again.');
      }
      throw Exception('Network Error: Could not connect to the server.');
    }
  }

  // --- Method to create a new packing list item ---
  Future<PackingListItem> createPackingListItem({
    required String tripId,
    required String itemName,
    required String category,
  }) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/packing-list/trip/$tripId',
        data: {
          'itemName': itemName,
          'category': category,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data['status'] == 'success') {
        return PackingListItem.fromJson(response.data['data']['item']);
      } else {
        throw Exception('Failed to create item');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  // --- Method to update a packing list item (e.g., toggle isPacked) ---
  Future<PackingListItem> updatePackingListItem(String itemId, bool isPacked) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }
    try {
      final response = await _dio.patch(
        '${ApiConstants.baseUrl}/packing-list/$itemId',
        data: {'isPacked': isPacked},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data['status'] == 'success') {
        return PackingListItem.fromJson(response.data['data']['item']);
      } else {
        throw Exception('Failed to update item');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  // --- Method to delete a packing list item ---
  Future<void> deletePackingListItem(String itemId) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }
    try {
      await _dio.delete(
        '${ApiConstants.baseUrl}/packing-list/$itemId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to delete item: ${e.toString()}');
    }
  }
}
