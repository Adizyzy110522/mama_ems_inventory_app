// lib/models/order.dart
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
  });

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

  // Create Order from Map (database retrieval)
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      storeName: map['storeName'] ?? '',
      personInCharge: map['personInCharge'] ?? '',
      packsOrdered: map['packsOrdered'] ?? 0,
      status: map['status'] ?? '',
      paymentStatus: map['paymentStatus'] ?? '',
      notes: map['notes'] ?? '',
      orderDate: DateTime.parse(map['orderDate']),
      deliveryDate: map['deliveryDate'] != null 
          ? DateTime.parse(map['deliveryDate']) 
          : null,
    );
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