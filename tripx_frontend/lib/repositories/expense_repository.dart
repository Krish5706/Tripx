import 'package:dio/dio.dart';
import 'package:tripx_frontend/api/api_constants.dart';
import 'package:tripx_frontend/models/expense.dart';
import 'package:tripx_frontend/utils/secure_storage_service.dart';

class ExpenseRepository {
  final Dio _dio = Dio();
  final SecureStorageService _storageService = SecureStorageService();

  Future<List<Expense>> getExpensesForTrip(String tripId) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/expenses/trip/$tripId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data['status'] == 'success') {
        List<dynamic> itemData = response.data['data']['expenses'];
        return itemData.map((json) => Expense.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load expenses');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid token. Please log in again.');
      }
      throw Exception('Network Error: Could not connect to the server.');
    }
  }

  Future<Expense> createExpense({
    required String tripId,
    required String description,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/expenses/trip/$tripId',
        data: {
          'description': description,
          'amount': amount,
          'category': category,
          'date': date.toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data['status'] == 'success') {
        return Expense.fromJson(response.data['data']['expense']);
      } else {
        throw Exception('Failed to create expense');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  // --- NEW: Method to update an expense ---
  Future<Expense> updateExpense({
    required String expenseId,
    required String description,
    required double amount,
    required String category,
  }) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }
    try {
      final response = await _dio.patch(
        '${ApiConstants.baseUrl}/expenses/$expenseId',
        data: {
          'description': description,
          'amount': amount,
          'category': category,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data['status'] == 'success') {
        return Expense.fromJson(response.data['data']['expense']);
      } else {
        throw Exception('Failed to update expense');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  // --- NEW: Method to delete an expense ---
  Future<void> deleteExpense(String expenseId) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }
    try {
      await _dio.delete(
        '${ApiConstants.baseUrl}/expenses/$expenseId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to delete expense: ${e.toString()}');
    }
  }
}
