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

  List<Order> get orders => _orders;
  Map<String, int> get statistics => _statistics;
  bool get isLoading => _isLoading;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _orders = await _databaseHelper.getAllOrders();
      await loadStatistics();
    } catch (e) {
      print('Error loading orders: $e');
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
      print('Error loading statistics: $e');
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

  Future<void> updateOrderQuantity(String orderId, int newQuantity) async {
    try {
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        final updatedOrder = _orders[orderIndex].copyWith(
          packsOrdered: newQuantity,
        );
        await updateOrder(updatedOrder);
      }
    } catch (e) {
      print('Error updating order quantity: $e');
    }
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