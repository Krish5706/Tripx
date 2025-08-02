import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'db_helper.dart';

enum Priority { low, medium, high }

class PackingItem {
  int? id;
  String name;
  String category;
  bool isPacked;
  int quantity;
  Priority priority;
  int userId;
  int? tripId;
  DateTime createdAt;
  DateTime updatedAt;

  PackingItem({
    this.id,
    required this.name,
    required this.category,
    this.isPacked = false,
    this.quantity = 1,
    this.priority = Priority.medium,
    required this.userId,
    this.tripId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'is_packed': isPacked ? 1 : 0,
      'quantity': quantity,
      'priority': priority.index,
      'user_id': userId,
      'trip_id': tripId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static PackingItem fromMap(Map<String, dynamic> map) {
    return PackingItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      isPacked: map['is_packed'] == 1,
      quantity: map['quantity'],
      priority: Priority.values[map['priority']],
      userId: map['user_id'],
      tripId: map['trip_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  PackingItem copyWith({
    int? id,
    String? name,
    String? category,
    bool? isPacked,
    int? quantity,
    Priority? priority,
    int? userId,
    int? tripId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isPacked: isPacked ?? this.isPacked,
      quantity: quantity ?? this.quantity,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PackingService {
  static final PackingService _instance = PackingService._internal();
  factory PackingService() => _instance;
  PackingService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Initialize database tables for packing items
  Future<void> initializePackingTables({bool clearExisting = false}) async {
    final db = await _dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS packing_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            is_packed INTEGER NOT NULL DEFAULT 0,
            quantity INTEGER NOT NULL DEFAULT 1,
            priority INTEGER NOT NULL DEFAULT 1,
            user_id INTEGER NOT NULL,
            trip_id INTEGER,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        await txn.execute('''
          CREATE INDEX IF NOT EXISTS idx_packing_items_user_id 
          ON packing_items (user_id)
        ''');

        await txn.execute('''
          CREATE INDEX IF NOT EXISTS idx_packing_items_trip_id 
          ON packing_items (trip_id)
        ''');

        await txn.execute('''
          CREATE INDEX IF NOT EXISTS idx_packing_items_category 
          ON packing_items (category)
        ''');

        if (clearExisting) {
          await txn.delete('packing_items');
          log('Cleared existing packing items during initialization', name: 'PackingService');
        }
      });

      log('Packing tables initialized successfully${clearExisting ? ' and cleared' : ''}', name: 'PackingService');
    } catch (e) {
      log('Error initializing packing tables: $e', name: 'PackingService');
      rethrow;
    }
  }

  // Add a new packing item
  Future<int?> addPackingItem(PackingItem item) async {
    final db = await _dbHelper.database;
    
    try {
      item.updatedAt = DateTime.now();
      final id = await db.insert('packing_items', item.toMap());
      log('Added packing item: ${item.name}', name: 'PackingService');
      return id;
    } catch (e) {
      log('Error adding packing item: $e', name: 'PackingService');
      return null;
    }
  }

  // Get all packing items for a user
  Future<List<PackingItem>> getPackingItems(int userId, {int? tripId}) async {
    final db = await _dbHelper.database;
    
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId];
      
      if (tripId != null) {
        whereClause += ' AND trip_id = ?';
        whereArgs.add(tripId);
      }

      final maps = await db.query(
        'packing_items',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'priority DESC, created_at ASC',
      );

      return maps.map((map) => PackingItem.fromMap(map)).toList();
    } catch (e) {
      log('Error getting packing items: $e', name: 'PackingService');
      return [];
    }
  }

  // Get packing items by category
  Future<List<PackingItem>> getPackingItemsByCategory(
    int userId, 
    String category, 
    {int? tripId}
  ) async {
    final db = await _dbHelper.database;
    
    try {
      String whereClause = 'user_id = ? AND category = ?';
      List<dynamic> whereArgs = [userId, category];
      
      if (tripId != null) {
        whereClause += ' AND trip_id = ?';
        whereArgs.add(tripId);
      }

      final maps = await db.query(
        'packing_items',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'priority DESC, created_at ASC',
      );

      return maps.map((map) => PackingItem.fromMap(map)).toList();
    } catch (e) {
      log('Error getting packing items by category: $e', name: 'PackingService');
      return [];
    }
  }

  // Update a packing item
  Future<bool> updatePackingItem(PackingItem item) async {
    final db = await _dbHelper.database;
    
    try {
      item.updatedAt = DateTime.now();
      final rowsAffected = await db.update(
        'packing_items',
        item.toMap(),
        where: 'id = ? AND user_id = ?',
        whereArgs: [item.id, item.userId],
      );
      
      if (rowsAffected > 0) {
        log('Updated packing item: ${item.name}', name: 'PackingService');
        return true;
      }
      return false;
    } catch (e) {
      log('Error updating packing item: $e', name: 'PackingService');
      return false;
    }
  }

  // Toggle packed status of an item
  Future<bool> togglePackedStatus(int itemId, int userId) async {
    final db = await _dbHelper.database;
    
    try {
      // First get the current status
      final items = await db.query(
        'packing_items',
        where: 'id = ? AND user_id = ?',
        whereArgs: [itemId, userId],
      );

      if (items.isEmpty) return false;

      final currentStatus = items.first['is_packed'] as int;
      final newStatus = currentStatus == 1 ? 0 : 1;

      final rowsAffected = await db.update(
        'packing_items',
        {
          'is_packed': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [itemId, userId],
      );

      return rowsAffected > 0;
    } catch (e) {
      log('Error toggling packed status: $e', name: 'PackingService');
      return false;
    }
  }

  // Delete a packing item
  Future<bool> deletePackingItem(int itemId, int userId) async {
    final db = await _dbHelper.database;
    
    try {
      final rowsAffected = await db.delete(
        'packing_items',
        where: 'id = ? AND user_id = ?',
        whereArgs: [itemId, userId],
      );
      
      if (rowsAffected > 0) {
        log('Deleted packing item with id: $itemId', name: 'PackingService');
        return true;
      }
      return false;
    } catch (e) {
      log('Error deleting packing item: $e', name: 'PackingService');
      return false;
    }
  }

  // Clear all packing items for a user
  Future<bool> clearAllPackingItems(int userId, {int? tripId}) async {
    final db = await _dbHelper.database;
    
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId];
      
      if (tripId != null) {
        whereClause += ' AND trip_id = ?';
        whereArgs.add(tripId);
      }
      
      final rowsAffected = await db.delete(
        'packing_items',
        where: whereClause,
        whereArgs: whereArgs,
      );
      
      log('Cleared $rowsAffected packing items for user $userId', name: 'PackingService');
      return true;
    } catch (e) {
      log('Error clearing packing items: $e', name: 'PackingService');
      return false;
    }
  }

  // Get packing statistics
  Future<Map<String, dynamic>> getPackingStats(int userId, {int? tripId}) async {
    final db = await _dbHelper.database;
    
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId];
      
      if (tripId != null) {
        whereClause += ' AND trip_id = ?';
        whereArgs.add(tripId);
      }

      // Get total and packed counts
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as total FROM packing_items WHERE $whereClause',
        whereArgs,
      );

      final packedResult = await db.rawQuery(
        'SELECT COUNT(*) as packed FROM packing_items WHERE $whereClause AND is_packed = 1',
        whereArgs,
      );

      // Get category breakdown
      final categoryResult = await db.rawQuery(
        '''
        SELECT category, 
               COUNT(*) as total,
               SUM(is_packed) as packed
        FROM packing_items 
        WHERE $whereClause
        GROUP BY category
        ORDER BY category
        ''',
        whereArgs,
      );

      // Get priority breakdown
      final priorityResult = await db.rawQuery(
        '''
        SELECT priority, 
               COUNT(*) as total,
               SUM(is_packed) as packed
        FROM packing_items 
        WHERE $whereClause
        GROUP BY priority
        ORDER BY priority DESC
        ''',
        whereArgs,
      );

      final totalItems = totalResult.first['total'] as int;
      final packedItems = packedResult.first['packed'] as int;
      final progress = totalItems > 0 ? packedItems / totalItems : 0.0;

      return {
        'totalItems': totalItems,
        'packedItems': packedItems,
        'unpackedItems': totalItems - packedItems,
        'progress': progress,
        'categoryBreakdown': categoryResult,
        'priorityBreakdown': priorityResult,
      };
    } catch (e) {
      log('Error getting packing stats: $e', name: 'PackingService');
      return {
        'totalItems': 0,
        'packedItems': 0,
        'unpackedItems': 0,
        'progress': 0.0,
        'categoryBreakdown': [],
        'priorityBreakdown': [],
      };
    }
  }

  // Search packing items
  Future<List<PackingItem>> searchPackingItems(
    int userId, 
    String query, 
    {int? tripId}
  ) async {
    final db = await _dbHelper.database;
    
    try {
      String whereClause = 'user_id = ? AND name LIKE ?';
      List<dynamic> whereArgs = [userId, '%$query%'];
      
      if (tripId != null) {
        whereClause += ' AND trip_id = ?';
        whereArgs.add(tripId);
      }

      final maps = await db.query(
        'packing_items',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'priority DESC, created_at ASC',
      );

      return maps.map((map) => PackingItem.fromMap(map)).toList();
    } catch (e) {
      log('Error searching packing items: $e', name: 'PackingService');
      return [];
    }
  }

  // Mark all items as packed/unpacked
  Future<bool> markAllItems(int userId, bool isPacked, {int? tripId}) async {
    final db = await _dbHelper.database;
    
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId];
      
      if (tripId != null) {
        whereClause += ' AND trip_id = ?';
        whereArgs.add(tripId);
      }

      final rowsAffected = await db.update(
        'packing_items',
        {
          'is_packed': isPacked ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: whereClause,
        whereArgs: whereArgs,
      );

      log('Marked $rowsAffected items as ${isPacked ? "packed" : "unpacked"}', 
          name: 'PackingService');
      return rowsAffected > 0;
    } catch (e) {
      log('Error marking all items: $e', name: 'PackingService');
      return false;
    }
  }



  // Get unique categories for a user
  Future<List<String>> getUserCategories(int userId, {int? tripId}) async {
    final db = await _dbHelper.database;
    
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId];
      
      if (tripId != null) {
        whereClause += ' AND trip_id = ?';
        whereArgs.add(tripId);
      }

      final maps = await db.rawQuery(
        'SELECT DISTINCT category FROM packing_items WHERE $whereClause ORDER BY category',
        whereArgs,
      );

      return maps.map((map) => map['category'] as String).toList();
    } catch (e) {
      log('Error getting user categories: $e', name: 'PackingService');
      return [];
    }
  }

  // Bulk add items from templates
  Future<bool> addItemsFromTemplate(
    int userId, 
    List<Map<String, dynamic>> templateItems, 
    {int? tripId}
  ) async {
    final db = await _dbHelper.database;
    
    try {
      final batch = db.batch();
      final currentTime = DateTime.now().toIso8601String();

      for (var template in templateItems) {
        // Check if item already exists
        final existing = await db.query(
          'packing_items',
          where: 'user_id = ? AND name = ? AND category = ?${tripId != null ? ' AND trip_id = ?' : ''}',
          whereArgs: tripId != null 
            ? [userId, template['name'], template['category'], tripId]
            : [userId, template['name'], template['category']],
        );

        if (existing.isEmpty) {
          batch.insert('packing_items', {
            'name': template['name'],
            'category': template['category'],
            'is_packed': 0,
            'quantity': template['quantity'] ?? 1,
            'priority': template['priority'] ?? Priority.medium.index,
            'user_id': userId,
            'trip_id': tripId,
            'created_at': currentTime,
            'updated_at': currentTime,
          });
        }
      }

      await batch.commit();
      log('Added ${templateItems.length} items from template', name: 'PackingService');
      return true;
    } catch (e) {
      log('Error adding items from template: $e', name: 'PackingService');
      return false;
    }
  }

  // Export packing list to JSON
  Future<String?> exportPackingList(int userId, {int? tripId}) async {
    try {
      final items = await getPackingItems(userId, tripId: tripId);
      final stats = await getPackingStats(userId, tripId: tripId);
      
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': userId,
        'tripId': tripId,
        'stats': stats,
        'items': items.map((item) => item.toMap()).toList(),
      };

      return jsonEncode(exportData);
    } catch (e) {
      log('Error exporting packing list: $e', name: 'PackingService');
      return null;
    }
  }

  // Import packing list from JSON
  Future<bool> importPackingList(int userId, String jsonData, {int? tripId}) async {
    try {
      final data = jsonDecode(jsonData);
      final items = data['items'] as List;
      
      final templateItems = items.map((item) => {
        'name': item['name'],
        'category': item['category'],
        'quantity': item['quantity'],
        'priority': item['priority'],
      }).toList();

      return await addItemsFromTemplate(userId, templateItems, tripId: tripId);
    } catch (e) {
      log('Error importing packing list: $e', name: 'PackingService');
      return false;
    }
  }

  // Get recent packing items (for suggestions)
  Future<List<String>> getRecentItems(int userId, {int limit = 10}) async {
    final db = await _dbHelper.database;
    
    try {
      final maps = await db.query(
        'packing_items',
        columns: ['name'],
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'updated_at DESC',
        limit: limit,
        distinct: true,
      );

      return maps.map((map) => map['name'] as String).toList();
    } catch (e) {
      log('Error getting recent items: $e', name: 'PackingService');
      return [];
    }
  }

  // Clean up old packing items (older than specified days)
  Future<bool> cleanupOldItems(int userId, int daysOld) async {
    final db = await _dbHelper.database;
    
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final rowsAffected = await db.delete(
        'packing_items',
        where: 'user_id = ? AND created_at < ?',
        whereArgs: [userId, cutoffDate.toIso8601String()],
      );

      log('Cleaned up $rowsAffected old packing items', name: 'PackingService');
      return rowsAffected > 0;
    } catch (e) {
      log('Error cleaning up old items: $e', name: 'PackingService');
      return false;
    }
  }
}