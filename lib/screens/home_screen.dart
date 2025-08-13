import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import 'order_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard, size: 24),
            SizedBox(width: 8),
            Text(
              'Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.lastError != null) {
            return _buildErrorView(context, provider);
          }

          final stats = provider.statistics;
          final orders = provider.orders;
          
          return RefreshIndicator(
            onRefresh: () => provider.loadOrders(refresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  _buildWelcomeSection(),
                  const SizedBox(height: AppTheme.largeSpacing),
                  
                  // Statistics section
                  _buildStatisticsSection(stats),
                  const SizedBox(height: AppTheme.largeSpacing),
                  
                  // Recent orders section
                  _buildRecentOrdersSection(context, orders),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, OrderProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.cancelledColor,
            size: 64,
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          Text(
            provider.lastError ?? 'Unable to load data',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
          ElevatedButton.icon(
            onPressed: () => provider.retryLastOperation(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Today is ${dateFormat.format(now)}',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            const Text(
              'Welcome to Mama Em\'s Inventory Management',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildStatisticsSection(Map<String, int> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.smallSpacing),
          child: Text(
            'Order Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.smallSpacing),
        Row(
          children: [
            Expanded(
              child: _statisticsCard(
                icon: Icons.check_circle,
                title: 'Completed',
                value: stats['completed'] ?? 0,
                color: AppTheme.completedColor,
              ),
            ),
            const SizedBox(width: AppTheme.smallSpacing),
            Expanded(
              child: _statisticsCard(
                icon: Icons.pending_actions,
                title: 'Processing',
                value: stats['pending'] ?? 0,
                color: AppTheme.processingColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.smallSpacing),
        Row(
          children: [
            Expanded(
              child: _statisticsCard(
                icon: Icons.cancel,
                title: 'Cancelled',
                value: stats['cancelled'] ?? 0,
                color: AppTheme.cancelledColor,
              ),
            ),
            const SizedBox(width: AppTheme.smallSpacing),
            Expanded(
              child: _statisticsCard(
                icon: Icons.payments,
                title: 'Paid',
                value: stats['paid'] ?? 0,
                color: AppTheme.paidColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _statisticsCard({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppTheme.smallSpacing),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context, List<Order> allOrders) {
    // Get the 5 most recent orders
    final recentOrders = allOrders.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.smallSpacing),
              child: Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/orders');
              },
              icon: const Icon(Icons.visibility),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.smallSpacing),
        recentOrders.isEmpty
            ? _emptyOrdersCard()
            : Column(
                children: recentOrders
                    .map((order) => _orderCard(context, order))
                    .toList(),
              ),
      ],
    );
  }

  Widget _emptyOrdersCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.mediumSpacing),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory,
                size: 48,
                color: AppTheme.textLightColor,
              ),
              SizedBox(height: AppTheme.smallSpacing),
              Text(
                'No orders yet',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              SizedBox(height: AppTheme.smallSpacing),
              Text(
                'Create a new order to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLightColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _orderCard(BuildContext context, Order order) {
    final statusColor = AppTheme.getStatusColor(order.status);
    final dateFormat = DateFormat('MMM d, y');
    
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        onTap: () {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
          );
        },
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
            ],
          ),
        ),
      ),
    );
  }
}