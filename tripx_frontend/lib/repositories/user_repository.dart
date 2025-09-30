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
    String? phone,
    String? bio,
    File? profileImage,
    bool removeImage = false,
  }) async {
    final token = await _storageService.readToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        'phone': phone,
        'bio': bio,
        'removeImage': removeImage ? 'true' : 'false',
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

  Future<String> uploadProfilePicture(String imagePath) async {
    final token = await _storageService.readToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/users/uploadProfilePicture',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['data'] != null && response.data['data']['photo'] != null) {
        return response.data['data']['photo'];
      }
      throw Exception('Upload failed: No photo URL returned');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? e.message;
      throw Exception('Failed to upload profile picture: $errorMessage');
    }
  }

  Future<void> updateProfilePicture(String photoUrl) async {
    final token = await _storageService.readToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      await _dio.patch(
        '${ApiConstants.baseUrl}/users/updateMe',
        data: {'photo': photoUrl},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? e.message;
      throw Exception('Failed to update profile picture: $errorMessage');
    }
  }
}
