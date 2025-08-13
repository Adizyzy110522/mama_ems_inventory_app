import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? _searchQuery;
  List<Order>? _searchResults;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        // Clear search when closing search bar
        _searchController.clear();
        _searchQuery = null;
        _searchResults = null;
      }
    });
  }
  
  void _performSearch(String query) {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final results = provider.searchOrders(query);
    
    setState(() {
      _searchQuery = query;
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: 'Search store or person...',
                hintStyle: TextStyle(color: Colors.black54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                prefixIcon: Icon(Icons.search, color: Colors.black54),
              ),
              onChanged: (value) {
                // Perform real-time search as user types
                if (value.isEmpty) {
                  setState(() {
                    _searchQuery = null;
                    _searchResults = null;
                  });
                } else if (value.length >= 2) {
                  // Only search if at least 2 characters
                  _performSearch(value);
                }
              },
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _performSearch(value);
                }
              },
            )
          : const Row(
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
            icon: Icon(_isSearching ? Icons.close : Icons.search, 
              color: _isSearching ? Colors.black54 : null),
            onPressed: () {
              if (_isSearching) {
                // If closing search and there's text, clear it
                _searchController.clear();
                setState(() {
                  _searchQuery = null;
                  _searchResults = null;
                  _isSearching = false;
                });
              } else {
                // Opening search
                _toggleSearch();
              }
            },
            tooltip: _isSearching ? 'Close search' : 'Search orders',
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

          // Get orders based on whether we're searching or not
          final orders = _searchResults ?? provider.orders;

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.list_alt,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery != null 
                      ? 'No orders found matching "$_searchQuery"' 
                      : 'No orders found',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  if (_searchQuery != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = null;
                            _searchResults = null;
                          });
                        },
                        child: const Text('Clear Search'),
                      ),
                    ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Show search query if we're searching
              if (_searchQuery != null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: AppTheme.backgroundColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Showing results for "$_searchQuery"',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchQuery = null;
                            _searchResults = null;
                          });
                        },
                        tooltip: 'Clear Search',
                      ),
                    ],
                  ),
                ),
                
              // Order list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadOrders();
                    // Clear search when refreshing
                    setState(() {
                      _searchQuery = null;
                      _searchResults = null;
                    });
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
                          ).then((_) {
                            // Refresh search results when coming back from details
                            if (_searchQuery != null) {
                              _performSearch(_searchQuery!);
                            }
                          });
                        },
                        child: _orderCard(order),
                      );
                    },
                  ),
                ),
              ),
            ],
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
    String? paymentStatus; // Set to null initially for default prompt
    DateTime? deadline; // Order deadline date
    
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
                    // Contact number with embedded Philippines area code
                    TextField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone, color: theme.primaryColor),
                        prefixText: '+63 ',
                        hintText: '9XX XXX XXXX',
                      ),
                      // Only allow numeric input
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10), // Limit to 10 digits (9XX XXX XXXX)
                      ],
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
                      // Only show Processing, Hold, and Pending options
                      items: ['Processing', 'Hold', 'Pending'].map<DropdownMenuItem<String>>((String value) {
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
                      hint: const Text('Select payment status'),
                      onChanged: (newValue) {
                        setState(() {
                          paymentStatus = newValue;
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
                    
                    // Deadline date picker
                    InkWell(
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: theme.primaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (selectedDate != null) {
                          setState(() {
                            deadline = selectedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Order Deadline',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today, color: theme.primaryColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              deadline == null 
                                ? 'Select a deadline date' 
                                : DateFormat('MMM dd, yyyy').format(deadline!),
                              style: TextStyle(
                                color: deadline == null ? Colors.grey : Colors.black,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: theme.primaryColor,
                            ),
                          ],
                        ),
                      ),
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

                    // Validate payment status is selected
                    if (paymentStatus == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a payment status'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Validate deadline date is selected
                    if (deadline == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a deadline date'),
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
                      contactNumber: '+63 ' + contactController.text, // Add +63 prefix to contact number
                      packsOrdered: packs,
                      status: status,
                      paymentStatus: paymentStatus!, // Now safe to use with ! since we checked for null
                      notes: notesController.text,
                      orderDate: DateTime.now(),
                      deliveryDate: deadline, // Use the selected deadline date
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