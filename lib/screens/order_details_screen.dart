import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late int packsOrdered;

  @override
  void initState() {
    super.initState();
    packsOrdered = widget.order["packsOrdered"];
  }

  void _increment() {
    setState(() {
      packsOrdered++;
    });
  }

  void _decrement() {
    if (packsOrdered > 0) {
      setState(() {
        packsOrdered--;
      });
    }
  }

  void _manualInput() async {
    final controller = TextEditingController(text: packsOrdered.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Packs Ordered"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Enter number of packs",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        packsOrdered = result;
      });
    }
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: Text(order["storeName"]),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Packs Ordered Monitor
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minus Button
                IconButton(
                  icon: const Icon(Icons.remove_circle, size: 40, color: Colors.red),
                  onPressed: _decrement,
                ),

                // Big Circle Display (Tap to Edit)
                GestureDetector(
                  onTap: _manualInput,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue, width: 4),
                    ),
                    child: Center(
                      child: Text(
                        "$packsOrdered",
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),

                // Plus Button
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 40, color: Colors.green),
                  onPressed: _increment,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Order Details
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      _detailItem("Store Name", order["storeName"]),
                      _detailItem("Person in Charge", order["personInCharge"]),
                      _detailItem("Status", order["status"]),
                      _detailItem("Payment Status", order["paymentStatus"]),
                      _detailItem("Notes", order["notes"]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
