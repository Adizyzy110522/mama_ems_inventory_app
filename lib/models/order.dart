// lib/models/order.dart
import 'package:flutter/foundation.dart';
import '../config/product_config.dart';

class Order {
  final String id;
  final String storeName;
  final String personInCharge;
  final String contactNumber;  // Added contact number field
  final int packsOrdered;  // Target number of packs needed for this order
  final int packsProduced;  // Current number of packs produced for this order
  final String status;
  final String paymentStatus;
  final String notes;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  
  // New fields for packaging and pricing
  final String packType; // Stand Pouch or Square Pack
  final String priceType; // Wholesale or Retail
  final double unitPrice; // Price per pack
  final double totalPrice; // Total price (packsOrdered * unitPrice)
  
  // Add validation constants
  static const List<String> validStatuses = ['Processing', 'Pending', 'Hold', 'Completed', 'Cancelled'];
  static const List<String> validPaymentStatuses = ['Paid', 'Pending'];
  static const int maxPacksPerOrder = 1000;

  Order({
    required this.id,
    required this.storeName,
    required this.personInCharge,
    this.contactNumber = '',  // Default to empty string if not provided
    required this.packsOrdered,
    this.packsProduced = 0,   // Default to 0 if not provided
    required this.status,
    required this.paymentStatus,
    required this.notes,
    required this.orderDate,
    this.deliveryDate,
    required this.packType,
    required this.priceType,
    required this.unitPrice,
    required this.totalPrice,
  }) {
    // Validate values in debug mode only to avoid runtime crashes in production
    assert(id.isNotEmpty, 'Order ID cannot be empty');
    assert(storeName.isNotEmpty, 'Store name cannot be empty');
    assert(personInCharge.isNotEmpty, 'Person in charge cannot be empty');
    assert(packsOrdered >= 0, 'Packs ordered must be non-negative');
    assert(packsProduced >= 0, 'Packs produced must be non-negative');
    assert(packsProduced <= packsOrdered, 'Packs produced cannot exceed packs ordered');
    assert(validStatuses.contains(status), 'Invalid order status: $status');
    assert(validPaymentStatuses.contains(paymentStatus), 'Invalid payment status: $paymentStatus');
    assert(packType.isNotEmpty, 'Pack type cannot be empty');
    assert(priceType.isNotEmpty, 'Price type cannot be empty');
    assert(unitPrice >= 0, 'Unit price must be non-negative');
    assert(totalPrice >= 0, 'Total price must be non-negative');
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storeName': storeName,
      'personInCharge': personInCharge,
      'contactNumber': contactNumber,  // Added contact number
      'packsOrdered': packsOrdered,
      'packsProduced': packsProduced,
      'status': status,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'packType': packType,
      'priceType': priceType,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  // Create Order from Map (database retrieval) with better error handling
  factory Order.fromMap(Map<String, dynamic> map) {
    try {
      return Order(
        id: map['id'] ?? '',
        storeName: map['storeName'] ?? '',
        personInCharge: map['personInCharge'] ?? '',
        contactNumber: map['contactNumber'] ?? '',
        packsOrdered: _parsePacksOrdered(map['packsOrdered']),
        packsProduced: _parsePacksProduced(map['packsProduced'], map['packsOrdered']),
        status: _validateStatus(map['status']),
        paymentStatus: _validatePaymentStatus(map['paymentStatus']),
        notes: map['notes'] ?? '',
        orderDate: _parseDateTime(map['orderDate'], DateTime.now()),
        deliveryDate: map['deliveryDate'] != null 
            ? _parseDateTime(map['deliveryDate'], null) 
            : null,
        packType: map['packType'] ?? ProductConfig.standPouch,
        priceType: map['priceType'] ?? ProductConfig.wholesale,
        unitPrice: _parseDouble(map['unitPrice'], 0.0),
        totalPrice: _parseDouble(map['totalPrice'], 0.0),
      );
    } catch (e) {
      debugPrint('Error parsing order: $e');
      // Return a default order if parsing fails
      return Order(
        id: map['id'] ?? 'error_${DateTime.now().millisecondsSinceEpoch}',
        storeName: 'Error Loading Data',
        personInCharge: '',
        contactNumber: '',
        packsOrdered: 0,
        packsProduced: 0,
        status: 'Processing',
        paymentStatus: 'Pending',
        notes: 'There was an error loading this order data: $e',
        orderDate: DateTime.now(),
        packType: ProductConfig.standPouch,
        priceType: ProductConfig.wholesale,
        unitPrice: 0.0,
        totalPrice: 0.0,
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
  
  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    
    if (value is double) {
      return value;
    }
    
    if (value is int) {
      return value.toDouble();
    }
    
    try {
      return double.parse(value.toString());
    } catch (e) {
      return defaultValue;
    }
  }
  
  static int _parsePacksProduced(dynamic value, dynamic maxValue) {
    // Default to 0 if null
    if (value == null) return 0;
    
    // Get maximum packs ordered
    int maxPacks = _parsePacksOrdered(maxValue);
    
    if (value is int) {
      return value.clamp(0, maxPacks);
    }
    
    try {
      final parsedValue = int.parse(value.toString());
      return parsedValue.clamp(0, maxPacks);
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
    String? contactNumber,
    int? packsOrdered,
    int? packsProduced,
    String? status,
    String? paymentStatus,
    String? notes,
    DateTime? orderDate,
    DateTime? deliveryDate,
    String? packType,
    String? priceType,
    double? unitPrice,
    double? totalPrice,
  }) {
    return Order(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      personInCharge: personInCharge ?? this.personInCharge,
      contactNumber: contactNumber ?? this.contactNumber,
      packsOrdered: packsOrdered ?? this.packsOrdered,
      packsProduced: packsProduced ?? this.packsProduced,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      packType: packType ?? this.packType,
      priceType: priceType ?? this.priceType,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}