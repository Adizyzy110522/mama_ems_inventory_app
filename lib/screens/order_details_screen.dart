import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../config/app_theme.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late int packsOrdered;

  @override
  void initState() {
    super.initState();
    packsOrdered = widget.order.packsOrdered;
  }

  Future<void> _updateQuantity(OrderProvider provider) async {
    if (packsOrdered != widget.order.packsOrdered) {
      try {
        // Validate input before updating
        if (packsOrdered < 0) {
          throw Exception('Quantity cannot be negative');
        }
        
        if (packsOrdered > Order.maxPacksPerOrder) {
          throw Exception('Maximum order quantity exceeded (${Order.maxPacksPerOrder})');
        }
        
        await provider.updateOrderQuantity(widget.order.id, packsOrdered);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quantity updated successfully')),
          );
        }
      } catch (e) {
        // Handle errors
        if (mounted) {
          setState(() {
            // Revert to original value on error
            packsOrdered = widget.order.packsOrdered;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating quantity: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _increment(OrderProvider provider) {
    // Prevent exceeding max value
    if (packsOrdered < Order.maxPacksPerOrder) {
      setState(() {
        packsOrdered++;
      });
      _updateQuantity(provider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum order quantity (${Order.maxPacksPerOrder}) reached'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _decrement(OrderProvider provider) {
    if (packsOrdered > 0) {
      setState(() {
        packsOrdered--;
      });
      _updateQuantity(provider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity cannot be negative'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _manualInput(OrderProvider provider) async {
    final controller = TextEditingController(text: packsOrdered.toString());
    String? errorText;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Enter Packs Ordered"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Enter number of packs",
                  errorText: errorText,
                  helperText: "Maximum: ${Order.maxPacksPerOrder} packs",
                ),
                onChanged: (value) {
                  // Live validation
                  setState(() {
                    final parsedValue = int.tryParse(value);
                    if (parsedValue == null) {
                      errorText = "Please enter a valid number";
                    } else if (parsedValue < 0) {
                      errorText = "Quantity cannot be negative";
                    } else if (parsedValue > Order.maxPacksPerOrder) {
                      errorText = "Maximum quantity exceeded";
                    } else {
                      errorText = null;
                    }
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value >= 0 && value <= Order.maxPacksPerOrder) {
                  Navigator.pop(context, value);
                } else {
                  // Show error in the dialog
                  setState(() {
                    if (value == null) {
                      errorText = "Please enter a valid number";
                    } else if (value < 0) {
                      errorText = "Quantity cannot be negative";
                    } else {
                      errorText = "Maximum quantity (${Order.maxPacksPerOrder}) exceeded";
                    }
                  });
                }
              },
              child: const Text("OK"),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        packsOrdered = result;
      });
      _updateQuantity(provider);
    }
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.smallSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
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
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        // Get the most up-to-date order data
        final currentOrder = provider.orders
            .firstWhere((o) => o.id == widget.order.id, orElse: () => widget.order);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.inventory_2, size: 24),
                const SizedBox(width: 8),
                Text(
                  currentOrder.storeName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            child: Column(
              children: [
                const SizedBox(height: AppTheme.largeSpacing),

                // Packs Ordered Monitor
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Minus Button
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle, 
                        size: 40, 
                        color: AppTheme.cancelledColor
                      ),
                      onPressed: () => _decrement(provider),
                    ),

                    // Big Circle Display (Tap to Edit)
                    GestureDetector(
                      onTap: () => _manualInput(provider),
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          border: Border.all(color: AppTheme.primaryColor, width: 4),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$packsOrdered",
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const Text(
                                "packs",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Plus Button
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle, 
                        size: 40, 
                        color: AppTheme.completedColor
                      ),
                      onPressed: () => _increment(provider),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.largeSpacing),

                // Order Details
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                      child: ListView(
                        children: [
                          _detailItem("Store Name", currentOrder.storeName),
                          _detailItem("Person in Charge", currentOrder.personInCharge),
                          _detailItem("Order Date", DateFormat('MMM dd, yyyy').format(currentOrder.orderDate)),
                          _detailItem("Status", currentOrder.status),
                          _detailItem("Payment Status", currentOrder.paymentStatus),
                          _detailItem("Notes", currentOrder.notes),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}