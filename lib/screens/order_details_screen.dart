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
  late int packsProduced;
  bool _changesApplied = false;
  bool _skipNextNotification = false;

  @override
  void initState() {
    super.initState();
    packsProduced = widget.order.packsProduced;
  }

  Future<void> _updateQuantity(OrderProvider provider) async {
    if (packsProduced != widget.order.packsProduced) {
      try {
        // Validate input before updating
        if (packsProduced < 0) {
          throw Exception('Produced packs cannot be negative');
        }
        
        if (packsProduced > widget.order.packsOrdered) {
          throw Exception('Produced packs cannot exceed ordered packs (${widget.order.packsOrdered})');
        }
        
        await provider.updatePacksProduced(widget.order.id, packsProduced);
        
        // Mark that changes were applied
        _changesApplied = true;
        
        // Only show error messages immediately, success message will be shown on exit
        if (!_skipNextNotification) {
          // For batch operations, we can skip individual notifications
          _skipNextNotification = false;
        }
      } catch (e) {
        // Handle errors immediately
        if (mounted) {
          setState(() {
            // Revert to original value on error
            packsProduced = widget.order.packsProduced;
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
    if (packsProduced < widget.order.packsOrdered) {
      setState(() {
        packsProduced++;
        _skipNextNotification = true; // Skip notification for this update
      });
      _updateQuantity(provider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum production quantity (${widget.order.packsOrdered}) reached'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _decrement(OrderProvider provider) {
    if (packsProduced > 0) {
      setState(() {
        packsProduced--;
        _skipNextNotification = true; // Skip notification for this update
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
    final controller = TextEditingController(text: packsProduced.toString());
    String? errorText;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Enter Packs Produced"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Enter number of packs produced",
                  errorText: errorText,
                  helperText: "Maximum: ${widget.order.packsOrdered} packs",
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
                if (value != null && value >= 0 && value <= widget.order.packsOrdered) {
                  Navigator.pop(context, value);
                } else {
                  // Show error in the dialog
                  setState(() {
                    if (value == null) {
                      errorText = "Please enter a valid number";
                    } else if (value < 0) {
                      errorText = "Quantity cannot be negative";
                    } else {
                      errorText = "Maximum quantity (${widget.order.packsOrdered}) exceeded";
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
        packsProduced = result;
        _skipNextNotification = true; // Skip notification for this update
      });
      _updateQuantity(provider);
    }
  }
  
  // Update order status method
  Future<void> _updateOrderStatus(OrderProvider provider, Order order, String newStatus) async {
    try {
      final updatedOrder = order.copyWith(status: newStatus);
      await provider.updateOrder(updatedOrder);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as ${newStatus.toLowerCase()}'),
            backgroundColor: newStatus == 'Completed' 
                ? AppTheme.completedColor 
                : (newStatus == 'Processing' ? Colors.amber : 
                   newStatus == 'Hold' ? Colors.amber : 
                   newStatus == 'Pending' ? Colors.blue : Colors.grey),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Confirm delete dialog
  void _confirmDelete(OrderProvider provider, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to delete this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cancelledColor,
            ),
            onPressed: () async {
              try {
                await provider.deleteOrder(order.id);
                
                if (mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop(); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting order: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getIconForLabel(label),
            color: AppTheme.primaryColor.withOpacity(0.7),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get icon for each label type
  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Store Name':
        return Icons.store;
      case 'Person in Charge':
        return Icons.person;
      case 'Contact Number':
        return Icons.phone;
      case 'Order Date':
        return Icons.calendar_today;
      case 'Delivery Date':
        return Icons.local_shipping;
      case 'Status':
        return Icons.info_outline;
      case 'Payment Status':
        return Icons.payment;
      case 'Notes':
        return Icons.note;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        // Get the most up-to-date order data
        final currentOrder = provider.orders
            .firstWhere((o) => o.id == widget.order.id, orElse: () => widget.order);

        return WillPopScope(
          onWillPop: () async {
            // Show a success notification when exiting if changes were made
            if (_changesApplied && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Production quantity changes saved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return true; // Allow the navigation to proceed
          },
          child: Scaffold(
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
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  switch (value) {
                    case 'complete':
                      await _updateOrderStatus(provider, currentOrder, 'Completed');
                      break;
                    case 'hold':
                      await _updateOrderStatus(provider, currentOrder, 'Hold');
                      break;
                    case 'delete':
                      _confirmDelete(provider, currentOrder);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.completedColor),
                        const SizedBox(width: 8),
                        const Text('Mark as Complete'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'hold',
                    child: Row(
                      children: [
                        Icon(Icons.pause_circle, color: Colors.amber),
                        const SizedBox(width: 8),
                        const Text('Put on Hold'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: AppTheme.cancelledColor),
                        const SizedBox(width: 8),
                        const Text('Delete Order'),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            child: Column(
              children: [
                const SizedBox(height: AppTheme.largeSpacing),

                // Packs Ordered Monitor with Interactive Progress Circle
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

                    // Interactive Progress Circle
                    GestureDetector(
                      onTap: () => _manualInput(provider),
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            // Add a glow effect when the target is met
                            if (currentOrder.packsProduced >= currentOrder.packsOrdered)
                              BoxShadow(
                                color: AppTheme.completedColor.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Progress Circle
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: CircularProgressIndicator(
                                value: currentOrder.packsOrdered > 0 
                                    ? (currentOrder.packsProduced / currentOrder.packsOrdered).clamp(0.0, 1.0) 
                                    : 1.0,
                                strokeWidth: 10,
                                backgroundColor: Colors.grey.shade200,
                                color: currentOrder.packsProduced >= currentOrder.packsOrdered 
                                    ? AppTheme.completedColor 
                                    : AppTheme.primaryColor,
                              ),
                            ),
                            // Inner content
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${currentOrder.packsProduced}/${currentOrder.packsOrdered}",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: currentOrder.packsProduced >= currentOrder.packsOrdered
                                        ? AppTheme.completedColor
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  "packs",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: currentOrder.packsProduced >= currentOrder.packsOrdered
                                        ? AppTheme.completedColor
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                // Status indicator
                                if (currentOrder.packsProduced >= currentOrder.packsOrdered)
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, 
                                        color: AppTheme.completedColor, 
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Target Met",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.completedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
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
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                      child: ListView(
                        children: [
                          _detailItem("Store Name", currentOrder.storeName),
                          _detailItem("Person in Charge", currentOrder.personInCharge),
                          if (currentOrder.contactNumber.isNotEmpty)
                            _detailItem("Contact Number", currentOrder.contactNumber),
                          _detailItem("Order Date", DateFormat('MMM dd, yyyy').format(currentOrder.orderDate)),
                          if (currentOrder.deliveryDate != null)
                            _detailItem("Deadline Date", DateFormat('MMM dd, yyyy').format(currentOrder.deliveryDate!)),
                          _detailItem("Status", currentOrder.status),
                          _detailItem("Payment Status", currentOrder.paymentStatus),
                          if (currentOrder.notes.isNotEmpty)
                            _detailItem("Notes", currentOrder.notes),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Complete Button
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.completedColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _updateOrderStatus(provider, currentOrder, 'Completed'),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Hold Button
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.pause_circle_filled),
                    label: const Text('Hold'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _updateOrderStatus(provider, currentOrder, 'Hold'),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Delete Button
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cancelledColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _confirmDelete(provider, currentOrder),
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}
