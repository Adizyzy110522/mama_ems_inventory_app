import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import 'order_details_screen.dart';

class FilteredOrdersScreen extends StatefulWidget {
  final String filterStatus;

  const FilteredOrdersScreen({super.key, required this.filterStatus});

  @override
  State<FilteredOrdersScreen> createState() => _FilteredOrdersScreenState();
}

class _FilteredOrdersScreenState extends State<FilteredOrdersScreen> {
  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  Future<void> _applyFilter() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    
    if (widget.filterStatus.startsWith('payment:')) {
      // Handle payment status filter
      final paymentStatus = widget.filterStatus.substring(8); // Remove 'payment:' prefix
      await provider.loadOrdersByPaymentStatus(paymentStatus);
    } else {
      // Handle order status filter
      await provider.loadOrdersByStatus(widget.filterStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    if (widget.filterStatus.startsWith('payment:')) {
      title = '${widget.filterStatus.substring(8)} Orders';
    } else {
      title = '${widget.filterStatus} Orders';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            tooltip: 'Clear Filter',
            onPressed: () {
              Provider.of<OrderProvider>(context, listen: false)
                  .loadOrders(refresh: true);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = provider.orders;

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.filter_list_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${title.toLowerCase()} found',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _orderCard(context, order);
            },
          );
        },
      ),
    );
  }

  Widget _orderCard(BuildContext context, Order order) {
    final statusColor = AppTheme.getStatusColor(order.status);
    final paymentStatusColor = AppTheme.getPaymentStatusColor(order.paymentStatus);
    final dateFormat = DateFormat('MMM d, y');
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
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
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    order.personInCharge,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, size: 14, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Ordered: ${dateFormat.format(order.orderDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: paymentStatusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.paymentStatus,
                      style: TextStyle(
                        color: paymentStatusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildProgressIndicator(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(Order order) {
    final progress = order.packsProduced / order.packsOrdered;
    final completedPercentage = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress: $completedPercentage%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${order.packsProduced}/${order.packsOrdered} packs',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1 ? AppTheme.completedColor : AppTheme.processingColor,
          ),
        ),
      ],
    );
  }
}
