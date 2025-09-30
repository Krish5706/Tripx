import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // Save the token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Read the token
  Future<String?> readToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Delete the token (for logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
