import 'package:dio/dio.dart';
import 'package:tripx_frontend/api/api_constants.dart';
import 'package:tripx_frontend/models/note.dart';
import 'package:tripx_frontend/utils/secure_storage_service.dart';

class NoteRepository {
  final Dio _dio = Dio();
  final SecureStorageService _storageService = SecureStorageService();

  // --- Method to get all notes for a specific trip ---
  Future<List<Note>> getNotesForTrip(String tripId) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/notes/trip/$tripId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data['status'] == 'success') {
        List<dynamic> itemData = response.data['data']['notes'];
        return itemData.map((json) => Note.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notes');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid token. Please log in again.');
      }
      throw Exception('Network Error: Could not connect to the server.');
    }
  }

  // --- Method to create a new note ---
  Future<Note> createNote({
    required String tripId,
    required String title,
    String? content,
  }) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/notes/trip/$tripId',
        data: {
          'title': title,
          'content': content,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data['status'] == 'success') {
        return Note.fromJson(response.data['data']['note']);
      } else {
        throw Exception('Failed to create note');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  // --- Method to update a note ---
  Future<Note> updateNote({
    required String noteId,
    required String title,
    String? content,
  }) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }
    try {
      final response = await _dio.patch(
        '${ApiConstants.baseUrl}/notes/$noteId',
        data: {
          'title': title,
          'content': content,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data['status'] == 'success') {
        return Note.fromJson(response.data['data']['note']);
      } else {
        throw Exception('Failed to update note');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  // --- Method to delete a note ---
  Future<void> deleteNote(String noteId) async {
    final token = await _storageService.readToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }
    try {
      await _dio.delete(
        '${ApiConstants.baseUrl}/notes/$noteId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to delete note: ${e.toString()}');
    }
  }
}
