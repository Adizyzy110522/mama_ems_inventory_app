// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'orders.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        storeName TEXT NOT NULL,
        personInCharge TEXT NOT NULL,
        packsOrdered INTEGER NOT NULL,
        status TEXT NOT NULL,
        paymentStatus TEXT NOT NULL,
        notes TEXT,
        orderDate TEXT NOT NULL,
        deliveryDate TEXT
      )
    ''');

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final sampleOrders = [
      {
        'id': 'order_001',
        'storeName': 'FreshMart Grocery',
        'personInCharge': 'Anna Lopez',
        'packsOrdered': 25,
        'status': 'Processing',
        'paymentStatus': 'Paid',
        'notes': 'Deliver before Friday morning',
        'orderDate': DateTime.now().toIso8601String(),
        'deliveryDate': null,
      },
      {
        'id': 'order_002',
        'storeName': 'City Deli',
        'personInCharge': 'Mark Santos',
        'packsOrdered': 40,
        'status': 'Processing',
        'paymentStatus': 'Pending',
        'notes': 'Urgent order',
        'orderDate': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        'deliveryDate': null,
      },
      {
        'id': 'order_003',
        'storeName': 'Banana King',
        'personInCharge': 'Carla Reyes',
        'packsOrdered': 12,
        'status': 'Processing',
        'paymentStatus': 'Paid',
        'notes': 'No rush delivery',
        'orderDate': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'deliveryDate': null,
      },
      {
        'id': 'order_004',
        'storeName': 'GreenLeaf Market',
        'personInCharge': 'Joey Fernandez',
        'packsOrdered': 30,
        'status': 'Processing',
        'paymentStatus': 'Paid',
        'notes': 'Fragile packaging',
        'orderDate': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
        'deliveryDate': null,
      },
    ];

    for (var order in sampleOrders) {
      await db.insert('orders', order);
    }
  }

  // CRUD Operations
  Future<int> insertOrder(Order order) async {
    final db = await database;
    return await db.insert('orders', order.toMap());
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('orders');
    
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  Future<Order?> getOrder(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Order.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;
    return await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> deleteOrder(String id) async {
    final db = await database;
    return await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Order>> getOrdersByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'status = ?',
      whereArgs: [status],
    );

    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  Future<Map<String, int>> getOrderStatistics() async {
    final db = await database;
    
    final completed = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE status = ?',
      ['Completed']
    );
    final cancelled = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE status = ?',
      ['Cancelled']
    );
    final pending = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE status = ?',
      ['Processing']
    );
    final paid = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE paymentStatus = ?',
      ['Paid']
    );

    return {
      'completed': completed.first['count'] as int,
      'cancelled': cancelled.first['count'] as int,
      'pending': pending.first['count'] as int,
      'paid': paid.first['count'] as int,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}