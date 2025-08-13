import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/product_manager.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  String _selectedChip = 'Revenue';
  String _selectedProduct = 'All Products';
  
  // Dummy data for sales
  final Map<String, List<SalesData>> _salesData = {
    'weekly': [
      SalesData('Mon', 15000, 120),
      SalesData('Tue', 18000, 140),
      SalesData('Wed', 16000, 130),
      SalesData('Thu', 21000, 160),
      SalesData('Fri', 24000, 180),
      SalesData('Sat', 28000, 200),
      SalesData('Sun', 22000, 170),
    ],
    'monthly': [
      SalesData('Jan', 120000, 950),
      SalesData('Feb', 140000, 1100),
      SalesData('Mar', 160000, 1250),
      SalesData('Apr', 180000, 1400),
      SalesData('May', 200000, 1550),
      SalesData('Jun', 220000, 1700),
      SalesData('Jul', 240000, 1850),
      SalesData('Aug', 190000, 1450),
      SalesData('Sep', 170000, 1300),
      SalesData('Oct', 210000, 1600),
      SalesData('Nov', 230000, 1750),
      SalesData('Dec', 260000, 2000),
    ],
    'yearly': [
      SalesData('2020', 1500000, 12000),
      SalesData('2021', 1800000, 14000),
      SalesData('2022', 2200000, 17000),
      SalesData('2023', 2500000, 19000),
      SalesData('2024', 2800000, 22000),
      SalesData('2025', 1800000, 14000), // Current year (partial)
    ],
  };
  
  // Product-specific data
  final Map<String, Map<String, List<SalesData>>> _productData = {
    'Banana Chips': {
      'weekly': [
        SalesData('Mon', 5000, 40),
        SalesData('Tue', 6000, 48),
        SalesData('Wed', 5500, 44),
        SalesData('Thu', 7000, 56),
        SalesData('Fri', 8000, 64),
        SalesData('Sat', 9500, 76),
        SalesData('Sun', 7500, 60),
      ],
      'monthly': [
        SalesData('Jan', 40000, 320),
        SalesData('Feb', 45000, 360),
        SalesData('Mar', 50000, 400),
        SalesData('Apr', 60000, 480),
        SalesData('May', 65000, 520),
        SalesData('Jun', 70000, 560),
        SalesData('Jul', 80000, 640),
        SalesData('Aug', 60000, 480),
        SalesData('Sep', 55000, 440),
        SalesData('Oct', 70000, 560),
        SalesData('Nov', 75000, 600),
        SalesData('Dec', 85000, 680),
      ],
      'yearly': [
        SalesData('2020', 500000, 4000),
        SalesData('2021', 600000, 4800),
        SalesData('2022', 700000, 5600),
        SalesData('2023', 800000, 6400),
        SalesData('2024', 900000, 7200),
        SalesData('2025', 600000, 4800), // Current year (partial)
      ],
    },
    'Karlang Chips': {
      'weekly': [
        SalesData('Mon', 6000, 48),
        SalesData('Tue', 7000, 56),
        SalesData('Wed', 6500, 52),
        SalesData('Thu', 8000, 64),
        SalesData('Fri', 9000, 72),
        SalesData('Sat', 10500, 84),
        SalesData('Sun', 8500, 68),
      ],
      'monthly': [
        SalesData('Jan', 45000, 360),
        SalesData('Feb', 50000, 400),
        SalesData('Mar', 55000, 440),
        SalesData('Apr', 65000, 520),
        SalesData('May', 70000, 560),
        SalesData('Jun', 75000, 600),
        SalesData('Jul', 85000, 680),
        SalesData('Aug', 65000, 520),
        SalesData('Sep', 60000, 480),
        SalesData('Oct', 75000, 600),
        SalesData('Nov', 80000, 640),
        SalesData('Dec', 90000, 720),
      ],
      'yearly': [
        SalesData('2020', 550000, 4400),
        SalesData('2021', 650000, 5200),
        SalesData('2022', 750000, 6000),
        SalesData('2023', 850000, 6800),
        SalesData('2024', 950000, 7600),
        SalesData('2025', 650000, 5200), // Current year (partial)
      ],
    },
    'Kamote Chips': {
      'weekly': [
        SalesData('Mon', 4000, 32),
        SalesData('Tue', 5000, 40),
        SalesData('Wed', 4000, 32),
        SalesData('Thu', 6000, 48),
        SalesData('Fri', 7000, 56),
        SalesData('Sat', 8000, 64),
        SalesData('Sun', 6000, 48),
      ],
      'monthly': [
        SalesData('Jan', 35000, 280),
        SalesData('Feb', 40000, 320),
        SalesData('Mar', 45000, 360),
        SalesData('Apr', 55000, 440),
        SalesData('May', 60000, 480),
        SalesData('Jun', 65000, 520),
        SalesData('Jul', 75000, 600),
        SalesData('Aug', 55000, 440),
        SalesData('Sep', 50000, 400),
        SalesData('Oct', 65000, 520),
        SalesData('Nov', 70000, 560),
        SalesData('Dec', 80000, 640),
      ],
      'yearly': [
        SalesData('2020', 450000, 3600),
        SalesData('2021', 550000, 4400),
        SalesData('2022', 650000, 5200),
        SalesData('2023', 750000, 6000),
        SalesData('2024', 850000, 6800),
        SalesData('2025', 550000, 4400), // Current year (partial)
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current product from ProductManager
    final productManager = Provider.of<ProductManager>(context);
    final currentProductCategory = productManager.currentProduct;
    
    // Set default product chip based on the current product category
    String displayProduct = 'All Products';
    if (currentProductCategory == 'banana') {
      displayProduct = 'Banana Chips';
    } else if (currentProductCategory == 'karlang') {
      displayProduct = 'Karlang Chips';
    } else if (currentProductCategory == 'kamote') {
      displayProduct = 'Kamote Chips';
    }
    
    // Update selected product if it has changed
    if (_selectedProduct != displayProduct && _selectedProduct == 'All Products') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedProduct = displayProduct;
        });
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bar_chart, size: 24),
            SizedBox(width: 8),
            Text(
              'Statistics',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // Filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Type',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Revenue', Icons.attach_money),
                      const SizedBox(width: 8),
                      _filterChip('Units Sold', Icons.inventory_2),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Product',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _productChip('All Products', Icons.category),
                      const SizedBox(width: 8),
                      _productChip('Banana Chips', Icons.cookie),
                      const SizedBox(width: 8),
                      _productChip('Karlang Chips', Icons.cookie),
                      const SizedBox(width: 8),
                      _productChip('Kamote Chips', Icons.cookie),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistics Summary
          _buildSummaryCard(),
          
          const SizedBox(height: 16),
          
          // Chart
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChartView('weekly'),
                _buildChartView('monthly'),
                _buildChartView('yearly'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _filterChip(String label, IconData icon) {
    final isSelected = _selectedChip == label;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedChip = label;
        });
      },
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }
  
  Widget _productChip(String label, IconData icon) {
    final isSelected = _selectedProduct == label;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedProduct = label;
        });
      },
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildSummaryCard() {
    final period = _getPeriodLabel();
    final data = _getCurrentData();
    
    // Calculate totals
    double totalAmount = 0;
    int totalUnits = 0;
    for (var item in data) {
      totalAmount += item.amount;
      totalUnits += item.unitsSold;
    }
    
    // Calculate average
    final avgAmount = data.isEmpty ? 0 : totalAmount / data.length;
    final avgUnits = data.isEmpty ? 0 : totalUnits / data.length;
    
    // Find max values
    double maxAmount = data.isEmpty ? 0 : data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    int maxUnits = data.isEmpty ? 0 : data.map((e) => e.unitsSold).reduce((a, b) => a > b ? a : b);
    
    // Best day/month/year
    final bestPeriod = data.isEmpty ? '' : data.firstWhere((e) => _selectedChip == 'Revenue' ? 
      e.amount == maxAmount : e.unitsSold == maxUnits).period;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary for $_selectedProduct',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Divider(),
          Row(
            children: [
              _summaryItem(
                'Total ${_selectedChip == 'Revenue' ? 'Revenue' : 'Units'}',
                _selectedChip == 'Revenue' 
                  ? '₱${NumberFormat.compact().format(totalAmount)}' 
                  : NumberFormat.compact().format(totalUnits),
                Icons.summarize,
              ),
              _summaryItem(
                'Average per $period',
                _selectedChip == 'Revenue' 
                  ? '₱${NumberFormat.compact().format(avgAmount)}' 
                  : NumberFormat.compact().format(avgUnits),
                Icons.trending_up,
              ),
              _summaryItem(
                'Best $period',
                bestPeriod,
                Icons.emoji_events,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getPeriodLabel() {
    switch (_selectedTabIndex) {
      case 0: return 'day';
      case 1: return 'month';
      case 2: return 'year';
      default: return 'period';
    }
  }
  
  Widget _summaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChartView(String period) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Graph',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildChart(period),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChart(String period) {
    final data = _getCurrentData(period);
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= data.length) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[value.toInt()].period,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final String text;
                  if (_selectedChip == 'Revenue') {
                    text = '₱${NumberFormat.compact().format(value)}';
                  } else {
                    text = NumberFormat.compact().format(value);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
                reservedSize: 50,
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(
            data.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: _selectedChip == 'Revenue' ? data[index].amount : data[index].unitsSold.toDouble(),
                  width: 20,
                  color: _getBarColor(index, data.length),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  List<SalesData> _getCurrentData([String? specificPeriod]) {
    final period = specificPeriod ?? ['weekly', 'monthly', 'yearly'][_selectedTabIndex];
    final productManager = Provider.of<ProductManager>(context, listen: false);
    final currentProductCategory = productManager.currentProduct;
    
    // If "All Products" is selected, return all data
    if (_selectedProduct == 'All Products') {
      return _salesData[period] ?? [];
    } else {
      // Map the product category from ProductManager to the product name in our data
      String productKey = _selectedProduct;
      
      // If no specific product is selected in the UI, use the one from ProductManager
      if (_selectedProduct == 'All Products' && currentProductCategory != 'all') {
        if (currentProductCategory == 'banana') {
          productKey = 'Banana Chips';
        } else if (currentProductCategory == 'karlang') {
          productKey = 'Karlang Chips';
        } else if (currentProductCategory == 'kamote') {
          productKey = 'Kamote Chips';
        }
      }
      
      return _productData[productKey]?[period] ?? [];
    }
  }
  
  Color _getBarColor(int index, int totalBars) {
    if (_selectedProduct == 'All Products') {
      return AppTheme.primaryColor.withOpacity(0.6 + 0.4 * (index / totalBars));
    } else if (_selectedProduct == 'Banana Chips') {
      return Colors.amber.shade700.withOpacity(0.6 + 0.4 * (index / totalBars));
    } else if (_selectedProduct == 'Karlang Chips') {
      return Colors.orange.shade800.withOpacity(0.6 + 0.4 * (index / totalBars));
    } else if (_selectedProduct == 'Kamote Chips') {
      return Colors.deepOrange.shade600.withOpacity(0.6 + 0.4 * (index / totalBars));
    } else {
      return Colors.brown.shade400.withOpacity(0.6 + 0.4 * (index / totalBars));
    }
  }
}

class SalesData {
  final String period;
  final double amount;
  final int unitsSold;
  
  SalesData(this.period, this.amount, this.unitsSold);
}
