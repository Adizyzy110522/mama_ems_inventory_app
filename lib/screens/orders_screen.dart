import 'package:flutter/material.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data — replace with database/API later
    final List<Map<String, dynamic>> orders = [
      {
        "storeName": "FreshMart Grocery",
        "personInCharge": "Anna Lopez",
        "packsOrdered": 25,
        "status": "Processing",
        "paymentStatus": "Paid",
        "notes": "Deliver before Friday morning"
      },
      {
        "storeName": "City Deli",
        "personInCharge": "Mark Santos",
        "packsOrdered": 40,
        "status": "Processing",
        "paymentStatus": "Pending",
        "notes": "Urgent order"
      },
      {
        "storeName": "Banana King",
        "personInCharge": "Carla Reyes",
        "packsOrdered": 12,
        "status": "Processing",
        "paymentStatus": "Paid",
        "notes": "No rush delivery"
      },
      {
        "storeName": "GreenLeaf Market",
        "personInCharge": "Joey Fernandez",
        "packsOrdered": 30,
        "status": "Processing",
        "paymentStatus": "Paid",
        "notes": "Fragile packaging"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders in Process'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailsScreen(order: order),
                ),
              );
            },
            child: _orderCard(
              storeName: order["storeName"],
              personInCharge: order["personInCharge"],
              packsOrdered: order["packsOrdered"],
            ),
          );
        },
      ),
    );
  }

  Widget _orderCard({
    required String storeName,
    required String personInCharge,
    required int packsOrdered,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "In charge: $personInCharge",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "$packsOrdered packs",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
