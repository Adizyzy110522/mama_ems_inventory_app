// lib/services/database_helper.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order.dart';
import '../config/product_config.dart';

class DatabaseHelper {
  // Static cache of database helpers per product category
  static final Map<String, DatabaseHelper> _instances = {};
  
  // Factory constructor that creates/returns instance for specific product category
  factory DatabaseHelper({String productCategory = 'banana'}) {
    if (!_instances.containsKey(productCategory)) {
      _instances[productCategory] = DatabaseHelper._internal(productCategory);
    }
    return _instances[productCategory]!;
  }
  
  // The product category this instance is for
  final String productCategory;
  
  // Private constructor
  DatabaseHelper._internal(this.productCategory);

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
        path = 'orders_${productCategory}_database.db';
        debugPrint('Using web database path for $productCategory: $path');
      } else {
        // For native platforms, use the file system
        path = join(await getDatabasesPath(), 'orders_$productCategory.db');
        debugPrint('Using native database path for $productCategory: $path');
        
        // During development, force recreate the database to apply schema changes
        if (kDebugMode) {
          try {
            await deleteDatabase(path);
            debugPrint('Deleted old database for $productCategory to force schema update');
          } catch (e) {
            debugPrint('Error deleting database: $e');
          }
        }
      }
      
      return await openDatabase(
        path,
        version: 4, // Upgraded to version 4 to add packaging and pricing fields
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
        deliveryDate TEXT,
        packType TEXT NOT NULL DEFAULT 'Stand Pouch',
        priceType TEXT NOT NULL DEFAULT 'Wholesale',
        unitPrice REAL NOT NULL DEFAULT 0.0,
        totalPrice REAL NOT NULL DEFAULT 0.0
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
    
    if (oldVersion < 4) {
      // Add new packaging and pricing columns
      try {
        // SQLite has limited ALTER TABLE support, so we add one column at a time
        await db.execute('ALTER TABLE orders ADD COLUMN packType TEXT NOT NULL DEFAULT \'Stand Pouch\';');
        await db.execute('ALTER TABLE orders ADD COLUMN priceType TEXT NOT NULL DEFAULT \'Wholesale\';');
        await db.execute('ALTER TABLE orders ADD COLUMN unitPrice REAL NOT NULL DEFAULT 0.0;');
        await db.execute('ALTER TABLE orders ADD COLUMN totalPrice REAL NOT NULL DEFAULT 0.0;');
        debugPrint('Successfully added packaging and pricing columns to orders table');
      } catch (e) {
        debugPrint('Error adding packaging and pricing columns: $e');
      }
    }
    //   await db.execute('ALTER TABLE orders ADD COLUMN priority TEXT');
    // }
  }

  Future<void> _insertSampleData(Database db) async {
    // Different sample data based on product category
    List<Map<String, dynamic>> sampleOrders = [];
    
    switch (productCategory) {
      case 'banana':
        sampleOrders = [
          {
            'id': 'banana_001',
            'storeName': 'FreshMart Grocery',
            'personInCharge': 'Anna Lopez',
            'packsOrdered': 25,
            'packsProduced': 15,
            'status': 'Processing',
            'paymentStatus': 'Paid',
            'notes': 'Deliver banana chips before Friday morning',
            'orderDate': DateTime.now().toIso8601String(),
            'deliveryDate': null,
            'packType': 'Stand Pouch',
            'priceType': 'Wholesale',
            'unitPrice': 70.0,
            'totalPrice': 1750.0,
          },
          {
            'id': 'banana_002',
            'storeName': 'City Deli',
            'personInCharge': 'Mark Santos',
            'packsOrdered': 40,
            'packsProduced': 20,
            'status': 'Hold',
            'paymentStatus': 'Pending',
            'notes': 'Urgent banana chips order - on hold',
            'orderDate': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
            'deliveryDate': null,
            'packType': 'Square Pack',
            'priceType': 'Retail',
            'unitPrice': 35.0,
            'totalPrice': 1400.0,
          },
          {
            'id': 'banana_003',
            'storeName': 'Banana King',
            'personInCharge': 'Carla Reyes',
            'packsOrdered': 12,
            'packsProduced': 12,
            'status': 'Processing',
            'paymentStatus': 'Paid',
            'notes': 'No rush banana chips delivery',
            'orderDate': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
            'deliveryDate': null,
            'packType': 'Stand Pouch',
            'priceType': 'Retail',
            'unitPrice': 100.0,
            'totalPrice': 1200.0,
          },
          {
            'id': 'banana_004',
            'storeName': 'GreenLeaf Market',
            'personInCharge': 'Joey Fernandez',
            'packsOrdered': 30,
            'packsProduced': 0,
            'status': 'Processing',
            'paymentStatus': 'Paid',
            'notes': 'Fragile banana chips packaging',
            'orderDate': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
            'deliveryDate': null,
            'packType': 'Square Pack',
            'priceType': 'Wholesale',
            'unitPrice': 20.0,
            'totalPrice': 600.0,
          },
        ];
        break;
        
      case 'karlang':
        sampleOrders = [
          {
            'id': 'karlang_001',
            'storeName': 'Snack Haven',
            'personInCharge': 'Miguel Cruz',
            'packsOrdered': 20,
            'packsProduced': 10,
            'status': 'Processing',
            'paymentStatus': 'Paid',
            'notes': 'Regular karlang chips customer',
            'orderDate': DateTime.now().toIso8601String(),
            'deliveryDate': null,
            'packType': 'Stand Pouch',
            'priceType': 'Wholesale',
            'unitPrice': 70.0,
            'totalPrice': 1400.0,
          },
          {
            'id': 'karlang_002',
            'storeName': 'Corner Store',
            'personInCharge': 'Teresa Lim',
            'packsOrdered': 15,
            'packsProduced': 15,
            'status': 'Completed',
            'paymentStatus': 'Paid',
            'notes': 'Karlang chips special packaging',
            'orderDate': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
            'deliveryDate': null,
            'packType': 'Square Pack',
            'priceType': 'Retail',
            'unitPrice': 35.0,
            'totalPrice': 525.0,
          },
          {
            'id': 'karlang_003',
            'storeName': 'Filipino Delights',
            'personInCharge': 'Ramon Diaz',
            'packsOrdered': 35,
            'packsProduced': 0,
            'status': 'Hold',
            'paymentStatus': 'Pending',
            'notes': 'Big karlang chips order for event - on hold',
            'orderDate': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
            'deliveryDate': null,
            'packType': 'Stand Pouch',
            'priceType': 'Wholesale',
            'unitPrice': 70.0,
            'totalPrice': 2450.0,
          },
        ];
        break;
        
      case 'kamote':
        sampleOrders = [
          {
            'id': 'kamote_001',
            'storeName': 'Sweet Treats',
            'personInCharge': 'Elena Santos',
            'packsOrdered': 18,
            'packsProduced': 10,
            'status': 'Processing',
            'paymentStatus': 'Pending',
            'notes': 'Kamote chips for weekend market',
            'orderDate': DateTime.now().toIso8601String(),
            'deliveryDate': null,
            'packType': 'Square Pack',
            'priceType': 'Wholesale',
            'unitPrice': 20.0,
            'totalPrice': 360.0,
          },
          {
            'id': 'kamote_002',
            'storeName': 'Local Grocery',
            'personInCharge': 'Pedro Mendoza',
            'packsOrdered': 25,
            'packsProduced': 25,
            'status': 'Completed',
            'paymentStatus': 'Paid',
            'notes': 'Regular kamote chips order',
            'orderDate': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
            'deliveryDate': null,
            'packType': 'Stand Pouch',
            'priceType': 'Retail',
            'unitPrice': 100.0,
            'totalPrice': 2500.0,
          },
          {
            'id': 'kamote_003',
            'storeName': 'School Canteen',
            'personInCharge': 'Marissa Cruz',
            'packsOrdered': 40,
            'packsProduced': 20,
            'status': 'Processing',
            'paymentStatus': 'Paid',
            'notes': 'Monthly kamote chips supply',
            'orderDate': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
            'deliveryDate': null,
            'packType': 'Stand Pouch',
            'priceType': 'Wholesale',
            'unitPrice': 70.0,
            'totalPrice': 2800.0,
          },
          {
            'id': 'kamote_004',
            'storeName': 'Island Cafe',
            'personInCharge': 'James Reyes',
            'packsOrdered': 10,
            'packsProduced': 0,
            'status': 'Pending',
            'paymentStatus': 'Pending',
            'notes': 'Small kamote chips batch',
            'orderDate': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
            'deliveryDate': null,
            'packType': 'Square Pack',
            'priceType': 'Retail',
            'unitPrice': 35.0,
            'totalPrice': 350.0,
          },
        ];
        break;
      
      default:
        // Default case should not happen, but providing fallback data just in case
        sampleOrders = [
          {
            'id': 'default_001',
            'storeName': 'Sample Store',
            'personInCharge': 'Sample Person',
            'packsOrdered': 10,
            'packsProduced': 0,
            'status': 'Pending',
            'paymentStatus': 'Pending',
            'notes': 'Sample order',
            'orderDate': DateTime.now().toIso8601String(),
            'deliveryDate': null,
            'packType': 'Stand Pouch',
            'priceType': 'Wholesale',
            'unitPrice': 70.0,
            'totalPrice': 700.0,
          },
        ];
    }

    for (var order in sampleOrders) {
      await db.insert('orders', order);
    }
  }

  // CRUD Operations
  Future<int> insertOrder(Order order) async {
    try {
      final db = await database;
      return await db.insert('orders', order.toMap(), 
        conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error inserting order: $e');
      rethrow;
    }
  }

  Future<List<Order>> getAllOrders() async {
    try {
      final maps = await safeQuery('orders');
      
      return List.generate(maps.length, (i) {
        try {
          return Order.fromMap(maps[i]);
        } catch (e) {
          debugPrint('Error parsing order at index $i: $e');
          // Return a placeholder order to prevent app crash, but mark it as invalid
          return Order(
            id: 'error_${DateTime.now().millisecondsSinceEpoch}_$i',
            storeName: 'Error Loading Order',
            personInCharge: '',
            packsOrdered: 0,
            status: 'Processing', // Use a valid status
            paymentStatus: 'Pending', // Use a valid payment status
            notes: 'There was an error loading this order: $e',
            orderDate: DateTime.now(),
            packType: ProductConfig.standPouch,
            priceType: ProductConfig.wholesale,
            unitPrice: 0.0,
            totalPrice: 0.0,
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

      if (maps.isNotEmpty) {
        return Order.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting order $id: $e');
      return null;
    }
  }

  Future<int> updateOrder(Order order) async {
    try {
      final db = await database;
      return await db.update(
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
            paymentStatus: 'Pending',
            notes: 'There was an error loading this order: $e',
            orderDate: DateTime.now(),
            packType: ProductConfig.standPouch,
            priceType: ProductConfig.wholesale,
            unitPrice: 0.0,
            totalPrice: 0.0,
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
      final maps = paymentStatus == 'Unpaid' 
        ? await safeQuery(
            'orders',
            where: 'paymentStatus != ?',
            whereArgs: ['Paid'],
          )
        : await safeQuery(
            'orders',
            where: 'paymentStatus = ?',
            whereArgs: [paymentStatus],
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
            status: 'Processing',
            paymentStatus: paymentStatus,
            notes: 'There was an error loading this order: $e',
            orderDate: DateTime.now(),
            packType: ProductConfig.standPouch,
            priceType: ProductConfig.wholesale,
            unitPrice: 0.0,
            totalPrice: 0.0,
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
      
      // Use a single transaction to get all statistics for better performance and consistency
      return await db.transaction((txn) async {
        final completed = await txn.rawQuery(
          'SELECT COUNT(*) as count FROM orders WHERE status = ?',
          ['Completed']
        );
        final cancelled = await txn.rawQuery(
          'SELECT COUNT(*) as count FROM orders WHERE status = ?',
          ['Cancelled']
        );
        final pending = await txn.rawQuery(
          'SELECT COUNT(*) as count FROM orders WHERE status = ?',
          ['Processing']
        );
        final hold = await txn.rawQuery(
          'SELECT COUNT(*) as count FROM orders WHERE status = ?',
          ['Hold']
        );
        final paid = await txn.rawQuery(
          'SELECT COUNT(*) as count FROM orders WHERE paymentStatus = ?',
          ['Paid']
        );
        final unpaid = await txn.rawQuery(
          'SELECT COUNT(*) as count FROM orders WHERE paymentStatus != ?',
          ['Paid']
        );

        return {
          'completed': completed.isNotEmpty ? (completed.first['count'] as int? ?? 0) : 0,
          'cancelled': cancelled.isNotEmpty ? (cancelled.first['count'] as int? ?? 0) : 0,
          'pending': pending.isNotEmpty ? (pending.first['count'] as int? ?? 0) : 0,
          'hold': hold.isNotEmpty ? (hold.first['count'] as int? ?? 0) : 0,
          'paid': paid.isNotEmpty ? (paid.first['count'] as int? ?? 0) : 0,
          'unpaid': unpaid.isNotEmpty ? (unpaid.first['count'] as int? ?? 0) : 0,
        };
      });
    } catch (e) {
      debugPrint('Error getting order statistics: $e');
      // Return default values if we can't get statistics
      return {
        'completed': 0,
        'cancelled': 0,
        'pending': 0,
        'hold': 0,
        'paid': 0,
        'unpaid': 0,
      };
    }
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('Database connection closed');
    }
  }
  
  /// Execute a transaction with proper error handling
  Future<T> executeTransaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    try {
      return await db.transaction(action);
    } catch (e) {
      debugPrint('Transaction error: $e');
      rethrow;
    }
  }
  
  /// Safe database query with error handling
  Future<List<Map<String, dynamic>>> safeQuery(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
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
      debugPrint('Query error: $e');
      rethrow;
    }
  }
}