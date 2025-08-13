import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/product_manager.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.largeSpacing),
              
              // App Logo and Title
              const Column(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(height: AppTheme.mediumSpacing),
                  Text(
                    'OMATA',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(height: AppTheme.smallSpacing),
                  Text(
                    'Order Monitoring and Tracking App',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.largeSpacing * 2),
              
              // Product Category Cards
              Text(
                'Select Product Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.mediumSpacing),
              
              // Banana Chips Card
              _buildProductCard(
                context,
                'Banana Chips',
                'Assets for banana chips production',
                Icons.eco,
                Colors.amber,
                () => _selectProductCategory(context, 'banana'),
              ),
              
              const SizedBox(height: AppTheme.mediumSpacing),
              
              // Karlang Chips Card
              _buildProductCard(
                context,
                'Karlang Chips',
                'Assets for karlang chips production',
                Icons.fastfood,
                Colors.deepOrange,
                () => _selectProductCategory(context, 'karlang'),
              ),
              
              const SizedBox(height: AppTheme.mediumSpacing),
              
              // Kamote Chips Card
              _buildProductCard(
                context,
                'Kamote Chips',
                'Assets for kamote chips production',
                Icons.spa,
                Colors.brown,
                () => _selectProductCategory(context, 'kamote'),
              ),
              
              const SizedBox(height: AppTheme.largeSpacing),
              
              // Footer Text
              const Text(
                'Mama Em\'s Inventory System',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, String title, String subtitle, 
      IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.smallSpacing),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
              ),
              const SizedBox(width: AppTheme.mediumSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectProductCategory(BuildContext context, String category) {
    // Set the selected category in the ProductManager
    Provider.of<ProductManager>(context, listen: false).setProduct(category);
    
    // Navigate to the main app
    Navigator.pushReplacementNamed(context, '/main');
  }
}
