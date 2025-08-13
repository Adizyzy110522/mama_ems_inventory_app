// lib/screens/orders_screen_improved.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../config/app_theme.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = orderProvider.orders;
          
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start adding orders using the button below',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.mediumSpacing),
                child: ListTile(
                  title: Text(
                    order.storeName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Person: ${order.personInCharge}'),
                      if (order.contactNumber.isNotEmpty)
                        Text('Contact: ${order.contactNumber}'),
                      Text('Packs: ${order.packsOrdered}'),
                      Text('Status: ${order.status}'),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    // Navigate to order details
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrderDialog(context),
        label: const Text('New Order'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOrderDialog(BuildContext context) {
    final TextEditingController storeNameController = TextEditingController();
    final TextEditingController personController = TextEditingController();
    final TextEditingController contactController = TextEditingController(); // New contact field
    final TextEditingController packsController = TextEditingController(text: '1');
    final TextEditingController notesController = TextEditingController();
    String status = 'Processing';
    String paymentStatus = 'Pending';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Order'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Store Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: personController,
                      decoration: const InputDecoration(
                        labelText: 'Person in Charge',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Contact number field
                    TextField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        hintText: 'e.g., +63 912 345 6789',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: packsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Packs Ordered',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                      value: status,
                      onChanged: (newValue) {
                        setState(() {
                          status = newValue!;
                        });
                      },
                      items: Order.validStatuses.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Payment Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                      value: paymentStatus,
                      onChanged: (newValue) {
                        setState(() {
                          paymentStatus = newValue!;
                        });
                      },
                      items: Order.validPaymentStatuses.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Order'),
                  onPressed: () {
                    if (storeNameController.text.isEmpty ||
                        personController.text.isEmpty ||
                        packsController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Parse the number of packs
                    int packs;
                    try {
                      packs = int.parse(packsController.text);
                      if (packs < 0 || packs > Order.maxPacksPerOrder) {
                        throw FormatException('Invalid quantity');
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid quantity. Please enter a number between 0 and ${Order.maxPacksPerOrder}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Create and add the new order
                    final order = Order(
                      id: const Uuid().v4(), // Generate a unique ID
                      storeName: storeNameController.text,
                      personInCharge: personController.text,
                      contactNumber: contactController.text, // Added contact number
                      packsOrdered: packs,
                      status: status,
                      paymentStatus: paymentStatus,
                      notes: notesController.text,
                      orderDate: DateTime.now(),
                      deliveryDate: null,
                    );

                    Provider.of<OrderProvider>(context, listen: false)
                        .addOrder(order)
                        .then((_) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding order: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
