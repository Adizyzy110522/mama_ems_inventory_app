import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.settings, size: 24),
            SizedBox(width: 8),
            Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        children: [
          _buildThemeSection(context),
          const Divider(),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(
            left: AppTheme.smallSpacing,
            bottom: AppTheme.smallSpacing,
          ),
          child: Text(
            'Appearance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Theme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.smallSpacing),
                Wrap(
                  spacing: AppTheme.smallSpacing,
                  runSpacing: AppTheme.smallSpacing,
                  children: themeProvider.themeOptions.keys.map((themeName) {
                    final colors = themeProvider.themeOptions[themeName]!;
                    final isSelected = themeProvider.currentTheme == themeName;
                    
                    return InkWell(
                      onTap: () {
                        themeProvider.setTheme(themeName);
                      },
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      child: Container(
                        width: 90,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.smallSpacing,
                          vertical: AppTheme.mediumSpacing,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                          border: Border.all(
                            color: isSelected ? colors['primary']! : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: colors['primary'],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: colors['accent'],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.smallSpacing),
                            Text(
                              themeName,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: AppTheme.smallSpacing),
                              Icon(
                                Icons.check_circle,
                                color: colors['primary'],
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.mediumSpacing),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customize Colors',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.smallSpacing),
                const Text(
                  'Primary Color',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppTheme.smallSpacing),
                _buildColorPalette(
                  context,
                  [
                    Colors.blue,
                    Colors.red,
                    Colors.green,
                    Colors.purple,
                    Colors.orange,
                    Colors.teal,
                    Colors.pink,
                    Colors.amber,
                    Colors.indigo,
                    Colors.cyan,
                  ],
                  selectedColor: themeProvider.primaryColor,
                  onColorSelected: (color) {
                    // Create a custom theme with the selected primary color
                    themeProvider.setCustomTheme(
                      primaryColor: color,
                      accentColor: themeProvider.accentColor,
                    );
                  },
                ),
                const SizedBox(height: AppTheme.mediumSpacing),
                const Text(
                  'Accent Color',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppTheme.smallSpacing),
                _buildColorPalette(
                  context,
                  [
                    Colors.teal,
                    Colors.pink,
                    Colors.amber,
                    Colors.indigo,
                    Colors.cyan,
                    Colors.blue,
                    Colors.red,
                    Colors.green,
                    Colors.purple,
                    Colors.orange,
                  ],
                  selectedColor: themeProvider.accentColor,
                  onColorSelected: (color) {
                    // Create a custom theme with the selected accent color
                    themeProvider.setCustomTheme(
                      primaryColor: themeProvider.primaryColor,
                      accentColor: color,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPalette(
    BuildContext context, 
    List<Color> colors, 
    {required Color selectedColor, required Function(Color) onColorSelected}
  ) {
    return Wrap(
      spacing: AppTheme.smallSpacing,
      children: colors.map((color) {
        final isSelected = color.value == selectedColor.value;
        return InkWell(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected 
                ? [BoxShadow(
                    color: color.withOpacity(0.8), 
                    blurRadius: 4, 
                    spreadRadius: 1
                  )] 
                : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(
            left: AppTheme.smallSpacing,
            bottom: AppTheme.smallSpacing,
            top: AppTheme.smallSpacing,
          ),
          child: Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  // Show help dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Help & Support'),
                      content: const Text(
                        'For any issues or questions, please contact our support team at support@mamaemsapp.com'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                onTap: () {
                  // Show privacy policy
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Privacy Policy'),
                      content: const SingleChildScrollView(
                        child: Text(
                          'Mama Em\'s Inventory App respects your privacy. This app does not collect any personal data. All inventory data is stored locally on your device.'
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
