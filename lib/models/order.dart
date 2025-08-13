// lib/models/order.dart
import 'package:flutter/foundation.dart';

class Order {
  final String id;
  final String storeName;
  final String personInCharge;
  final int packsOrdered;
  final String status;
  final String paymentStatus;
  final String notes;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  
  // Add validation constants
  static const List<String> validStatuses = ['Processing', 'Completed', 'Cancelled'];
  static const List<String> validPaymentStatuses = ['Paid', 'Pending', 'Cancelled'];
  static const int maxPacksPerOrder = 1000;

  Order({
    required this.id,
    required this.storeName,
    required this.personInCharge,
    required this.packsOrdered,
    required this.status,
    required this.paymentStatus,
    required this.notes,
    required this.orderDate,
    this.deliveryDate,
  }) {
    // Validate values in debug mode only to avoid runtime crashes in production
    assert(id.isNotEmpty, 'Order ID cannot be empty');
    assert(storeName.isNotEmpty, 'Store name cannot be empty');
    assert(personInCharge.isNotEmpty, 'Person in charge cannot be empty');
    assert(packsOrdered >= 0, 'Packs ordered must be non-negative');
    assert(validStatuses.contains(status), 'Invalid order status: $status');
    assert(validPaymentStatuses.contains(paymentStatus), 'Invalid payment status: $paymentStatus');
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storeName': storeName,
      'personInCharge': personInCharge,
      'packsOrdered': packsOrdered,
      'status': status,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
    };
  }

  // Create Order from Map (database retrieval) with better error handling
  factory Order.fromMap(Map<String, dynamic> map) {
    try {
      return Order(
        id: map['id'] ?? '',
        storeName: map['storeName'] ?? '',
        personInCharge: map['personInCharge'] ?? '',
        packsOrdered: _parsePacksOrdered(map['packsOrdered']),
        status: _validateStatus(map['status']),
        paymentStatus: _validatePaymentStatus(map['paymentStatus']),
        notes: map['notes'] ?? '',
        orderDate: _parseDateTime(map['orderDate'], DateTime.now()),
        deliveryDate: map['deliveryDate'] != null 
            ? _parseDateTime(map['deliveryDate'], null) 
            : null,
      );
    } catch (e) {
      debugPrint('Error parsing order: $e');
      // Return a default order if parsing fails
      return Order(
        id: map['id'] ?? 'error_${DateTime.now().millisecondsSinceEpoch}',
        storeName: 'Error Loading Data',
        personInCharge: '',
        packsOrdered: 0,
        status: 'Processing',
        paymentStatus: 'Pending',
        notes: 'There was an error loading this order data: $e',
        orderDate: DateTime.now(),
      );
    }
  }
  
  // Helper methods for parsing
  static int _parsePacksOrdered(dynamic value) {
    if (value == null) return 0;
    
    if (value is int) {
      return value.clamp(0, maxPacksPerOrder);
    }
    
    try {
      final parsedValue = int.parse(value.toString());
      return parsedValue.clamp(0, maxPacksPerOrder);
    } catch (e) {
      return 0;
    }
  }
  
  static String _validateStatus(String? status) {
    if (status != null && validStatuses.contains(status)) {
      return status;
    }
    return 'Processing';  // Default status
  }
  
  static String _validatePaymentStatus(String? paymentStatus) {
    if (paymentStatus != null && validPaymentStatuses.contains(paymentStatus)) {
      return paymentStatus;
    }
    return 'Pending';  // Default payment status
  }
  
  static DateTime _parseDateTime(String? dateTimeStr, DateTime? defaultValue) {
    if (dateTimeStr == null) {
      return defaultValue ?? DateTime.now();
    }
    
    try {
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      return defaultValue ?? DateTime.now();
    }
  }

  // Create a copy with updated fields
  Order copyWith({
    String? id,
    String? storeName,
    String? personInCharge,
    int? packsOrdered,
    String? status,
    String? paymentStatus,
    String? notes,
    DateTime? orderDate,
    DateTime? deliveryDate,
  }) {
    return Order(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      personInCharge: personInCharge ?? this.personInCharge,
      packsOrdered: packsOrdered ?? this.packsOrdered,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
    );
  }
}