import 'dart:async';
import 'dart:convert';
import 'db_helper.dart';

class Trip {
  final int? id;
  final String name;
  final String destination;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String budget;
  final List<String> activities;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    this.id,
    required this.name,
    required this.destination,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.activities,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'budget': budget,
      'activities': jsonEncode(activities),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      name: map['name'],
      destination: map['destination'],
      description: map['description'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      budget: map['budget'],
      activities: List<String>.from(jsonDecode(map['activities'] ?? '[]')),
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Trip copyWith({
    int? id,
    String? name,
    String? destination,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? budget,
    List<String>? activities,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      activities: activities ?? this.activities,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get duration => endDate.difference(startDate).inDays + 1;
  
  bool get isUpcoming => startDate.isAfter(DateTime.now());
  
  bool get isOngoing => DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  
  bool get isCompleted => DateTime.now().isAfter(endDate);
}

class TripService {
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Initialize trips table
  Future<void> initializeTripsTable() async {
    final db = await _dbHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        destination TEXT NOT NULL,
        description TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        budget TEXT,
        activities TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // Create a new trip
  Future<int> createTrip(Trip trip) async {
    final db = await _dbHelper.database;
    await initializeTripsTable();
    
    final now = DateTime.now();
    final tripWithTimestamps = trip.copyWith(
      createdAt: now,
      updatedAt: now,
    );
    
    return await db.insert('trips', tripWithTimestamps.toMap());
  }

  // Get all trips
  Future<List<Trip>> getAllTrips() async {
    final db = await _dbHelper.database;
    await initializeTripsTable();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) => Trip.fromMap(maps[i]));
  }

  // Get trip by ID
  Future<Trip?> getTripById(int id) async {
    final db = await _dbHelper.database;
    await initializeTripsTable();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    }
    return null;
  }

  // Update a trip
  Future<int> updateTrip(Trip trip) async {
    final db = await _dbHelper.database;
    await initializeTripsTable();
    
    final updatedTrip = trip.copyWith(updatedAt: DateTime.now());
    
    return await db.update(
      'trips',
      updatedTrip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  // Delete a trip
  Future<int> deleteTrip(int id) async {
    final db = await _dbHelper.database;
    await initializeTripsTable();
    
    return await db.delete(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search trips
  Future<List<Trip>> searchTrips(String query) async {
    final db = await _dbHelper.database;
    await initializeTripsTable();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      where: 'name LIKE ? OR destination LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) => Trip.fromMap(maps[i]));
  }

  // Get upcoming trips
  Future<List<Trip>> getUpcomingTrips() async {
    final trips = await getAllTrips();
    final now = DateTime.now();
    return trips.where((trip) => trip.startDate.isAfter(now)).toList();
  }

  // Get ongoing trips
  Future<List<Trip>> getOngoingTrips() async {
    final trips = await getAllTrips();
    final now = DateTime.now();
    return trips.where((trip) => 
      now.isAfter(trip.startDate) && now.isBefore(trip.endDate)
    ).toList();
  }

  // Get completed trips
  Future<List<Trip>> getCompletedTrips() async {
    final trips = await getAllTrips();
    final now = DateTime.now();
    return trips.where((trip) => now.isAfter(trip.endDate)).toList();
  }

  // Get trip statistics
  Future<Map<String, int>> getTripStats() async {
    final trips = await getAllTrips();
    final now = DateTime.now();
    
    int upcoming = 0;
    int ongoing = 0;
    int completed = 0;
    
    for (final trip in trips) {
      if (trip.startDate.isAfter(now)) {
        upcoming++;
      } else if (now.isAfter(trip.startDate) && now.isBefore(trip.endDate)) {
        ongoing++;
      } else if (now.isAfter(trip.endDate)) {
        completed++;
      }
    }
    
    return {
      'total': trips.length,
      'upcoming': upcoming,
      'ongoing': ongoing,
      'completed': completed,
    };
  }
}