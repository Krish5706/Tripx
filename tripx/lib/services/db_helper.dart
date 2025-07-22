import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  /// Call this before any DB usage on desktop/web/test environments
  static void initFfi() {
    // Only needed for non-mobile platforms
    databaseFactory = databaseFactoryFfi;
  }

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tripx.db');

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        session_token TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // Hash password using SHA256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register a new user
  Future<int> registerUser(String name, String email, String password) async {
    final db = await database;

    try {
      // Check if email already exists
      final existingUser = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (existingUser.isNotEmpty) {
        return -1; // Email already exists
      }

      // Hash the password
      String hashedPassword = _hashPassword(password);

      // Get current timestamp
      String currentTime = DateTime.now().toIso8601String();

      // Insert new user
      int userId = await db.insert('users', {
        'name': name,
        'email': email.toLowerCase(),
        'password': hashedPassword,
        'created_at': currentTime,
        'updated_at': currentTime,
      });

      return userId;
    } catch (e) {
      log('Error registering user: $e', name: 'DatabaseHelper');
      return -1;
    }
  }

  // Login user
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;

    try {
      // Hash the provided password
      String hashedPassword = _hashPassword(password);

      // Query user with email and hashed password
      final users = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email.toLowerCase(), hashedPassword],
      );

      if (users.isNotEmpty) {
        // Update last login time
        await db.update(
          'users',
          {'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [users.first['id']],
        );

        return users.first;
      }

      return null; // Invalid credentials
    } catch (e) {
      log('Error logging in user: $e', name: 'DatabaseHelper');
      return null;
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;

    try {
      final users = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (users.isNotEmpty) {
        return users.first;
      }

      return null;
    } catch (e) {
      log('Error getting user by ID: $e', name: 'DatabaseHelper');
      return null;
    }
  }

  // Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;

    try {
      final users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (users.isNotEmpty) {
        return users.first;
      }

      return null;
    } catch (e) {
      log('Error getting user by email: $e', name: 'DatabaseHelper');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUser(int userId, {String? name, String? email}) async {
    final db = await database;

    try {
      Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (email != null) {
        // Check if new email already exists (excluding current user)
        final existingUser = await db.query(
          'users',
          where: 'email = ? AND id != ?',
          whereArgs: [email.toLowerCase(), userId],
        );

        if (existingUser.isNotEmpty) {
          return false; // Email already exists
        }

        updateData['email'] = email.toLowerCase();
      }

      int rowsAffected = await db.update(
        'users',
        updateData,
        where: 'id = ?',
        whereArgs: [userId],
      );

      return rowsAffected > 0;
    } catch (e) {
      log('Error updating user: $e', name: 'DatabaseHelper');
      return false;
    }
  }

  // Change user password
  Future<bool> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    final db = await database;

    try {
      // Verify current password
      String hashedCurrentPassword = _hashPassword(currentPassword);

      final users = await db.query(
        'users',
        where: 'id = ? AND password = ?',
        whereArgs: [userId, hashedCurrentPassword],
      );

      if (users.isEmpty) {
        return false; // Current password is incorrect
      }

      // Update with new password
      String hashedNewPassword = _hashPassword(newPassword);

      int rowsAffected = await db.update(
        'users',
        {
          'password': hashedNewPassword,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      return rowsAffected > 0;
    } catch (e) {
      log('Error changing password: $e', name: 'DatabaseHelper');
      return false;
    }
  }

  // Reset password (for forgot password functionality)
  Future<bool> resetPassword(String email, String newPassword) async {
    final db = await database;

    try {
      // Check if email exists
      final users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (users.isEmpty) {
        return false; // Email doesn't exist
      }

      // Update with new password
      String hashedNewPassword = _hashPassword(newPassword);

      int rowsAffected = await db.update(
        'users',
        {
          'password': hashedNewPassword,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      return rowsAffected > 0;
    } catch (e) {
      log('Error resetting password: $e', name: 'DatabaseHelper');
      return false;
    }
  }

  // Create user session
  Future<String?> createSession(int userId) async {
    final db = await database;

    try {
      // Generate session token
      String sessionToken = _generateSessionToken(userId);

      // Session expires in 30 days
      DateTime expiresAt = DateTime.now().add(const Duration(days: 30));

      await db.insert('user_sessions', {
        'user_id': userId,
        'session_token': sessionToken,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      return sessionToken;
    } catch (e) {
      log('Error creating session: $e', name: 'DatabaseHelper');
      return null;
    }
  }

  // Generate session token
  String _generateSessionToken(int userId) {
    String data = '$userId${DateTime.now().millisecondsSinceEpoch}';
    var bytes = utf8.encode(data);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Validate session
  Future<Map<String, dynamic>?> validateSession(String sessionToken) async {
    final db = await database;

    try {
      final sessions = await db.rawQuery(
        '''
        SELECT s.*, u.* FROM user_sessions s
        INNER JOIN users u ON s.user_id = u.id
        WHERE s.session_token = ? AND s.expires_at > ?
      ''',
        [sessionToken, DateTime.now().toIso8601String()],
      );

      if (sessions.isNotEmpty) {
        return sessions.first;
      }

      return null;
    } catch (e) {
      log('Error validating session: $e', name: 'DatabaseHelper');
      return null;
    }
  }

  // Delete session (logout)
  Future<bool> deleteSession(String sessionToken) async {
    final db = await database;

    try {
      int rowsAffected = await db.delete(
        'user_sessions',
        where: 'session_token = ?',
        whereArgs: [sessionToken],
      );

      return rowsAffected > 0;
    } catch (e) {
      log('Error deleting session: $e', name: 'DatabaseHelper');
      return false;
    }
  }

  // Delete all sessions for a user (logout from all devices)
  Future<bool> deleteAllUserSessions(int userId) async {
    final db = await database;

    try {
      int rowsAffected = await db.delete(
        'user_sessions',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      return rowsAffected > 0;
    } catch (e) {
      log('Error deleting all user sessions: $e', name: 'DatabaseHelper');
      return false;
    }
  }

  // Clean expired sessions
  Future<bool> cleanExpiredSessions() async {
    final db = await database;

    try {
      int rowsAffected = await db.delete(
        'user_sessions',
        where: 'expires_at <= ?',
        whereArgs: [DateTime.now().toIso8601String()],
      );

      return rowsAffected > 0;
    } catch (e) {
      log('Error cleaning expired sessions: $e', name: 'DatabaseHelper');
      return false;
    }
  }

  // Get all users (for admin purposes)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;

    try {
      final users = await db.query(
        'users',
        columns: [
          'id',
          'name',
          'email',
          'created_at',
          'updated_at',
        ], // Exclude password
        orderBy: 'created_at DESC',
      );

      return users;
    } catch (e) {
      log('Error getting all users: $e', name: 'DatabaseHelper');
      return [];
    }
  }

  // Delete user account
  Future<bool> deleteUser(int userId) async {
    final db = await database;

    try {
      // Delete user sessions first (due to foreign key constraint)
      await db.delete(
        'user_sessions',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Delete user
      int rowsAffected = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      return rowsAffected > 0;
    } catch (e) {
      log('Error deleting user: $e', name: 'DatabaseHelper');
      return false;
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    final db = await database;

    try {
      final users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      return users.isNotEmpty;
    } catch (e) {
      log('Error checking if email exists: $e', name: 'DatabaseHelper');
      return false;
    }
  }

  // Get user count
  Future<int> getUserCount() async {
    final db = await database;

    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
      return result.first['count'] as int;
    } catch (e) {
      log('Error getting user count: $e', name: 'DatabaseHelper');
      return 0;
    }
  }

  // Close database connection
  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Database backup (export users data)
  Future<List<Map<String, dynamic>>> exportUsers() async {
    final db = await database;

    try {
      final users = await db.query(
        'users',
        columns: ['name', 'email', 'created_at'], // Exclude sensitive data
        orderBy: 'created_at ASC',
      );

      return users;
    } catch (e) {
      log('Error exporting users: $e', name: 'DatabaseHelper');
      return [];
    }
  }

  // Database maintenance - vacuum
  Future<bool> vacuumDatabase() async {
    final db = await database;

    try {
      await db.execute('VACUUM');
      return true;
    } catch (e) {
      log('Error vacuuming database: $e', name: 'DatabaseHelper');
      return false;
    }
  }
}
