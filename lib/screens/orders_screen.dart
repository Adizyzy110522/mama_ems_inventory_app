import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.list_alt, size: 24),
            SizedBox(width: 8),
            Text(
              'Orders',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrderDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = provider.orders;

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No orders found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadOrders();
            },
            child: ListView.builder(
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
                  child: _orderCard(order),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _orderCard(Order order) {
    final statusColor = AppTheme.getStatusColor(order.status);
    final paymentStatusColor = AppTheme.getPaymentStatusColor(order.paymentStatus);
    final dateFormat = DateFormat('MMM d, y');
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.storeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.smallSpacing,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.personInCharge,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (order.contactNumber.isNotEmpty) ... [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.contactNumber,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${order.packsOrdered} packs',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(order.orderDate),
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, 
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: paymentStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(color: paymentStatusColor),
                  ),
                  child: Text(
                    order.paymentStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: paymentStatusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (order.notes.isNotEmpty) ...[
              const SizedBox(height: AppTheme.smallSpacing),
              Text(
                order.notes,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showAddOrderDialog(BuildContext context) {
    final TextEditingController storeNameController = TextEditingController();
    final TextEditingController personController = TextEditingController();
    final TextEditingController contactController = TextEditingController();
    final TextEditingController packsController = TextEditingController(text: '1');
    final TextEditingController notesController = TextEditingController();
    String status = 'Processing';
    String paymentStatus = 'Pending';
    
    // Get theme for consistent styling
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(20),
              title: Row(
                children: [
                  Icon(
                    Icons.add_shopping_cart,
                    color: theme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add New Order',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Store Information Section
                    const Text(
                      'Store Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: storeNameController,
                      decoration: InputDecoration(
                        labelText: 'Store Name',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store, color: theme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Contact Information Section
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: personController,
                      decoration: InputDecoration(
                        labelText: 'Person in Charge',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person, color: theme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone, color: theme.primaryColor),
                        hintText: 'e.g., +63 912 345 6789',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Order Details Section
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: packsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Packs Ordered',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory, color: theme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline, color: theme.primaryColor),
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
                      decoration: InputDecoration(
                        labelText: 'Payment Status',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment, color: theme.primaryColor),
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
                    const SizedBox(height: 16),
                    
                    // Additional Information Section
                    const Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note, color: theme.primaryColor),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Order'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
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
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}