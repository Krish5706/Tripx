import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tripx/screens/trip_details/expenses.dart';

class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'travel_expenses.db');
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('expenses', orderBy: 'timestamp DESC');
    return maps.map((map) => Expense(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      category: map['category'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    )).toList();
  }

  Future<void> addExpense(String description, double amount, String category) async {
    final db = await database;
    await db.insert('expenses', {
      'description': description.trim(),
      'amount': amount,
      'category': category.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateExpense(int id, String description, double amount, String category) async {
    final db = await database;
    await db.update(
      'expenses',
      {
        'description': description.trim(),
        'amount': amount,
        'category': category.trim(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}