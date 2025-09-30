import 'dart:io';
import 'package:dio/dio.dart';
import 'package:tripx_frontend/api/api_constants.dart';
import 'package:tripx_frontend/models/user.dart';
import 'package:tripx_frontend/utils/secure_storage_service.dart';

class UserRepository {
  final Dio _dio = Dio();
  final SecureStorageService _storageService = SecureStorageService();

  Future<User> getMe() async {
    final token = await _storageService.readToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/users/me', // Fixed: Changed from /auth/me to /users/me
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // The user object is nested inside a 'user' key within the 'data' object.
      if (response.data['data'] != null &&
          response.data['data']['user'] != null) {
        return User.fromJson(response.data['data']['user']);
      }
      throw Exception('User data not found in response');
    } catch (e) {
      throw Exception('Failed to fetch user data');
    }
  }

  Future<void> updateUser({
    required String name,
    required String email,
    required String phone,
    required String bio,
    File? profileImage,
  }) async {
    final token = await _storageService.readToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        'phone': phone,
        'bio': bio,
        if (profileImage != null)
          'photo': await MultipartFile.fromFile(profileImage.path),
      });

      await _dio.patch(
        '${ApiConstants.baseUrl}/users/updateMe',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? e.message;
      throw Exception('Failed to update profile: $errorMessage');
    }
  }
}
