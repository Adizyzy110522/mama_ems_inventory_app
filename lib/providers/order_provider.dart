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
  
  // Pagination support
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMoreOrders = true;

  List<Order> get orders => _orders;
  Map<String, int> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get hasMoreOrders => _hasMoreOrders;

  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _orders = [];
      _currentPage = 0;
      _hasMoreOrders = true;
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

  Future<void> deleteOrder(String orderId) async {
    try {
      await _databaseHelper.deleteOrder(orderId);
      _orders.removeWhere((order) => order.id == orderId);
      await loadStatistics();
      notifyListeners();
    } catch (e) {
      print('Error deleting order: $e');
    }
  }

  Future<void> updatePacksProduced(String orderId, int packsProduced) async {
    try {
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        final currentOrder = _orders[orderIndex];
        // Ensure packsProduced doesn't exceed packsOrdered
        final validatedPacksProduced = packsProduced > currentOrder.packsOrdered
            ? currentOrder.packsOrdered
            : packsProduced;
            
        final updatedOrder = currentOrder.copyWith(
          packsProduced: validatedPacksProduced,
        );
        await updateOrder(updatedOrder);
      }
    } catch (e) {
      print('Error updating produced packs: $e');
    }
  }
  
  // Keep this for backward compatibility - redirects to updatePacksProduced
  @Deprecated('Use updatePacksProduced instead')
  Future<void> updateOrderQuantity(String orderId, int newQuantity) async {
    return updatePacksProduced(orderId, newQuantity);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        final updatedOrder = _orders[orderIndex].copyWith(
          status: newStatus,
        );
        await updateOrder(updatedOrder);
      }
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Future<void> updatePaymentStatus(String orderId, String newPaymentStatus) async {
    try {
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        final updatedOrder = _orders[orderIndex].copyWith(
          paymentStatus: newPaymentStatus,
        );
        await updateOrder(updatedOrder);
      }
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }

  List<Order> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  List<Order> searchOrders(String query) {
    final lowerQuery = query.toLowerCase();
    return _orders.where((order) =>
      order.storeName.toLowerCase().contains(lowerQuery) ||
      order.personInCharge.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}