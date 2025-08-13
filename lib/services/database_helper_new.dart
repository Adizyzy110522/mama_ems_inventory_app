// lib/services/database_helper.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;
  final Completer<void> _initializationCompleter = Completer<void>();
  bool _isInitializing = false;

  /// Returns the database instance, initializing it if necessary.
  /// Uses a Completer to prevent multiple simultaneous initializations.
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Wait if initialization is already in progress
    if (_isInitializing) {
      await _initializationCompleter.future;
      return _database!;
    }
    
    try {
      _isInitializing = true;
      _database = await _initDatabase();
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
    } catch (e) {
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.completeError(e);
      }
      rethrow;
    } finally {
      _isInitializing = false;
    }
    
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path;
      
      if (kIsWeb) {
        // For web, use a simple name as path is virtual anyway
        path = 'orders_database.db';
        debugPrint('Using web database path: $path');
      } else {
        // For native platforms, use the file system
        path = join(await getDatabasesPath(), 'orders.db');
        debugPrint('Using native database path: $path');
      }
      
      return await openDatabase(
        path,
        version: 3, // Upgraded from version 2 to 3 to add packsProduced field
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      debugPrint('Database initialization error: $e');
      rethrow;
    }
  }

  /// Handles database creation when the database is first created
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        storeName TEXT NOT NULL,
        personInCharge TEXT NOT NULL,
        contactNumber TEXT, 
        packsOrdered INTEGER NOT NULL,
        packsProduced INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        paymentStatus TEXT NOT NULL,
        notes TEXT,
        orderDate TEXT NOT NULL,
        deliveryDate TEXT
      )
    ''');

    // Insert sample data only in debug mode
    if (kDebugMode) {
      await _insertSampleData(db);
    }
  }
  
  /// Handles database upgrades when version changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    
    // Add migration logic here as the app evolves
    if (oldVersion < 2) {
      // Add contactNumber column to the orders table
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN contactNumber TEXT;');
        debugPrint('Successfully added contactNumber column to orders table');
      } catch (e) {
        debugPrint('Error adding contactNumber column: $e');
      }
    }
    
    if (oldVersion < 3) {
      // Add packsProduced column to the orders table
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN packsProduced INTEGER NOT NULL DEFAULT 0;');
        debugPrint('Successfully added packsProduced column to orders table');
      } catch (e) {
        debugPrint('Error adding packsProduced column: $e');
      }
    }
  }

  Future<void> _insertSampleData(Database db) async {
    final sampleOrders = [
      {
        'id': 'order_001',
        'storeName': 'FreshMart Grocery',
        'personInCharge': 'Anna Lopez',
        'packsOrdered': 25,
        'packsProduced': 15,
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
        'packsProduced': 20,
        'status': 'Processing',
        'paymentStatus': 'Pending',
        'notes': 'Urgent order',
        'orderDate': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        'deliveryDate': null,
      },
      {
        'id': 'order_003',
        'storeName': 'Downtown Market',
        'personInCharge': 'Maria Garcia',
        'packsOrdered': 15,
        'packsProduced': 15,
        'status': 'Completed',
        'paymentStatus': 'Paid',
        'notes': 'Regular customer',
        'orderDate': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
        'deliveryDate': DateTime.now().add(Duration(days: 2)).toIso8601String(),
      },
    ];

    for (var order in sampleOrders) {
      await db.insert('orders', order);
    }
    debugPrint('Sample data inserted successfully');
  }
  
  /// Safe query wrapper with better error handling
  Future<List<Map<String, dynamic>>> safeQuery(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error querying $table: $e');
      // Return empty list instead of throwing to make the app more robust
      return [];
    }
  }

  Future<List<Order>> getAllOrders() async {
    try {
      final maps = await safeQuery(
        'orders',
        orderBy: 'orderDate DESC',
      );

      return List.generate(maps.length, (i) {
        try {
          return Order.fromMap(maps[i]);
        } catch (e) {
          debugPrint('Error parsing order at index $i: $e');
          return Order(
            id: 'error_${DateTime.now().millisecondsSinceEpoch}_$i',
            storeName: 'Error Loading Order',
            personInCharge: '',
            packsOrdered: 0,
            status: 'Error',
            paymentStatus: 'Unknown',
            notes: 'There was an error loading this order: $e',
            orderDate: DateTime.now(),
          );
        }
      });
    } catch (e) {
      debugPrint('Error getting all orders: $e');
      return [];
    }
  }

  Future<Order?> getOrder(String id) async {
    try {
      final maps = await safeQuery(
        'orders',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        return null;
      }

      return Order.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error getting order $id: $e');
      rethrow;
    }
  }

  Future<void> insertOrder(Order order) async {
    try {
      final db = await database;
      await db.insert(
        'orders',
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error inserting order: $e');
      rethrow;
    }
  }

  Future<void> updateOrder(Order order) async {
    try {
      final db = await database;
      await db.update(
        'orders',
        order.toMap(),
        where: 'id = ?',
        whereArgs: [order.id],
      );
    } catch (e) {
      debugPrint('Error updating order ${order.id}: $e');
      rethrow;
    }
  }

  Future<int> deleteOrder(String id) async {
    try {
      final db = await database;
      return await db.delete(
        'orders',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting order $id: $e');
      rethrow;
    }
  }

  Future<List<Order>> getOrdersByStatus(String status) async {
    try {
      final maps = await safeQuery(
        'orders',
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'orderDate DESC',
      );

      return List.generate(maps.length, (i) {
        try {
          return Order.fromMap(maps[i]);
        } catch (e) {
          debugPrint('Error parsing order with status $status at index $i: $e');
          return Order(
            id: 'error_${DateTime.now().millisecondsSinceEpoch}_$i',
            storeName: 'Error Loading Order',
            personInCharge: '',
            packsOrdered: 0,
            status: status,
            paymentStatus: 'Unknown',
            notes: 'There was an error loading this order: $e',
            orderDate: DateTime.now(),
          );
        }
      });
    } catch (e) {
      debugPrint('Error getting orders by status $status: $e');
      return [];
    }
  }
  
  Future<List<Order>> getOrdersByPaymentStatus(String paymentStatus) async {
    try {
      final maps = await safeQuery(
        'orders',
        where: 'paymentStatus = ?',
        whereArgs: [paymentStatus],
        orderBy: 'orderDate DESC',
      );

      return List.generate(maps.length, (i) {
        try {
          return Order.fromMap(maps[i]);
        } catch (e) {
          debugPrint('Error parsing order with payment status $paymentStatus at index $i: $e');
          return Order(
            id: 'error_${DateTime.now().millisecondsSinceEpoch}_$i',
            storeName: 'Error Loading Order',
            personInCharge: '',
            packsOrdered: 0,
            status: 'Unknown',
            paymentStatus: paymentStatus,
            notes: 'There was an error loading this order: $e',
            orderDate: DateTime.now(),
          );
        }
      });
    } catch (e) {
      debugPrint('Error getting orders by payment status $paymentStatus: $e');
      return [];
    }
  }

  Future<Map<String, int>> getOrderStatistics() async {
    try {
      final db = await database;
      
      // Get count of orders by status
      final completedOrders = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM orders WHERE status = ?',
        ['Completed'],
      )) ?? 0;
      
      final pendingOrders = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM orders WHERE status = ?',
        ['Pending'],
      )) ?? 0;
      
      final processingOrders = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM orders WHERE status = ?',
        ['Processing'],
      )) ?? 0;
      
      final holdOrders = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM orders WHERE status = ?',
        ['Hold'],
      )) ?? 0;
      
      final cancelledOrders = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM orders WHERE status = ?',
        ['Cancelled'],
      )) ?? 0;
      
      // Get count of orders by payment status
      final paidOrders = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM orders WHERE paymentStatus = ?',
        ['Paid'],
      )) ?? 0;
      
      // Combine the active (non-completed, non-cancelled) orders
      final activeOrders = pendingOrders + processingOrders + holdOrders;
      
      return {
        'completed': completedOrders,
        'cancelled': cancelledOrders,
        'pending': activeOrders, // All non-completed, non-cancelled orders
        'paid': paidOrders,
      };
    } catch (e) {
      debugPrint('Error getting order statistics: $e');
      return {
        'completed': 0,
        'cancelled': 0,
        'pending': 0,
        'paid': 0,
      };
    }
  }
}
