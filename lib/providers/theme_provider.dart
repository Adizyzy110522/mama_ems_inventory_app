import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  // Available themes
  static const String defaultTheme = 'Default Blue';
  static const String greenTheme = 'Green';
  static const String purpleTheme = 'Purple';
  static const String orangeTheme = 'Orange';
  static const String redTheme = 'Red';
  
  // Theme data storage
  late SharedPreferences _prefs;
  bool _isLoaded = false;
  
  // Current theme settings
  String _currentTheme = defaultTheme;
  Color _primaryColor = AppTheme.primaryColor;
  Color _accentColor = AppTheme.accentColor;

  // Theme options
  final Map<String, Map<String, Color>> themeOptions = {
    defaultTheme: {
      'primary': const Color(0xFF1E88E5), // Blue
      'accent': const Color(0xFF26A69A), // Teal
    },
    greenTheme: {
      'primary': const Color(0xFF43A047), // Green
      'accent': const Color(0xFF26C6DA), // Cyan
    },
    purpleTheme: {
      'primary': const Color(0xFF7B1FA2), // Purple
      'accent': const Color(0xFFE91E63), // Pink
    },
    orangeTheme: {
      'primary': const Color(0xFFEF6C00), // Orange
      'accent': const Color(0xFF8D6E63), // Brown
    },
    redTheme: {
      'primary': const Color(0xFFC62828), // Red
      'accent': const Color(0xFFFF9800), // Amber
    },
  };

  // Getters
  String get currentTheme => _currentTheme;
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  bool get isLoaded => _isLoaded;

  // Initialize the provider
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTheme();
    _isLoaded = true;
    notifyListeners();
  }

  // Load theme from preferences
  void _loadTheme() {
    final savedTheme = _prefs.getString('theme_name') ?? defaultTheme;
    
    if (savedTheme == 'Custom') {
      // Load custom theme
      _currentTheme = 'Custom';
      
      // Get saved colors or use default
      final primaryColorValue = _prefs.getInt('primary_color');
      final accentColorValue = _prefs.getInt('accent_color');
      
      if (primaryColorValue != null) {
        _primaryColor = Color(primaryColorValue);
      }
      
      if (accentColorValue != null) {
        _accentColor = Color(accentColorValue);
      }
      
      // Add the custom theme to options if it doesn't exist
      if (!themeOptions.containsKey('Custom')) {
        themeOptions['Custom'] = {
          'primary': _primaryColor,
          'accent': _accentColor,
        };
      } else {
        // Update the custom theme in options
        themeOptions['Custom']!['primary'] = _primaryColor;
        themeOptions['Custom']!['accent'] = _accentColor;
      }
    } else if (themeOptions.containsKey(savedTheme)) {
      _currentTheme = savedTheme;
      _primaryColor = themeOptions[savedTheme]!['primary']!;
      _accentColor = themeOptions[savedTheme]!['accent']!;
    } else {
      // Fallback to default theme
      _currentTheme = defaultTheme;
      _primaryColor = themeOptions[defaultTheme]!['primary']!;
      _accentColor = themeOptions[defaultTheme]!['accent']!;
    }
  }

  // Change theme
  Future<void> setTheme(String themeName) async {
    if (!themeOptions.containsKey(themeName)) return;
    
    _currentTheme = themeName;
    _primaryColor = themeOptions[themeName]!['primary']!;
    _accentColor = themeOptions[themeName]!['accent']!;
    
    await _prefs.setString('theme_name', themeName);
    notifyListeners();
  }
  
  // Set custom theme
  Future<void> setCustomTheme({required Color primaryColor, required Color accentColor}) async {
    // Create or update the custom theme
    _currentTheme = 'Custom';
    _primaryColor = primaryColor;
    _accentColor = accentColor;
    
    // Save to preferences
    await _prefs.setString('theme_name', 'Custom');
    await _prefs.setInt('primary_color', primaryColor.value);
    await _prefs.setInt('accent_color', accentColor.value);
    
    notifyListeners();
  }

  // Get current theme data
  ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        primary: _primaryColor,
        secondary: _accentColor,
        background: AppTheme.backgroundColor,
        surface: AppTheme.cardColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppTheme.backgroundColor,
      cardColor: AppTheme.cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(AppTheme.cardBorderRadius),
            bottomRight: Radius.circular(AppTheme.cardBorderRadius),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: _primaryColor,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.mediumSpacing * 1.5,
            vertical: AppTheme.smallSpacing,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppTheme.cancelledColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.mediumSpacing,
          vertical: AppTheme.smallSpacing,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        space: AppTheme.mediumSpacing,
      ),
    );
  }
}
