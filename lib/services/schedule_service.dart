import 'dart:async';
import 'dart:convert';
import 'db_helper.dart';

class ScheduleItem {
  final int? id;
  final int tripId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String category;
  final String priority;
  final bool isCompleted;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleItem({
    this.id,
    required this.tripId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.category,
    required this.priority,
    this.isCompleted = false,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'category': category,
      'priority': priority,
      'is_completed': isCompleted ? 1 : 0,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'],
      tripId: map['trip_id'],
      title: map['title'],
      description: map['description'],
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      location: map['location'],
      category: map['category'],
      priority: map['priority'],
      isCompleted: map['is_completed'] == 1,
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  ScheduleItem copyWith({
    int? id,
    int? tripId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? category,
    String? priority,
    bool? isCompleted,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Initialize schedule table
  Future<void> initializeScheduleTable() async {
    final db = await _dbHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schedule_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        location TEXT,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  // Create a new schedule item
  Future<int> createScheduleItem(ScheduleItem item) async {
    final db = await _dbHelper.database;
    await initializeScheduleTable();
    
    final now = DateTime.now();
    final itemWithTimestamps = item.copyWith(
      createdAt: now,
      updatedAt: now,
    );
    
    return await db.insert('schedule_items', itemWithTimestamps.toMap());
  }

  // Get all schedule items for a trip
  Future<List<ScheduleItem>> getScheduleItemsByTrip(int tripId) async {
    final db = await _dbHelper.database;
    await initializeScheduleTable();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'schedule_items',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'start_time ASC',
    );
    
    return List.generate(maps.length, (i) => ScheduleItem.fromMap(maps[i]));
  }

  // Get schedule items for a specific date
  Future<List<ScheduleItem>> getScheduleItemsByDate(int tripId, DateTime date) async {
    final db = await _dbHelper.database;
    await initializeScheduleTable();
    
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'schedule_items',
      where: 'trip_id = ? AND start_time >= ? AND start_time <= ?',
      whereArgs: [
        tripId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'start_time ASC',
    );
    
    return List.generate(maps.length, (i) => ScheduleItem.fromMap(maps[i]));
  }

  // Update a schedule item
  Future<int> updateScheduleItem(ScheduleItem item) async {
    final db = await _dbHelper.database;
    await initializeScheduleTable();
    
    final updatedItem = item.copyWith(updatedAt: DateTime.now());
    
    return await db.update(
      'schedule_items',
      updatedItem.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Delete a schedule item
  Future<int> deleteScheduleItem(int id) async {
    final db = await _dbHelper.database;
    await initializeScheduleTable();
    
    return await db.delete(
      'schedule_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Toggle completion status
  Future<int> toggleCompletion(int id) async {
    final db = await _dbHelper.database;
    await initializeScheduleTable();
    
    final List<Map<String, dynamic>> result = await db.query(
      'schedule_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      final item = ScheduleItem.fromMap(result.first);
      final updatedItem = item.copyWith(
        isCompleted: !item.isCompleted,
        updatedAt: DateTime.now(),
      );
      
      return await db.update(
        'schedule_items',
        updatedItem.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    return 0;
  }

  // Get schedule statistics
  Future<Map<String, int>> getScheduleStats(int tripId) async {
    final db = await _dbHelper.database;
    await initializeScheduleTable();
    
    final List<Map<String, dynamic>> totalResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM schedule_items WHERE trip_id = ?',
      [tripId],
    );
    
    final List<Map<String, dynamic>> completedResult = await db.rawQuery(
      'SELECT COUNT(*) as completed FROM schedule_items WHERE trip_id = ? AND is_completed = 1',
      [tripId],
    );
    
    final int total = totalResult.first['total'] ?? 0;
    final int completed = completedResult.first['completed'] ?? 0;
    
    return {
      'total': total,
      'completed': completed,
      'pending': total - completed,
    };
  }

  // Search schedule items
  Future<List<ScheduleItem>> searchScheduleItems(int tripId, String query) async {
    final db = await _dbHelper.database;
    await initializeScheduleTable();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'schedule_items',
      where: 'trip_id = ? AND (title LIKE ? OR description LIKE ? OR location LIKE ?)',
      whereArgs: [tripId, '%$query%', '%$query%', '%$query%'],
      orderBy: 'start_time ASC',
    );
    
    return List.generate(maps.length, (i) => ScheduleItem.fromMap(maps[i]));
  }

  // Get schedule items by category
  Future<List<ScheduleItem>> getScheduleItemsByCategory(int tripId, String category) async {
    final db = await _dbHelper.database;
    await initializeScheduleTable();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'schedule_items',
      where: 'trip_id = ? AND category = ?',
      whereArgs: [tripId, category],
      orderBy: 'start_time ASC',
    );
    
    return List.generate(maps.length, (i) => ScheduleItem.fromMap(maps[i]));
  }

  // Get upcoming schedule items
  Future<List<ScheduleItem>> getUpcomingScheduleItems(int tripId, {int limit = 5}) async {
    final db = await _dbHelper.database;
    await initializeScheduleTable();
    
    final now = DateTime.now();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'schedule_items',
      where: 'trip_id = ? AND start_time > ? AND is_completed = 0',
      whereArgs: [tripId, now.toIso8601String()],
      orderBy: 'start_time ASC',
      limit: limit,
    );
    
    return List.generate(maps.length, (i) => ScheduleItem.fromMap(maps[i]));
  }

  // Delete all schedule items for a trip
  Future<int> deleteAllScheduleItems(int tripId) async {
    final db = await _dbHelper.database;
    await initializeScheduleTable();
    
    return await db.delete(
      'schedule_items',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
  }
}