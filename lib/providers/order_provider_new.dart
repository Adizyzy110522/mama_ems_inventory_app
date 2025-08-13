// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/database_helper.dart';

class OrderProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  List<Order> _orders = [];
  Map<String, int> _statistics = {
    'completed': 0,
    'cancelled': 0,
    'pending': 0,
    'paid': 0,
  };
  
  bool _isLoading = false;
  String? _lastError;
  String? _activeFilter;
  
  // Pagination support
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMoreOrders = true;

  List<Order> get orders => _orders;
  Map<String, int> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get hasMoreOrders => _hasMoreOrders;
  String? get activeFilter => _activeFilter;

  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _orders = [];
      _currentPage = 0;
      _hasMoreOrders = true;
      _activeFilter = null;
    }
    
    if (_isLoading || (!_hasMoreOrders && !refresh)) return;
    
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    
    try {
      // For now, we'll load all orders until we implement pagination in the database helper
      if (_orders.isEmpty || refresh) {
        _orders = await _databaseHelper.getAllOrders();
        await loadStatistics();
      }
      
      // Placeholder for future pagination implementation
      // final newOrders = await _databaseHelper.getOrdersPaginated(_currentPage, _pageSize);
      // _hasMoreOrders = newOrders.length == _pageSize;
      // if (refresh) {
      //   _orders = newOrders;
      // } else {
      //   _orders.addAll(newOrders);
      // }
      // _currentPage++;
      
    } catch (e) {
      _lastError = 'Error loading orders: $e';
      debugPrint(_lastError);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStatistics() async {
    try {
      _statistics = await _databaseHelper.getOrderStatistics();
      notifyListeners();
    } catch (e) {
      _lastError = 'Error loading statistics: $e';
      debugPrint(_lastError);
    }
  }
  
  /// Load orders filtered by status
  Future<void> loadOrdersByStatus(String status) async {
    _isLoading = true;
    _activeFilter = "Status: $status";
    _lastError = null;
    notifyListeners();
    
    try {
      _orders = await _databaseHelper.getOrdersByStatus(status);
    } catch (e) {
      _lastError = 'Error loading orders by status: $e';
      debugPrint(_lastError);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load orders filtered by payment status
  Future<void> loadOrdersByPaymentStatus(String paymentStatus) async {
    _isLoading = true;
    _activeFilter = "Payment: $paymentStatus";
    _lastError = null;
    notifyListeners();
    
    try {
      _orders = await _databaseHelper.getOrdersByPaymentStatus(paymentStatus);
    } catch (e) {
      _lastError = 'Error loading orders by payment status: $e';
      debugPrint(_lastError);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Clear filters and reload all orders
  Future<void> clearFilters() async {
    _activeFilter = null;
    await loadOrders(refresh: true);
  }
  
  /// Reload data when error occurred
  Future<void> retryLastOperation() async {
    if (_lastError != null) {
      _lastError = null;
      await loadOrders(refresh: true);
    }
  }

  Future<void> addOrder(Order order) async {
    try {
      await _databaseHelper.insertOrder(order);
      _orders.add(order);
      await loadStatistics();
      notifyListeners();
    } catch (e) {
      print('Error adding order: $e');
    }
  }

  Future<void> updateOrder(Order order) async {
    try {
      await _databaseHelper.updateOrder(order);
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = order;
      }
      await loadStatistics();
      notifyListeners();
    } catch (e) {
      print('Error updating order: $e');
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _databaseHelper.deleteOrder(id);
      _orders.removeWhere((order) => order.id == id);
      await loadStatistics();
      notifyListeners();
    } catch (e) {
      print('Error deleting order: $e');
    }
  }
  
  Future<void> updateOrderProgress(String orderId, int packsProduced) async {
    try {
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index == -1) return;
      
      // Get the current order
      final currentOrder = _orders[index];
      
      // Create a new order with updated packs produced
      final updatedOrder = Order(
        id: currentOrder.id,
        storeName: currentOrder.storeName,
        personInCharge: currentOrder.personInCharge,
        contactNumber: currentOrder.contactNumber,
        packsOrdered: currentOrder.packsOrdered,
        packsProduced: packsProduced,
        status: currentOrder.status,
        paymentStatus: currentOrder.paymentStatus,
        notes: currentOrder.notes,
        orderDate: currentOrder.orderDate,
        deliveryDate: currentOrder.deliveryDate,
      );
      
      // Update in database and memory
      await _databaseHelper.updateOrder(updatedOrder);
      _orders[index] = updatedOrder;
      
      notifyListeners();
    } catch (e) {
      print('Error updating order progress: $e');
    }
  }
}
