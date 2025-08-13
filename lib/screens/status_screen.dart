import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.largeSpacing),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                child: Column(
                  children: [
                    const Text(
                      'The status feature will allow you to track and monitor the status of all your orders in real-time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Feature coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Notify Me When Available'),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
