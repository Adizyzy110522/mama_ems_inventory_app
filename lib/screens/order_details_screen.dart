import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _OrderDetailsScreenState extends State<OrderDetailsScreen> with SingleTickerProviderStateMixin {
  late int packsProduced;
  bool _changesApplied = false;
  bool _skipNextNotification = false;
  
  // Animation controller for pulse effect
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    packsProduced = widget.order.packsProduced;
    
    // Initialize pulse animation controller
    _pulseAnimationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseAnimationController, 
        curve: Curves.easeInOut,
      ),
    );
    
    // Start repeating pulse animation
    _pulseAnimationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pulseAnimationController.dispose();
    super.dispose();
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
        
        // Update the packs produced
        await provider.updatePacksProduced(widget.order.id, packsProduced);
        
        // Auto-mark as completed if packs produced equals packs ordered and status is not already completed
        final currentOrder = provider.orders.firstWhere((order) => order.id == widget.order.id);
        if (packsProduced == widget.order.packsOrdered && 
            currentOrder.status != 'Completed' && 
            currentOrder.status != 'Cancelled') {
          await _updateOrderStatus(provider, currentOrder, 'Completed');
          
          // Show notification that order was automatically completed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Order automatically marked as completed!'),
                backgroundColor: AppTheme.completedColor,
              ),
            );
          }
        }
        
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

  // Utility method to provide haptic feedback
  void _provideHapticFeedback({bool isSuccess = true}) {
    if (isSuccess) {
      HapticFeedback.lightImpact(); // Light feedback for normal interactions
    } else {
      HapticFeedback.mediumImpact(); // Stronger feedback for errors or limits
    }
  }

  void _increment(OrderProvider provider) {
    // Prevent exceeding max value
    if (packsProduced < widget.order.packsOrdered) {
      setState(() {
        packsProduced++;
        _skipNextNotification = true; // Skip notification for this update
      });
      _provideHapticFeedback(); // Add haptic feedback
      _updateQuantity(provider);
    } else {
      _provideHapticFeedback(isSuccess: false); // Error feedback
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
      _provideHapticFeedback(); // Add haptic feedback
      _updateQuantity(provider);
    } else {
      _provideHapticFeedback(isSuccess: false); // Error feedback
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
      // If status is being set to Completed, also set packs produced to equal ordered
      Order updatedOrder;
      String message;
      
      if (newStatus == 'Completed') {
        // Update both status and packs produced
        updatedOrder = order.copyWith(
          status: newStatus, 
          packsProduced: order.packsOrdered
        );
        
        // Update the state variable to reflect the change
        setState(() {
          packsProduced = order.packsOrdered;
        });
        
        message = 'Order marked as completed with all packs produced';
      } else {
        // Just update the status
        updatedOrder = order.copyWith(status: newStatus);
        message = 'Order marked as ${newStatus.toLowerCase()}';
      }
      
      await provider.updateOrder(updatedOrder);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
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
  
  // Helper method to calculate responsive icon sizes based on screen width
  double _getResponsiveIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final smallerDimension = width < height ? width : height;
    
    // Responsive size calculation
    if (smallerDimension < 360) {
      return 50; // Very small screens
    } else if (smallerDimension < 600) {
      return 60; // Small to medium screens
    } else if (smallerDimension < 900) {
      return 70; // Medium to large screens
    } else {
      return 80; // Very large screens
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
            ),
            body: Padding(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.largeSpacing),

                  // Packs Ordered Monitor with Interactive Progress Circle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Animated Minus Button
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 200),
                            tween: Tween<double>(begin: 1.0, end: 1.0),
                            builder: (context, scale, child) {
                              return GestureDetector(
                                onTap: () {
                                  _provideHapticFeedback();
                                  _decrement(provider);
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) => setState(() {}),
                                  onExit: (_) => setState(() {}),
                                  child: AnimatedScale(
                                    scale: scale,
                                    duration: const Duration(milliseconds: 150),
                                    child: Container(
                                      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 12 : 20),
                                      child: Icon(
                                        Icons.remove_circle, 
                                        size: _getResponsiveIconSize(context),
                                        color: AppTheme.cancelledColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Interactive Progress Circle with Responsive Size and Smooth Animations
                          GestureDetector(
                            onTap: () {
                              _provideHapticFeedback();
                              _manualInput(provider);
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Calculate size based on available width and height
                                // Make it more responsive and proportional to the screen
                                final screenWidth = MediaQuery.of(context).size.width;
                                final screenHeight = MediaQuery.of(context).size.height;
                                
                                // Use the smaller dimension for better proportions
                                final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
                                
                                // Adjust size to be more reasonable on all screens
                                final size = smallerDimension < 600 
                                    ? smallerDimension * 0.45  // 45% of smaller dimension on small screens
                                    : 250.0;                  // Maximum size on larger screens
                                
                                return Hero(
                                  tag: 'progressCircle-${currentOrder.id}',
                                  child: AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      // Only apply pulse effect if the target is met or nearly met (>=90%)
                                      final shouldPulse = currentOrder.packsProduced >= currentOrder.packsOrdered || 
                                                        (currentOrder.packsOrdered > 0 && 
                                                         currentOrder.packsProduced / currentOrder.packsOrdered >= 0.9);
                                      
                                      final scale = shouldPulse ? _pulseAnimation.value : 1.0;
                                      
                                      return Transform.scale(
                                        scale: scale,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 500),
                                          curve: Curves.easeInOut,
                                          width: size,
                                          height: size,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              // Add a glow effect when the target is met
                                              if (currentOrder.packsProduced >= currentOrder.packsOrdered)
                                                BoxShadow(
                                                  color: AppTheme.completedColor.withOpacity(0.5),
                                                  blurRadius: 20,
                                                  spreadRadius: 8,
                                                  // Animated glow effect
                                                  offset: const Offset(0, 2),
                                                ),
                                            ],
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Progress Circle with Animated Progress
                                              TweenAnimationBuilder<double>(
                                                duration: const Duration(milliseconds: 750),
                                                curve: Curves.easeInOut,
                                                tween: Tween<double>(
                                                  begin: 0,
                                                  end: currentOrder.packsOrdered > 0 
                                                      ? (currentOrder.packsProduced / currentOrder.packsOrdered).clamp(0.0, 1.0) 
                                                      : 1.0,
                                                ),
                                                builder: (context, value, _) => SizedBox(
                                                  width: size,
                                                  height: size,
                                                  child: CircularProgressIndicator(
                                                    value: value,
                                                    strokeWidth: size * 0.04, // Slimmer stroke width (4% of circle size)
                                                    backgroundColor: Colors.grey.shade200.withOpacity(0.3),
                                                    color: currentOrder.packsProduced >= currentOrder.packsOrdered 
                                                        ? AppTheme.completedColor 
                                                        : AppTheme.primaryColor,
                                                  ),
                                                ),
                                              ),
                                              
                                              // Inner content with animations
                                              AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 300),
                                                child: Column(
                                                  key: ValueKey('${currentOrder.packsProduced}-${currentOrder.packsOrdered}'),
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    // Counter text with animated size
                                                    TweenAnimationBuilder<double>(
                                                      duration: const Duration(milliseconds: 400),
                                                      curve: Curves.easeOutCubic,
                                                      tween: Tween<double>(begin: 0.8, end: 1.0),
                                                      builder: (context, scale, child) => Transform.scale(
                                                        scale: scale,
                                                        child: Text(
                                                          "${currentOrder.packsProduced}/${currentOrder.packsOrdered}",
                                                          style: TextStyle(
                                                            fontSize: size * 0.18, // Slightly larger proportional font size
                                                            fontWeight: FontWeight.bold,
                                                            color: currentOrder.packsProduced >= currentOrder.packsOrdered
                                                                ? AppTheme.completedColor
                                                                : AppTheme.primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    
                                                    AnimatedDefaultTextStyle(
                                                      duration: const Duration(milliseconds: 300),
                                                      style: TextStyle(
                                                        fontSize: size * 0.09, // Slightly larger proportional font size
                                                        fontWeight: FontWeight.w500,
                                                        color: currentOrder.packsProduced >= currentOrder.packsOrdered
                                                            ? AppTheme.completedColor
                                                            : AppTheme.primaryColor,
                                                      ),
                                                      child: const Text("packs"),
                                                    ),
                                                    
                                                    SizedBox(height: size * 0.04), // Increased spacing
                                                    
                                                    // Status indicator with animation
                                                    if (currentOrder.packsProduced >= currentOrder.packsOrdered)
                                                      AnimatedOpacity(
                                                        opacity: 1.0,
                                                        duration: const Duration(milliseconds: 500),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.check_circle, 
                                                              color: AppTheme.completedColor, 
                                                              size: size * 0.07,
                                                            ),
                                                            SizedBox(width: size * 0.015),
                                                            Text(
                                                              "Target Met",
                                                              style: TextStyle(
                                                                fontSize: size * 0.05,
                                                                fontWeight: FontWeight.w500,
                                                                color: AppTheme.completedColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          // Animated Plus Button
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 200),
                            tween: Tween<double>(begin: 1.0, end: 1.0),
                            builder: (context, scale, child) {
                              return GestureDetector(
                                onTap: () {
                                  _provideHapticFeedback();
                                  _increment(provider);
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) => setState(() {}),
                                  onExit: (_) => setState(() {}),
                                  child: AnimatedScale(
                                    scale: scale,
                                    duration: const Duration(milliseconds: 150),
                                    child: Container(
                                      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 12 : 20),
                                      child: Icon(
                                        Icons.add_circle, 
                                        size: _getResponsiveIconSize(context),
                                        color: AppTheme.completedColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.largeSpacing),

                  // Order Details
                  Expanded(
                    child: Hero(
                      tag: 'order_card_${currentOrder.id}',
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
                    )),
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
                  // Complete/Cancel Button - Show Cancel if order is complete
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        currentOrder.packsProduced >= currentOrder.packsOrdered
                            ? Icons.cancel
                            : Icons.check_circle
                      ),
                      label: Text(
                        currentOrder.packsProduced >= currentOrder.packsOrdered
                            ? 'Cancel'
                            : 'Complete'
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentOrder.packsProduced >= currentOrder.packsOrdered
                            ? AppTheme.cancelledColor
                            : AppTheme.completedColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        if (currentOrder.packsProduced >= currentOrder.packsOrdered) {
                          _updateOrderStatus(provider, currentOrder, 'Cancelled');
                        } else {
                          _updateOrderStatus(provider, currentOrder, 'Completed');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Hold/Processing Button - Toggle between hold and processing
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        currentOrder.status == 'Hold'
                            ? Icons.play_circle_filled
                            : Icons.pause_circle_filled
                      ),
                      label: Text(
                        currentOrder.status == 'Hold'
                            ? 'Processing'
                            : 'Hold'
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentOrder.status == 'Hold'
                            ? AppTheme.processingColor
                            : Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        if (currentOrder.status == 'Hold') {
                          _updateOrderStatus(provider, currentOrder, 'Processing');
                        } else {
                          _updateOrderStatus(provider, currentOrder, 'Hold');
                        }
                      },
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
